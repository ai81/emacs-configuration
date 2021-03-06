;;; xmtn-status.el --- manage actions for multiple projects

;; Copyright (C) 2009 - 2010 Stephen Leake

;; Author: Stephen Leake
;; Keywords: tools

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA  02110-1301  USA.

(eval-when-compile
  ;; these have macros we use
  (require 'xmtn-ids))

(eval-and-compile
  ;; these have functions we use
  (require 'xmtn-base)
  (require 'xmtn-conflicts)
  (require 'xmtn-revlist))

(defvar xmtn-status-root ""
  "Buffer-local variable holding multi-workspace root directory.")
(make-variable-buffer-local 'xmtn-status-root)
(put 'xmtn-status-root 'permanent-local t)

(defvar xmtn-status-ewoc nil
  "Buffer-local ewoc for displaying multi-workspace status.
All xmtn-status functions operate on this ewoc.
The elements must all be of class xmtn-status-data.")
(make-variable-buffer-local 'xmtn-status-ewoc)
(put 'xmtn-status-ewoc 'permanent-local t)

(defstruct (xmtn-status-data (:copier nil))
  work             ; workspace directory name relative to xmtn-status-root
  branch           ; branch name (all workspaces have same branch; assumed never changes)
  need-refresh     ; nil | t : if an async process was started that invalidates state data
  head-rev         ; nil | mtn rev string : current head revision, nil if multiple heads
  conflicts-buffer ; *xmtn-conflicts* buffer for merge
  status-buffer    ; *xmtn-status* buffer for commit
  heads            ; 'need-scan | 'at-head | 'need-update | 'need-merge
  (update-review
   'pending)       ; 'pending | 'need-review | 'done
  (local-changes
   'need-scan)     ; 'need-scan | 'need-commit | 'ok
  (conflicts
   'need-scan)     ; 'need-scan | 'need-resolve | 'need-review-resolve-internal | 'resolved | 'none
  )

(defun xmtn-status-work (data)
  (concat xmtn-status-root (xmtn-status-data-work data)))

(defun xmtn-status-need-refresh (elem data)
  ;; The user has selected an action that will change the state of the
  ;; workspace via mtn actions; set our data to reflect that. We
  ;; assume the user will not be creating new files or editing
  ;; existing ones.
  (setf (xmtn-status-data-need-refresh data) t)
  (setf (xmtn-status-data-heads data) 'need-scan)
  (setf (xmtn-status-data-conflicts data) 'need-scan)
  (ewoc-invalidate xmtn-status-ewoc elem))

(defun xmtn-status-printer (data)
  "Print an ewoc element."
  (insert (dvc-face-add (format "%s\n" (xmtn-status-data-work data)) 'dvc-keyword))

  (if (xmtn-status-data-need-refresh data)
      (insert (dvc-face-add "  need refresh\n" 'dvc-conflict))

    (ecase (xmtn-status-data-local-changes data)
      (need-scan (insert "  local changes unknown\n"))
      (need-commit (insert (dvc-face-add "  need commit\n" 'dvc-header)))
      (ok nil))

    (ecase (xmtn-status-data-conflicts data)
      (need-scan
       (insert "  conflicts need scan\n"))
      (need-resolve
       (insert (dvc-face-add "  need resolve conflicts\n" 'dvc-conflict)))
      (need-review-resolve-internal
       (insert (dvc-face-add "  need review resolve internal\n" 'dvc-header)))
      (resolved
       (insert "  conflicts resolved\n"))
      ((resolved none) nil))

    (ecase (xmtn-status-data-heads data)
      (at-head     nil)
      (need-update
       (insert (dvc-face-add "  need update\n" 'dvc-conflict)))
      (need-merge
       (insert (dvc-face-add "  need merge\n" 'dvc-conflict))))

    (ecase (xmtn-status-data-update-review data)
      (pending nil)
      (need-review (insert "  need update review\n"))
      (done nil))
      ))

(defun xmtn-status-kill-conflicts-buffer (data)
  (if (buffer-live-p (xmtn-status-data-conflicts-buffer data))
      (let ((buffer (xmtn-status-data-conflicts-buffer data)))
        (with-current-buffer buffer (save-buffer))
        (kill-buffer buffer))))

(defun xmtn-status-kill-status-buffer (data)
  (if (buffer-live-p (xmtn-status-data-status-buffer data))
      (kill-buffer (xmtn-status-data-status-buffer data))))

(defun xmtn-status-save-conflicts-buffer (data)
  (if (buffer-live-p (xmtn-status-data-conflicts-buffer data))
      (with-current-buffer (xmtn-status-data-conflicts-buffer data) (save-buffer))))

(defun xmtn-status-clean-1 (data)
  "Clean DATA workspace."
  (xmtn-automate-kill-session (xmtn-status-work data))
  (xmtn-status-kill-conflicts-buffer data)
  (xmtn-status-kill-status-buffer data)
  (xmtn-conflicts-clean (xmtn-status-work data)))

(defun xmtn-status-clean ()
  "Clean current workspace, delete from ewoc"
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem))
         (inhibit-read-only t))
    (xmtn-status-clean-1 data)
    (ewoc-delete xmtn-status-ewoc elem)))

(defun xmtn-status-quit ()
  "Clean all remaining workspaces, kill automate sessions, kill buffer."
  (interactive)
  (ewoc-map 'xmtn-status-clean-1 xmtn-status-ewoc)
  (kill-buffer))

(defun xmtn-status-cleanp ()
  "Non-nil if clean & quit is appropriate for current workspace."
  (let ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    ;; don't check need-refresh here; allow deleting after just doing
    ;; final required action in another buffer.
    (and (member (xmtn-status-data-local-changes data) '(need-scan ok))
         (member (xmtn-status-data-heads data) '(need-scan at-head)))))

(defun xmtn-status-do-refresh-one ()
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (xmtn-status-refresh-one data current-prefix-arg)
    (ewoc-invalidate xmtn-status-ewoc elem)))

(defun xmtn-status-refreshp ()
  "Non-nil if refresh is appropriate for current workspace."
  (let ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (or (xmtn-status-data-need-refresh data)
        ;; everything's done, but the user just did mtn sync, and more
        ;; stuff showed up
        (eq 'ok (xmtn-status-data-local-changes data))
        (eq 'at-head (xmtn-status-data-heads data)))))

(defun xmtn-status-update ()
  "Update current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (xmtn-status-need-refresh elem data)
    (setf (xmtn-status-data-update-review data) 'need-review)
    (let ((default-directory (xmtn-status-work data)))
      (xmtn-dvc-update))
    (xmtn-status-refresh-one data nil)
    (ewoc-invalidate xmtn-status-ewoc elem)))

(defun xmtn-status-updatep ()
  "Non-nil if update is appropriate for current workspace."
  (let ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (and (not (xmtn-status-data-need-refresh data))
         (eq 'need-update (xmtn-status-data-heads data)))))

(defun xmtn-status-resolve-conflicts ()
  "Resolve conflicts for current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (xmtn-status-need-refresh elem data)
    (setf (xmtn-status-data-conflicts data) 'resolved)
    (pop-to-buffer (xmtn-status-data-conflicts-buffer data))))

(defun xmtn-status-resolve-conflictsp ()
  "Non-nil if resolve conflicts is appropriate for current workspace."
  (let* ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (and (not (xmtn-status-data-need-refresh data))
         (member (xmtn-status-data-conflicts data)
                 '(need-resolve need-review-resolve-internal)))))

(defun xmtn-status-status ()
  "Show status buffer for current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (xmtn-status-need-refresh elem data)
    (setf (xmtn-status-data-local-changes data) 'ok)
    (pop-to-buffer (xmtn-status-data-status-buffer data))
    ;; IMPROVEME: create a log-edit buffer now, since we have both a
    ;; status and conflict buffer, and that confuses dvc-log-edit
    ))

(defun xmtn-status-status-ok ()
  "Ignore local changes in current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (setf (xmtn-status-data-local-changes data) 'ok)
    (ewoc-invalidate xmtn-status-ewoc elem)))

(defun xmtn-status-statusp ()
  "Non-nil if xmtn-status is appropriate for current workspace."
  (let* ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (and (not (xmtn-status-data-need-refresh data))
         (member (xmtn-status-data-local-changes data)
                 '(need-scan need-commit)))))

(defun xmtn-status-review-update ()
  "Review last update for current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem)))
    (xmtn-status-need-refresh elem data)
    (setf (xmtn-status-data-update-review data) 'done)
    (xmtn-review-update (xmtn-status-work data))))

(defun xmtn-status-review-updatep ()
  "Non-nil if xmtn-status-review-update is appropriate for current workspace."
  (let* ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (and (not (xmtn-status-data-need-refresh data))
         (eq 'need-review (xmtn-status-data-update-review data)))))

(defun xmtn-status-merge ()
  "Run merge on current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem))
         (default-directory (xmtn-status-work data)))
    (xmtn-status-save-conflicts-buffer data)
    (xmtn-dvc-merge-1 default-directory nil)
    (xmtn-status-refresh-one data nil)
    (ewoc-invalidate xmtn-status-ewoc elem)))

(defun xmtn-status-heads ()
  "Show heads for current workspace."
  (interactive)
  (let* ((elem (ewoc-locate xmtn-status-ewoc))
         (data (ewoc-data elem))
         (default-directory (xmtn-status-work data)))
    (xmtn-status-need-refresh elem data)
    (xmtn-view-heads-revlist)))

(defun xmtn-status-headsp ()
  "Non-nil if xmtn-heads is appropriate for current workspace."
  (let* ((data (ewoc-data (ewoc-locate xmtn-status-ewoc))))
    (and (not (xmtn-status-data-need-refresh data))
         (eq 'need-merge (xmtn-status-data-heads data)))))

(defvar xmtn-status-actions-map
  (let ((map (make-sparse-keymap "actions")))
    (define-key map [?c]  '(menu-item "c) clean/delete"
                                      xmtn-status-clean
                                      :visible (xmtn-status-cleanp)))
    (define-key map [?g]  '(menu-item "g) refresh"
                                      xmtn-status-do-refresh-one
                                      :visible (xmtn-status-refreshp)))
    (define-key map [?i]  '(menu-item "i) ignore local changes"
                                      xmtn-status-status-ok
                                      :visible (xmtn-status-statusp)))
    (define-key map [?5]  '(menu-item "5) review update"
                                      xmtn-status-review-update
                                      :visible (xmtn-status-review-updatep)))
    (define-key map [?4]  '(menu-item "4) update"
                                      xmtn-status-update
                                      :visible (xmtn-status-updatep)))
    (define-key map [?3]  '(menu-item "3) merge"
                                      xmtn-status-merge
                                      :visible (xmtn-status-headsp)))
    (define-key map [?2]  '(menu-item "2) show heads"
                                      xmtn-status-heads
                                      :visible (xmtn-status-headsp)))
    (define-key map [?1]  '(menu-item "1) resolve conflicts"
                                      xmtn-status-resolve-conflicts
                                      :visible (xmtn-status-resolve-conflictsp)))
    (define-key map [?0]  '(menu-item "0) commit"
                                      xmtn-status-status
                                      :visible (xmtn-status-statusp)))
    map)
  "Keyboard menu keymap used in multiple-status mode.")

(dvc-make-ewoc-next xmtn-status-next xmtn-status-ewoc)
(dvc-make-ewoc-prev xmtn-status-prev xmtn-status-ewoc)

(defvar xmtn-multiple-status-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\M-d" xmtn-status-actions-map)
    (define-key map [?g]  'xmtn-status-refresh)
    (define-key map [?n]  'xmtn-status-next)
    (define-key map [?p]  'xmtn-status-prev)
    (define-key map [?q]  'xmtn-status-quit)
    map)
  "Keymap used in `xmtn-multiple-status-mode'.")

(define-derived-mode xmtn-multiple-status-mode nil "xmtn-multiple-status"
  "Major mode to show status of multiple workspaces."
  (setq dvc-buffer-current-active-dvc 'xmtn)
  (setq buffer-read-only nil)

  ;; don't do normal clean up stuff
  (set (make-local-variable 'before-save-hook) nil)
  (set (make-local-variable 'write-file-functions) nil)

  (dvc-install-buffer-menu)
  (setq buffer-read-only t)
  (buffer-disable-undo)

  (set-buffer-modified-p nil))

(defun xmtn-status-conflicts (data)
  "Return value for xmtn-status-data-conflicts for DATA."
  (let* ((work (xmtn-status-work data))
         (default-directory work))

    (if (buffer-live-p (xmtn-status-data-conflicts-buffer data))
        (kill-buffer (xmtn-status-data-conflicts-buffer data)))

    ;; create conflicts file
    (xmtn-conflicts-clean work)
    (xmtn-conflicts-save-opts work work (xmtn-status-data-branch data) (xmtn-status-data-branch data))
    (dvc-run-dvc-sync
     'xmtn
     (list "conflicts" "store")
     :error (lambda (output error status arguments)
              (pop-to-buffer error)))

    ;; create conflicts buffer
    (setf (xmtn-status-data-conflicts-buffer data)
          (save-excursion
            (let ((dvc-switch-to-buffer-first nil))
              (xmtn-conflicts-review work)
              (current-buffer))))

    (with-current-buffer (xmtn-status-data-conflicts-buffer data)
      (case xmtn-conflicts-total-count
        (0 'none)
        (t
         (if (= xmtn-conflicts-total-count xmtn-conflicts-resolved-internal-count)
             'need-review-resolve-internal
           'need-resolve))))))

(defun xmtn-status-refresh-one (data refresh-local-changes)
  "Refresh DATA."
  (let ((work (xmtn-status-work data)))

    (message "checking heads for %s " work)

    (let ((heads (xmtn--heads work (xmtn-status-data-branch data)))
          (base-rev (xmtn--get-base-revision-hash-id-or-null work)))
      (case (length heads)
        (1
         (setf (xmtn-status-data-head-rev data) (nth 0 heads))
         (setf (xmtn-status-data-conflicts data) 'none)
         (if (string= (xmtn-status-data-head-rev data) base-rev)
             (setf (xmtn-status-data-heads data) 'at-head)
           (setf (xmtn-status-data-heads data) 'need-update)))
        (t
         (setf (xmtn-status-data-head-rev data) nil)
         (setf (xmtn-status-data-heads data) 'need-merge)
         (case (xmtn-status-data-conflicts data)
           (resolved
            ;; Assume the resolution was just completed, so don't erase it!
            nil)
           (t
            (setf (xmtn-status-data-conflicts data) 'need-scan))))))

    (message "")

    (if refresh-local-changes
	(progn
	  (setf (xmtn-status-data-local-changes data) 'need-scan)
	  (case (xmtn-status-data-update-review data)
	    ('done (setf (xmtn-status-data-update-review data) 'need-review))
	    (t nil))))

    (case (xmtn-status-data-local-changes data)
      (need-scan
	 (let ((result (xmtn--status-inventory-sync (xmtn-status-work data))))
	   (setf (xmtn-status-data-status-buffer data) (car result)
		 (xmtn-status-data-local-changes data) (cadr result))) )
      (t nil))

    (case (xmtn-status-data-conflicts data)
      (need-scan
       (setf (xmtn-status-data-conflicts data)
             (xmtn-status-conflicts data)))
      (t nil))

    (setf (xmtn-status-data-need-refresh data) nil))

  ;; return non-nil to refresh display as we go along
  t)

(defun xmtn-status-refresh ()
  "Refresh status of each ewoc element. With prefix arg, re-scan for local changes."
  (interactive)
  (ewoc-map 'xmtn-status-refresh-one xmtn-status-ewoc current-prefix-arg)
  (message "done"))

;;;###autoload
(defun xmtn-update-multiple (dir &optional workspaces)
  "Update all projects under DIR."
  (interactive "DUpdate all in (root directory): ")
  (let ((root (file-name-as-directory (expand-file-name (substitute-in-file-name dir)))))

    (if (not workspaces) (setq workspaces (xmtn--filter-non-ws root)))

    (dolist (workspace workspaces)
      (let ((default-directory (concat root workspace)))
        (xmtn-dvc-update nil t)))
    (message "Update %s done" root)))

;;;###autoload
(defun xmtn-status-multiple (dir &optional workspaces skip-initial-scan)
  "Show actions to update all projects under DIR."
  (interactive "DStatus for all (root directory): \ni\nP")
  (pop-to-buffer (get-buffer-create "*xmtn-multi-status*"))
  (setq default-directory (file-name-as-directory (expand-file-name (substitute-in-file-name dir))))
  (if (not workspaces) (setq workspaces (xmtn--filter-non-ws default-directory)))
  (setq xmtn-status-root (file-name-as-directory default-directory))
  (setq xmtn-status-ewoc (ewoc-create 'xmtn-status-printer))
  (let ((inhibit-read-only t)) (delete-region (point-min) (point-max)))
  (ewoc-set-hf xmtn-status-ewoc (format "Root : %s\n" xmtn-status-root) "")
  (dolist (workspace workspaces)
    (ewoc-enter-last xmtn-status-ewoc
                     (make-xmtn-status-data
                      :work workspace
                      :branch (xmtn--tree-default-branch (concat xmtn-status-root workspace))
                      :need-refresh t
                      :heads 'need-scan)))
  (xmtn-multiple-status-mode)
  (when (not skip-initial-scan)
    (progn
      (xmtn-status-refresh)
      (xmtn-status-next))))

;;;###autoload
(defun xmtn-status-one (work)
  "Show actions to update WORK."
  (interactive "DStatus for (workspace): ")
  (pop-to-buffer (get-buffer-create "*xmtn-multi-status*"))
  ;; allow WORK to be relative, and ensure it is a workspace root
  (setq default-directory (xmtn-tree-root (expand-file-name (substitute-in-file-name work))))
  (setq xmtn-status-root (expand-file-name (concat (file-name-as-directory default-directory) "../")))
  (setq xmtn-status-ewoc (ewoc-create 'xmtn-status-printer))
  (let ((inhibit-read-only t)) (delete-region (point-min) (point-max)))
  (ewoc-set-hf xmtn-status-ewoc (format "Root : %s\n" xmtn-status-root) "")
  (ewoc-enter-last xmtn-status-ewoc
                   (make-xmtn-status-data
                    :work (file-name-nondirectory (directory-file-name default-directory))
                    :branch (xmtn--tree-default-branch default-directory)
                    :need-refresh t
                    :heads 'need-scan))
  (xmtn-multiple-status-mode)
  (xmtn-status-refresh)
  (xmtn-status-next))

;;;###autoload
(defun xmtn-status-one-1 (root name head-rev status-buffer heads local-changes)
  "Create an xmtn-multi-status buffer from xmtn-propagate."
  (pop-to-buffer (get-buffer-create "*xmtn-multi-status*"))
  (setq default-directory (concat root "/" name))
  (setq xmtn-status-root root)
  (setq xmtn-status-ewoc (ewoc-create 'xmtn-status-printer))
  (let ((inhibit-read-only t)) (delete-region (point-min) (point-max)))
  (ewoc-set-hf xmtn-status-ewoc (format "Root : %s\n" xmtn-status-root) "")
  (ewoc-enter-last xmtn-status-ewoc
                   (make-xmtn-status-data
                    :work (file-name-nondirectory (directory-file-name default-directory))
                    :branch (xmtn--tree-default-branch default-directory)
                    :need-refresh nil
		    :head-rev head-rev
		    :conflicts-buffer nil
		    :status-buffer status-buffer
                    :heads heads
		    :local-changes local-changes
		    :conflicts 'need-scan))
  (xmtn-multiple-status-mode)
  (xmtn-status-refresh))

(provide 'xmtn-multi-status)

;; end of file
