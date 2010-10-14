;; save DONE time
(setq org-log-done 'time)

(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

(add-hook 'org-mode-hook
          (lambda ()
            (local-set-key "\C-ct" 'org-time-stamp)
            ))

;; load all org files
(setq my-org-dir  (concat (file-name-directory
               (or load-file-name (buffer-file-name))) "my-org-files" ))
(mapc (lambda (name) (add-to-list 'org-agenda-files (concat my-org-dir "/" name)))
      (directory-files my-org-dir nil ".*org$"))

;; public to local server
(setq org-publish-project-alist
      '(( "ai-local-web-server"
        :base-directory "/home/ai/.emacs.d/ai/my-org-files" ;;,my-org-dir
        :base-extension "fake"
        :include ("priorities.org")
        :publishing-directory "/sudo:root@localhost:/var/www/"
        :auto-postamble nil
        )))

;; C-x r j o - directory with org files
(dolist (r `((?o (file . , my-org-dir))))
  (set-register (car r) (cadr r)))
