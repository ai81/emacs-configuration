;;; distel.el --- Top-level of distel package, loads all subparts

;; Prerequisites

(require 'vc-hooks)
(require 'vc-dispatcher)
(require 'vc)
(require 'erlang)
(require 'easy-mmode)
(require 'read-char-spec)

(provide 'wrangler)

;; Compatibility with XEmacs
(unless (fboundp 'define-minor-mode)
  (defalias 'define-minor-mode 'easy-mmode-define-minor-mode))


(defgroup wrangler '()
  "Wrangler options."
  :group 'tools)

(defcustom wrangler-search-paths (cons (expand-file-name ".") nil )
	"List of directories to search for .erl and .hrl files to refactor."
	:type '(repeat directory)
	:group 'wrangler)

(defcustom dirs-to-monitor nil
  "List of directories to be monitored by Wrangler to log refactoring activities."
  :type '(repeat directory)
  :group 'wrangler)

(defcustom refac-monitor-repository-path ""     
      "Path to the wrangler monitor"
      :type 'directory
      :group 'wrangler)

(defun wrangler-customize ()
 	  "Customization of group `wrangler' for the Erlang refactorer."
	  (interactive)
 	  (customize-group "wrangler"))

(require 'erl)
(require 'erl-service)


(setq modified-files nil)
(setq refactoring-committed nil)
(setq unopened-files nil)
(setq ediff-ignore-similar-regions t)
(setq refactor-mode nil)
(setq has-warning 'false)

(defun wrangler-ediff(file1 file2)
  "run ediff on file1 ans file2"
  (setq refactor-mode t)
  (ediff file1 file2)
)
(defun my-ediff-qh()
  "Function to be called when ediff quits."
  (if (equal refactor-mode t)
      (if (equal modified-files nil)
	  (commit-or-abort)
	(if (y-or-n-p "Do you want to preview changes made to other files?")
	    (progn
	      (setq file-to-diff (car modified-files))
	      (setq modified-files (cdr modified-files))
	      (if (get-file-buffer file-to-diff)
		  nil
		(setq unopened-files (cons file-to-diff unopened-files))
		)
	      (wrangler-ediff file-to-diff (concat (file-name-sans-extension file-to-diff) ".erl.swp")))
	  (progn
	    (setq modified-files nil)
	    (commit-or-abort))))
    nil))


(defun is-a-monitored-file(file)
  "check if a file is monitored by Wrangler for refactoring activities."
  (setq monitored nil)
  (setq dirs dirs-to-monitor)
  (while (and (not monitored) (not (equal dirs nil)))
    (if (string-match (file-name-as-directory (car dirs)) file)
	(setq monitored 'true)
      (setq dirs (cdr dirs))
      ))
  (if monitored 
      (car dirs)
    nil))
	    
	    
(defun commit()
  "commit the refactoring result."
      (erl-spawn
	(erl-send-rpc wrangler-erl-node 'wrangler_preview_server 'commit (list))
	(erl-receive ()
	    ((['rex ['badrpc rsn]]
	      (message "Commit failed: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Commit failed: %s" rsn))
	     (['rex ['ok files logmsg]]
	      ;; check in into the refactor monitoring repository before commiting changes.
	      (condition-case nil
		  (update-repository files logmsg)
		(error "The refactoring monitor is not working properly!"))
	      (dolist (f files)
		(progn
		  (setq old-file-name (elt f 0))
		  (setq new-file-name (elt f 1))
		  (setq swp-file-name (elt f 2))
		  (let ((swp-buff (get-file-buffer swp-file-name)))
		    (if swp-buff (kill-buffer swp-buff)
		      nil))
		  (delete-file  swp-file-name)
		  (let ((buffer (get-file-buffer old-file-name)))
		    (if buffer
			(if (equal old-file-name new-file-name)
			    (with-current-buffer buffer (revert-buffer nil t t))
			  (with-current-buffer buffer
			    (set-visited-file-name new-file-name)
			    (delete-file old-file-name)
			    (revert-buffer nil t t)))
		      nil))))
	          (setq refactoring-committed t)
		  (dolist (uf unopened-files)
		    (kill-buffer (get-file-buffer uf)))
		  (setq unopened-files nil)
		  (setq refactor-mode nil)
		  (if (equal has-warning 'true)
		      (progn
			(message "Refactoring succeeded, but please read the warning message in the *erl-output* buffer.")
			(setq has-warning 'false))
		    (message "Refactoring succeeded."))
		  )))))

(defun abort-changes()
  "abort the refactoring results"
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'wrangler_preview_server 'abort (list))
    (erl-receive ()
	((['rex ['badrpc rsn]]
	  (setq refactor-mode nil)
	  (message "Aborting refactoring failed: %S" rsn))
	 (['rex ['error rsn]]
	  (setq refactor-mode nil)
	  (message "Aborting refactoring failed: %s" rsn))
	 (['rex ['ok files]]
	  (dolist (f files)
	    (progn
	      (let ((buff (get-file-buffer f)))
		(if buff (kill-buffer (get-file-buffer f))
		  nil))
	      (delete-file f)))
	  (dolist (uf unopened-files)
	    (kill-buffer (get-file-buffer uf)))
	  (setq unopened-files nil)
	  (setq refactor-mode nil)
	  (message "Refactoring aborted."))))))      
  
      
(defun commit-or-abort()
  "commit or abort the refactoring result."
  (if (y-or-n-p "Do you want to perform the changes?")
      (commit)
     (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_preview_server 'abort (list))
      (erl-receive ()
	  ((['rex ['badrpc rsn]]
	    (setq refactor-mode nil)
	    (message "Aborting refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (setq refactor-mode nil)
	    (message "Aborting refactoring failed: %s" rsn))
	   (['rex ['ok files]]
	    (dolist (f files)
	      (progn
		(let ((buff (get-file-buffer f)))
		  (if buff (kill-buffer (get-file-buffer f))
		    nil))
		(delete-file f)))
	    (dolist (uf unopened-files)
	      (kill-buffer (get-file-buffer uf)))
	    (setq unopened-files nil)
	    (setq refactor-mode nil)
	    (message "Refactoring aborted.")))))))
      
(add-hook 'ediff-quit-hook 'my-ediff-qh)

(defvar refactor-menu-items
  '(nil
    ("Rename Variable Name" erl-refactor-rename-var)
    ("Rename Function Name" erl-refactor-rename-fun)
    ("Rename Module Name" erl-refactor-rename-mod)
    ("Generalise Function Definition" erl-refactor-generalisation)
    ("Move Function to Another Module" erl-refactor-move-fun)
    ("Function Extraction" erl-refactor-fun-extraction)
    ("Fold Expression Against Function" erl-refactor-fold-expression)
    ("Tuple Function Arguments" erl-refactor-tuple-funpar)
    ("Unfold Function Application" erl-refactor-unfold-fun)
    nil
    ("Introduce a Macro" erl-refactor-new-macro)
    ("Fold Against Macro Definition" erl-refactor-fold-against-macro)
    nil 
    ("Identical Code Detection"
     (("Detect Identical Code in Current Buffer"  erl-refactor-duplicated-code-in-buffer)
      ("Detect Identical Code in Dirs" erl-refactor-duplicated-code-in-dirs)
      ("Identical Expression Search in Current Buffer" erl-refactor-expression-search)
      ("Identical Expression Search in Dirs" erl-refactor-expression-search-in-dirs)
      ))
    nil
    ("Similar Code Detection"
     (("Detect Similar Code in Current Buffer" erl-refactor-similar-code-in-buffer)
      ("Detect Similar Code in Dirs" erl-refactor-similar-code-in-dirs)
      ("Similar Expression Search in Current Buffer" erl-refactor-similar-expression-search)
      ("Similar Expression Search in Dirs" erl-refactor-similar-expression-search-in-dirs)
      ))
    nil
    ("Refactorings for QuickCheck" 
     (
      ("Introduce ?LET" erl-refactor-introduce-let)
      ("Merge ?LETs"    erl-refactor-merge-let)
      ("Merge ?FORALLs"   erl-refactor-merge-forall)
      ("eqc_statem State Data to Record" erl-refactor-eqc-statem-to-record)
      ("eqc_fsm State Data to Record" erl-refactor-eqc-fsm-to-record)
      ("gen_fsm State Data to Record" erl-refactor-gen-fsm-to-record)
     ;; ("eqc_statem to eqc_fsm"  erl-refactor-statem-to-fsm)
     ))
    nil
    ("Process Refactorings (Beta)"
     (
      ("Rename a Process" erl-refactor-rename-process)
      ("Add a Tag to Messages"  erl-refactor-add-a-tag)
      ("Register a Process"   erl-refactor-register-pid)
      ("From Function to Process" erl-refactor-fun-to-process)
      ))
    ("Normalise Record Expression" erl-refactor-normalise-record-expr)
    nil
    ("Undo" erl-refactor-undo)
    nil
    ("Customize Wrangler" wrangler-customize)
    nil
    ("Version" erl-refactor-version)))


(defvar inspector-menu-items
  '(nil
    ("Variable Search" erl-wrangler-code-inspector-var-instances) 
      ("Caller Functions" erl-wrangler-code-inspector-caller-funs)
      ("Caller/Called Modules" erl-wrangler-code-inspector-caller-called-mods)
      ("Nested If Expresssions" erl-wrangler-code-inspector-nested-ifs)
      ("Nested Case Expressions" erl-wrangler-code-inspector-nested-cases)
      ("Nested Receive Expression" erl-wrangler-code-inspector-nested-receives)
      ("Long Functions" erl-wrangler-code-inspector-long-funs)
      ("Large Modules" erl-wrangler-code-inspector-large-mods)
     ;; ("UnCalled Exported Functions" erl-wrangler-code-inspector-uncalled-exports)
      ("Non Tail-recursive Servers" erl-wrangler-code-inspector-non-tail-recursive-servers)
      ("Not Flush UnKnown Messages" erl-wrangler-code-inspector-no-flush)))
 
   
(global-set-key (kbd "C-c C-r") 'toggle-erlang-refactor)

(setq erlang-refactor-status 0)

(add-hook 'erl-nodedown-hook 'wrangler-nodedown)

(setq wrangler-erl-node-string (concat "wrangler" (number-to-string (random 1000)) "@localhost"))

(setq wrangler-erl-node (intern  wrangler-erl-node-string))

(defun wrangler-nodedown(node)
  ( if (equal node wrangler-erl-node)
     (progn (wrangler-menu-remove)
            (setq erlang-refactor-status 0)	
            (message "Wrangler stopped.")
     )
   nil))

(defun toggle-erlang-refactor ()
  (interactive)
  (cond ((= erlang-refactor-status 0)
	 (call-interactively 'erlang-refactor-on)
	 (setq erlang-refactor-status 1))
	((= erlang-refactor-status 1)
	 (call-interactively 'erlang-refactor-off)
	 (setq erlang-refactor-status 0))))


(defun start-wrangler-app()
  (interactive)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'application 'start (list 'wrangler_app))
    (erl-receive()
	((['rex 'ok]
	  (wrangler-menu-init)
	  (message "Wrangler started.")
	  (setq erlang-refactor-status 1))
	 (['rex ['error ['already_started app]]]
	  (message "Wrangler failed to start: another Wrangler application is running.")
	  (setq erlang-refactor-status 0))	 
	 (['rex ['error rsn]]
	  (message "Wrangler failed to start:%s" rsn)
	  (setq erlang-refactor-status 0))))))

(defun erlang-refactor-off()
  (interactive)
  (wrangler-menu-remove) 
  (setq erlang-refactor-status 0)		
  (condition-case nil
      (erl-spawn
	(erl-send-rpc wrangler-erl-node 'application 'stop (list 'wrangler_app))
	)
   (error nil))
  (sleep-for 1.0)
  (condition-case nil   ;; (get-buffer "*Wrangler-Erl-Shell*")
      (kill-buffer "*Wrangler-Erl-Shell*")
    (error nil))
  (message "Wrangler stopped."))

(defun erlang-refactor-on()
  (interactive)
  ;;(if (get-buffer "*Wrangler-Erl-Shell*")
  ;;    (kill-buffer "*Wrangler-Erl-Shell*"))
  
  (condition-case nil   ;; (get-buffer "*Wrangler-Erl-Shell*")
      (kill-buffer "*Wrangler-Erl-Shell*")
    (error nil)
   )
  (setq wrangler-erl-node-string (concat "wrangler" (number-to-string (random 1000)) "@localhost"))
  (setq wrangler-erl-node (intern  wrangler-erl-node-string))
  (sleep-for 1.0)
  (save-window-excursion
     (wrangler-erlang-shell))
  (sleep-for 2.0)
  (start-wrangler-app))

(defun wrangler-erlang-shell()
  "Start a Erlang shell for Wrangler"
  (interactive)
  (call-interactively wrangler-erlang-shell-function))

(defvar wrangler-erlang-shell-function 'wrangler-erlang
  "Command to execute start a new Wrangler Erlang shell"
)

(defvar wrangler-erlang-shell-type 'newshell
	"variable need to make Wrangler start with Ubuntu"
)

(defun wrangler-erlang()
  "Run an Wrangler Erlang shell"
  (interactive)
  (require 'comint)
  (setq opts (list "-name" wrangler-erl-node-string
		   "-pa"  "/usr/local/share/wrangler/ebin"
		   "-setcookie" (erl-cookie)
                   "+R" "9"
		   "-newshell" "-env" "TERM" "vt100"))
  (setq wrangler-erlang-buffer
	(apply 'make-comint
	       "Wrangler-Erl-Shell" "erl"
	       nil opts))
  (setq wrangler-erlang-process
	(get-buffer-process wrangler-erlang-buffer))
  ;;(process-kill-without-query wrangler-erlang-process)
  (switch-to-buffer wrangler-erlang-buffer)
  (if (and (not (eq system-type 'windows-nt))
	   (eq wrangler-erlang-shell-type 'newshell))
      (setq comint-process-echoes t)))

(defun erl-refactor-version()
  (interactive)
  (message "Wrangler version 0.8.7"))

(setq wrangler-version  "(wrangler-0.8.7) ")

(defun wrangler-menu-init()
  "Init Wrangler menus."
  (define-key erlang-mode-map "\C-c\C-_"  'erl-refactor-undo)
  (define-key erlang-mode-map  "\C-c\C-b" 'erl-wrangler-code-inspector-var-instances)
  (define-key erlang-mode-map "\C-c\C-e" 'remove-highlights)
  (erlang-menu-install "Inspector" inspector-menu-items erlang-mode-map t)
  (erlang-menu-install "Refactor" refactor-menu-items erlang-mode-map t))

(defun wrangler-menu-remove()
  "Remove Wrangler menus."
  (define-key erlang-mode-map "\C-c\C-_"  nil)
  (define-key erlang-mode-map  "\C-c\C-b" nil)
  (define-key erlang-mode-map "\C-c\C-e"  nil)
  (erlang-menu-uninstall "Inspector" inspector-menu-items erlang-mode-map t)
  (erlang-menu-uninstall "Refactor" refactor-menu-items erlang-mode-map t))

(defun erlang-menu-uninstall (name items keymap &optional popup)
  "UnInstall a menu in Emacs or XEmacs based on an abstract description."
    (cond (erlang-xemacs-p
	 (let ((menu (erlang-menu-xemacs name items keymap)))
	   (funcall (symbol-function 'delete-menu-item) menu)))
	  ((>= erlang-emacs-major-version 19)
	 (define-key keymap (vector 'menu-bar (intern name))
	   'undefined))
	(t nil)))

(defun erl-refactor-undo()
  "Undo the latest refactoring."
  (interactive)
  (let (buffer (current-buffer))
    (if (y-or-n-p "Undo a refactoring will also undo the editings done after the refactoring, undo anyway?")
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_undo_server 'undo (list))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Undo failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Undo failed: %s" rsn))
	       (['rex ['ok modified1 logmsg curfile]]
		(dolist (f modified1)
		  (let ((oldfilename (car f))
			(newfilename (car (cdr f)))
			(buffer (get-file-buffer (car (cdr f)))))
		    (if buffer (if (not (equal oldfilename newfilename))
				   (with-current-buffer buffer
				     (progn (set-visited-file-name oldfilename)
					    (revert-buffer nil t t)))
				 (with-current-buffer buffer (revert-buffer nil t t)))
		      nil)))
		(let ((dir (is-a-monitored-file curfile)))
		  (if (equal nil dir)
		      nil
		    (condition-case nil
			(progn
			  (let ((reason (read-string "Reason for undo: " nil nil "" nil)))
			    (write-to-refac-logfile dir (concat "UNDO: " logmsg "Reason: " reason)))
			  )
		      (error nil))))
		    (message "Undo succeeded")))))
      (message "Undo aborted."))))

(defun preview-commit-cancel(current-file-name modified)
  (let ((answer (read-char-spec "Do you want to preview(p)/commit(c)/cancel(n) the changes to be performed?(p/c/n):"
		  '((?p p "Answer p to preview the changes")
		    (?c c "Answer c to commit the changes without preview")
		    (?n n "Answer n to abort the changes")))))
    (cond ((eq answer 'p) 
	   (setq modified-files (cdr modified))
	   (wrangler-ediff current-file-name (concat (file-name-sans-extension current-file-name) ".erl.swp")))	  ((eq answer 'c)
	   (commit))
	  ((eq answer 'n)
	   (abort-changes)))))

(defun current-buffer-saved(buffer)
  (let* ((n (buffer-name buffer)) (n1 (substring n 0 1)))
    (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p buffer))
	(if (y-or-n-p "The current buffer has been changed, and Wrangler needs to save it before refactoring, continue?")
	    (progn (save-buffer)
		   t)
	  nil)
      t)))

(defun buffers-saved()
  (let (changed)
      (dolist (b (buffer-list) changed)
	(let* ((n (buffer-name b)) (n1 (substring n 0 1)))
	  (if (and (not (or (string= " " n1) (string= "*" n1))) (buffer-modified-p b))
	      (setq changed (cons (buffer-name b) changed)))))
      (if changed 
	  (if (y-or-n-p (format "There are modified buffers: %s, which Wrangler needs to save before refactoring, continue?" changed))
	      (progn
		(save-some-buffers t)
		t)
	    nil)
	t)
      ))
	

	   
(defun erl-refactor-rename-var (name)
  "Rename an identified variable name."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_var (list current-file-name line-no column-no name wrangler-search-paths tab-width))
	  (erl-receive (line-no column-no current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok modified]]
		(progn
		  (if (equal modified nil)
		      (message "Refactoring finished, and no file has been changed.")
		    (preview-commit-cancel current-file-name modified)
		    (with-current-buffer (get-file-buffer current-file-name)
		      (goto-line line-no)
		      (goto-column column-no))))
	       )))
      (message "Refactoring aborted.")))))

(defun erl-refactor-rename-fun (name)
  "Rename an identified function name."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_fun (list current-file-name line-no column-no name wrangler-search-paths tab-width))
	  (erl-receive (line-no column-no current-file-name name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['warning msg]]
		(progn
		  (if (y-or-n-p msg)
		      (erl-spawn
			(erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring(list 'refac_rename_fun 'rename_fun_1 
							     (list current-file-name line-no column-no name wrangler-search-paths tab-width)))
			(erl-receive (line-no column-no current-file-name)
			    ((['rex ['badrpc rsn]]
			      (message "Refactoring failed: %S" rsn))
			     (['rex ['error rsn]]
			      (message "Refactoring failed: %s" rsn))
			     (['rex ['ok modified warning]]
			      (progn
				(setq has-warning warning)
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line line-no)
				  (goto-column column-no)))))))
		    (message "Refactoring aborted.")
		    )))
	       (['rex ['ok modified warning]]
		(progn
		  (setq has-warning warning)
		  (preview-commit-cancel current-file-name modified)
		  (with-current-buffer (get-file-buffer current-file-name)
		    (goto-line line-no)
		    (goto-column column-no))))
	       )))
      (message "Refactoring aborted."))))
  	 
	      

(defun erl-refactor-rename-mod (name)
  "Rename the current module name."
  (interactive (list (read-string "New module name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
  (if (buffers-saved)
      (erl-spawn
	(erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_mod (list current-file-name name wrangler-search-paths tab-width))
	(erl-receive (buffer name current-file-name)
	    ((['rex ['badrpc rsn]]
	      (message "Refactoring failed: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Refactoring failed: %s" rsn))
	     (['rex ['warning msg]]
	      (progn
		(if (y-or-n-p msg)
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring(list 'refac_rename_mod 'rename_mod_1
										      (list current-file-name name wrangler-search-paths tab-width 'false)))
		      (erl-receive (current-file-name)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['ok modified warning]]
			    (progn 
			      (setq has-warning warning)
			      (preview-commit-cancel current-file-name modified)
			    )))
		      (message "Refactoring aborted.")
		      )))))
	     (['rex ['question msg]]
	      (progn
		(if (y-or-n-p msg)
		  (erl-spawn
		    (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring(list 'refac_rename_mod 'rename_mod_1(list 
								    current-file-name name wrangler-search-paths tab-width 'true)))
		    (erl-receive (current-file-name)
			((['rex ['badrpc rsn]]
			  (message "Refactoring failed: %S" rsn))
			 (['rex ['error rsn]]
			  (message "Refactoring failed: %s" rsn))
			 (['rex ['ok modified warning]]
			  (progn 
			    (setq has-warning warning)
			    (preview-commit-cancel current-file-name modified))
			  ))))
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring(list 'refac_rename_mod 
                                  'rename_mod_1 (list current-file-name name wrangler-search-paths tab-width 'false)))
		    (erl-receive (current-file-name)
			((['rex ['badrpc rsn]]
			  (message "Refactoring failed: %S" rsn))
			 (['rex ['error rsn]]
			  (message "Refactoring failed: %s" rsn))
			 (['rex ['ok modified warning]]
			  (progn 
			    (setq has-warning warning)
			    (preview-commit-cancel current-file-name modified)
			    )))))
			   
		)))
	   (['rex ['ok modified warning]]
	    (progn
	      (setq has-warning warning)
	      (preview-commit-cancel current-file-name modified)
	      )))))
    (message "Refactoring aborted."))))


(defun erl-refactor-rename-process(name)
  "Rename a registered process."
  (interactive (list (read-string "New name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'rename_process (list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (name current-file-name line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['undecidables oldname logmsg]]
	   (if (y-or-n-p "Do you want to continue the refactoring?")
	       (erl-spawn
		 (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_rename_process 'rename_process_1
			       (list current-file-name oldname name wrangler-search-pa tab-width logmsg)))
		 (erl-receive (current-file-name line-no column-no)
		     ((['rex ['badrpc rsn]]
		       (message "Refactoring failed: %S" rsn))
		      (['rex ['error rsn]]
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['ok modified]]
		       (progn
			 (preview-commit-cancel current-file-name modified)
			 (with-current-buffer (get-file-buffer current-file-name)
			   (goto-line line-no)
			   (goto-column column-no)))))))
	     (message "Refactoring aborted!")))
	   (['rex ['ok modified]]
	    (progn
	      (preview-commit-cancel current-file-name modified)
	      (with-current-buffer (get-file-buffer current-file-name)
		(goto-line line-no)
		(goto-column column-no))))
	   )))
      (message "Refactoring aborted!"))))
	  
	    


(defun erl-refactor-unfold-fun()
  "Unfold a function application."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (current-buffer-saved buffer)
    	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'unfold_fun_app(list current-file-name line-no column-no wrangler-search-paths tab-width))
	  (erl-receive (line-no column-no current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok modified]]
		(progn
		  (if (equal modified nil)
		      (message "Refactoring finished, and no file has been changed.")
		    (preview-commit-cancel current-file-name modified))
		  (with-current-buffer (get-file-buffer current-file-name)
		    (goto-line line-no)
		    (goto-column column-no))))
	       )))
      (message "Refactoring aborted."))))
		  

(defun erl-refactor-register-pid(name start end)
  "Register a process with a user-provied name."
  (interactive (list (read-string "process name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (if (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'register_pid
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (current-file-name start-line-no start-col-no end-line-no end-col-no name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['unknown_pnames regpids logmsg]]
		(if (y-or-n-p "Do you want to continue the refactoring?")
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_register_pid 'register_pid_1
				    (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name regpids wrangler-search-paths tab-width logmsg)))
		      (erl-receive (current-file-name start-line-no start-col-no end-line-no end-col-no name)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['unknown_pids pars logmsg]]
			    (if (y-or-n-p "Do you want to continue the refactoring?")
				(erl-spawn
				  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_register_pid 'register_pid_2
						(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width logmsg)))
				  (erl-receive (current-file-name start-line-no start-col-no)
				      ((['rex ['badrpc rsn]]
					(message "Refactoring failed: %S" rsn))
				       (['rex ['error rsn]]
					(message "Refactoring failed: %s" rsn))
				       (['rex ['ok modified]]
					(progn
					  (preview-commit-cancel current-file-name modified)
					  (with-current-buffer (get-file-buffer current-file-name)
					    (goto-line start-line-no)
					    (goto-column start-column-no)))
					))))
			      (message "Refactoring aborted!")))
			   (['rex ['ok modified]]
			    (progn
			      (preview-commit-cancel current-file-name modified)
			      (with-current-buffer (get-file-buffer current-file-name)
				(goto-line start-line-no)
				(goto-column start-column-no)))
			    ))))
		  (message "Refactoring aborted!")))
	       (['rex ['unknown_pids pars logmsg]]
		(if (y-or-n-p "Do you want to continue the refactoring?")
		    (erl-spawn
		      (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_register_pid 'register_pid_2
				    (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width logmsg)))
		      (erl-receive (currnet-file-name start-line-no start-col-no)
			  ((['rex ['badrpc rsn]]
			    (message "Refactoring failed: %S" rsn))
			   (['rex ['error rsn]]
			    (message "Refactoring failed: %s" rsn))
			   (['rex ['ok modified]]
			    (progn
			      (preview-commit-cancel current-file-name modified)
			      (with-current-buffer (get-file-buffer current-file-name)
				(goto-line start-line-no)
				(goto-column start-column-no)))
			    ))))
		  (message "Refactoring aborted!")))
	       (['rex ['ok modified]]
		 (progn
		   (preview-commit-cancel current-file-name modified)
		   (with-current-buffer (get-file-buffer current-file-name)
		     (goto-line start-line-no)
		     (goto-column start-column-no))))
	       )))
       (message "Refactoring aborted."))))

(defun erl-refactor-move-fun (name)
  "Move a function definition from one module to another."
  (interactive (list (read-string "Target Module name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'move_fun
			(list current-file-name line-no column-no name wrangler-search-paths tab-width))
	  (erl-receive (line-no column-no  name current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['question msg]]
		(progn 
		  (if (y-or-n-p msg)
		      (erl-spawn
			(erl-send-rpc wrangler-erl-node 'wrangler 'move_fun_1 
					       (list current-file-name line-no column-no name wrangler-search-paths tab-width))
			(erl-receive (line-no column-no current-file-name)
			    ((['rex ['badrpc rsn]]
			      (message "Refactoring failed: %S" rsn))
			     (['rex ['error rsn]]
			      (message "Refactoring failed: %s" rsn))
			     (['rex ['ok modified]]
			      (progn
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line line-no)
				  (goto-column column-no)))))))
		    (message "Refactoring aborted."))))	
	       (['rex ['warning msg]]
		(progn 
		  (if (y-or-n-p msg)
		      (erl-spawn
			(erl-send-rpc wrangler-erl-node 'wrangler 'move_fun_1 
				      (list current-file-name line-no column-no name wrangler-search-paths tab-width))
			(erl-receive (line-no column-no current-file-name)
			    ((['rex ['badrpc rsn]]
			      (message "Refactoring failed: %S" rsn))
			     (['rex ['error rsn]]
			      (message "Refactoring failed: %s" rsn))
			     (['rex ['ok modified]]
			      (progn
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line line-no)
				  (goto-column column-no)))))))
		    (message "Refactoring aborted."))))	
	       (['rex ['ok modified]]
		(progn
		  (preview-commit-cancel current-file-name modified)
		  (with-current-buffer (get-file-buffer current-file-name)
		    (goto-line line-no)
		    (goto-column column-no))))
	       )))
      (message "Refactoring aborted."))))


;; redefined get-file-buffer to handle the difference between
;; unix and windows filepath seperator.
(defun get-file-buffer (filename)
 (let ((buffer)
	(bs (buffer-list)))
        (while (and (not buffer) (not (equal bs nil)))
	   (let ((b (car bs)))
	     (if (and (buffer-file-name b)
		      (and (equal (file-name-nondirectory filename)
				  (file-name-nondirectory (buffer-file-name b)))
			   (equal (file-name-directory filename)
			    (file-name-directory (buffer-file-name b)))))
		 (setq buffer 'true)
	       (setq bs (cdr bs)))))
	(car bs)))		  



(defun get_instances_to_gen(instances buffer highlight-region-overlay)
  (setq instances-to-gen nil)
  (setq last-position 0)
  (while (not (equal instances nil))
    (setq new-inst (car instances))
    (setq line1 (elt (elt new-inst 0) 0))
    (setq col1  (elt (elt  new-inst 0) 1))
    (setq line2 (elt (elt new-inst 1) 0))
    (setq col2  (elt  (elt new-inst 1) 1))
    (if  (> (get-position line1 col1) last-position)
	(progn 
	  (highlight-region line1 col1 line2  col2 buffer)
	  (if (yes-or-no-p "The expression selected occurs more than once in this function clause, would you like to replace the occurrence highlighted too?")
	      (progn
		(setq instances-to-gen (cons new-inst instances-to-gen))
		(setq last-position (get-position line2 col2)))
	    nil))
      nil)  
    (setq instances (cdr instances)))
  (delete-overlay highlight-region-overlay)
  instances-to-gen)
  

(defun erl-refactor-generalisation(name start end)
  "Generalise a function definition over an user-selected expression."
  (interactive (list (read-string "New parameter name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (if (current-buffer-saved buffer)
   	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'generalise
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (current-file-name wrangler-search-paths start-line-no start-col-no buffer highlight-region-overlay)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['more_than_one_clause pars]]
	    (setq  parname (elt pars 0))
	    (setq funname (elt pars 1))
	    (setq arity (elt pars 2))
	    (setq defpos (elt pars 3))
	    (setq exp (elt pars 4))
	    (setq side_effect (elt pars 5))
	    (setq instances_in_fun (elt pars 6))
	    (setq instances_in_clause (elt pars 7))
	    (setq logmsg (elt pars 8))
	    (if (y-or-n-p "The function selected has multiple clauses, would you like to generalise the function clause selected only?")
		(progn 
		  (with-current-buffer (get-file-buffer current-file-name)
		    (setq instances_to_gen (get_instances_to_gen instances_in_clause buffer highlight-region-overlay)))
		  (erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_clause (list 
				current-file-name parname funname arity defpos exp tab-width side_effect instances_to_gen logmsg)))
		  (erl-receive (start-line-no start-col-no current-file-name)
		      ((['rex ['badrpc rsn]]
			(message "Refactoring failed: %S" rsn))
		       (['rex ['error rsn]]
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok modified]]
			(preview-commit-cancel current-file-name modified)
			(with-current-buffer (get-file-buffer current-file-name)
			  (goto-line start-line-no)
			  (goto-column start-col-no)))))))
	      (progn
		(with-current-buffer (get-file-buffer current-file-name)
		  (setq instances_to_gen (get_instances_to_gen instances_in_fun buffer highlight-region-overlay)))
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 (list side_effect current-file-name parname 
						funname arity defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
		  (erl-receive (start-line-no start-col-no current-file-name)
		      ((['rex ['badrpc rsn]]
		      (message "Refactoring failed: %S" rsn))
		       (['rex ['error rsn]]
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok modified]]
			(preview-commit-cancel current-file-name modified)
			(with-current-buffer (get-file-buffer current-file-name)
			  (goto-line start-line-no)
			  (goto-column start-col-no)))))))))
	   (['rex ['unknown_side_effect pars]]	        
	    (setq  parname (elt pars 0))
	    (setq funname (elt pars 1))
	    (setq arity (elt pars 2))
	    (setq defpos (elt pars 3))
	    (setq exp (elt pars 4))
	    (setq no_of_clauses (elt pars 5))
	    (setq instances_in_fun (elt pars 6))
	    (setq instances_in_clause (elt pars 7))
	    (setq logmsg (elt pars 8))
	    (if (y-or-n-p "Does the expression selected have side effect?")
		(if (> no_of_clauses 1)
		    (if (y-or-n-p "The function selected has multiple clauses, would you like to generalise the function clause selected only?")
			(progn
			  (with-current-buffer (get-file-buffer current-file-name)
			    (setq instances_to_gen (get_instances_to_gen instances_in_clause buffer highlight-region-overlay)))
			  (erl-spawn
			    (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_clause (list current-file-name parname funname arity 
											     defpos exp tab-width 'true instances_to_gen logmsg)))
			  (erl-receive (start-line-no start-col-no current-file-name)
			      ((['rex ['badrpc rsn]]
				(message "Refactoring failed: %S" rsn))
			       (['rex ['error rsn]]
				(message "Refactoring failed: %s" rsn))
			       (['rex ['ok modified]]
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line start-line-no)
				  (goto-column start-col-no)))))))
		      (progn 
			(with-current-buffer (get-file-buffer current-file-name)
			  (setq instances_to_gen (get_instances_to_gen instances_in_fun buffer highlight-region-overlay)))
			(erl-spawn
			  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 (list 'true current-file-name parname funname arity 
										      defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
			  (erl-receive (start-line-no start-col-no current-file-name)
			      ((['rex ['badrpc rsn]]
				(message "Refactoring failed: %S" rsn))
			       (['rex ['error rsn]]
				(message "Refactoring failed: %s" rsn))
			       (['rex ['ok modified]]
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line start-line-no)
				  (goto-column start-col-no))))))))
		   (progn 
			(with-current-buffer (get-file-buffer current-file-name)
			  (setq instances_to_gen (get_instances_to_gen instances_in_fun buffer highlight-region-overlay)))
			(erl-spawn
			  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 (list 'true current-file-name parname funname arity 
										      defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
			  (erl-receive (start-line-no start-col-no current-file-name)
			      ((['rex ['badrpc rsn]]
				(message "Refactoring failed: %S" rsn))
			       (['rex ['error rsn]]
				(message "Refactoring failed: %s" rsn))
			       (['rex ['ok modified]]
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line start-line-no)
				  (goto-column start-col-no)))))))
		  )
	      (if (> no_of_clauses 1)
		  (if (y-or-n-p "The function selected has multiple clauses, would you like to generalise the function clause selected only?")
		      (progn
			(with-current-buffer (get-file-buffer current-file-name)
			    (setq instances_to_gen (get_instances_to_gen instances_in_clause buffer highlight-region-overlay)))
			(erl-spawn
			  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_clause (list current-file-name parname funname 
											   arity defpos exp tab-width 'false instances_to_gen logmsg)))
			  (erl-receive (start-line-no start-col-no current-file-name)
			      ((['rex ['badrpc rsn]]
				(message "Refactoring failed: %S" rsn))
			       (['rex ['error rsn]]
				(message "Refactoring failed: %s" rsn))
			       (['rex ['ok modified]]
				(preview-commit-cancel current-file-name modified)
				(with-current-buffer (get-file-buffer current-file-name)
				  (goto-line start-line-no)
				  (goto-column start-col-no)))))))
		    (progn
		      (with-current-buffer (get-file-buffer current-file-name)
			  		   (setq instances_to_gen (get_instances_to_gen instances_in_fun buffer highlight-region-overlay)))
		      (erl-spawn	   
			(erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 
                               (list 'false current-file-name parname funname arity defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
			(erl-receive (start-line-no start-col-no current-file-name)
			    ((['rex ['badrpc rsn]]
			      (message "Refactoring failed: %S" rsn))
			     (['rex ['error rsn]]
			      (message "Refactoring failed: %s" rsn))
			     (['rex ['ok modified]]
			      (preview-commit-cancel current-file-name modified)
			      (with-current-buffer (get-file-buffer current-file-name)
				(goto-line start-line-no)
				(goto-column start-col-no))))))))
		(progn
		  (with-current-buffer (get-file-buffer current-file-name)
		    (setq instances_to_gen (get_instances_to_gen instances_in_fun buffer highlight-region-overlay)))
		  (erl-spawn	   
		    (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 
					     (list 'false current-file-name parname funname arity defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
		    (erl-receive (start-line-no start-col-no current-file-name)
			((['rex ['badrpc rsn]]
			  (message "Refactoring failed: %S" rsn))
			 (['rex ['error rsn]]
			  (message "Refactoring failed: %s" rsn))
			 (['rex ['ok modified]]
			  (preview-commit-cancel current-file-name modified)
			  (with-current-buffer (get-file-buffer current-file-name)
			    (goto-line start-line-no)
			    (goto-column start-col-no)))))))
		)))
	   (['rex ['multiple_instances pars]]
	    (setq  parname (elt pars 0))
	    (setq funname (elt pars 1))
	    (setq arity (elt pars 2))
	    (setq defpos (elt pars 3))
	    (setq exp (elt pars 4))
	    (setq side_effect (elt pars 5))
	    (setq instances (elt pars 6))
	    (setq logmsg (elt pars 7))
	    (with-current-buffer (get-file-buffer current-file-name)
	      (setq instances_to_gen (get_instances_to_gen instances buffer highlight-region-overlay)))
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_gen 'gen_fun_1 (list side_effect current-file-name parname 
									  funname arity defpos exp wrangler-search-paths tab-width instances_to_gen logmsg)))
	      (erl-receive (start-line-no start-col-no current-file-name)
		  ((['rex ['badrpc rsn]]
		    (message "Refactoring failed: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Refactoring failed: %s" rsn))
		   (['rex ['ok modified]]
		    (preview-commit-cancel current-file-name modified)
		    (with-current-buffer (get-file-buffer current-file-name)
		      (goto-line start-line-no)
		      (goto-column start-col-no)))))))
	   (['rex ['ok modified]]
	    (preview-commit-cancel current-file-name modified)
	    (with-current-buffer (get-file-buffer current-file-name)
	      (goto-line start-line-no)
	      (goto-column start-col-no))))))
      (message "Refactoring aborted."))))
      
	   
(defun erl-refactor-fun-extraction(name start end)
  "Introduce a new function to represent an user-selected expression/expression sequence."
  (interactive (list (read-string "New function name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (if (current-buffer-saved buffer)
  	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fun_extraction
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name tab-width))
	  (erl-receive (start-line-no start-col-no end-line-no end-col-no name current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	        (['rex ['warning msg]]
	    (progn
	      (if (y-or-n-p msg)
		  (erl-spawn
		    (erl-send-rpc wrangler-erl-node 'wrangler 'fun_extraction_1 
				  (list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name tab-width))
		    (erl-receive (current-file-name)
			((['rex ['badrpc rsn]]
			  (message "Refactoring failed: %S" rsn))
			 (['rex ['error rsn]]
			  (message "Refactoring failed: %s" rsn))
			 (['rex ['ok modified]]
			  (preview-commit-cancel current-file-name modified)
			  ))))
		(message "Refactoring aborted.")
		)))
	       (['rex ['ok modified]]
		(preview-commit-cancel current-file-name modified)
		(with-current-buffer (get-file-buffer current-file-name)
		  (goto-line start-line-no)
		  (goto-column start-col-no))))))
      (message "Refactoring aborted."))))
		
(defun erl-refactor-new-macro(name start end)
  "Introduce a new marco to represent an user-selected syntax phrase."
  (interactive (list (read-string "New macro name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (if (current-buffer-saved buffer)
  	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'new_macro
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (start-line-no start-col-no current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok modified]]
		(preview-commit-cancel current-file-name modified)
		(with-current-buffer (get-file-buffer current-file-name)
		  (goto-line start-line-no)
		  (goto-column start-col-no))))))
      (message "Refactoring aborted."))))
      
	
(defun erl-refactor-fold-against-macro()
  "Fold expression(s)/patterns(s) against a macro definition."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_against_macro
		    (list current-file-name line-no column-no wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name line-no column-no highlight-region-overlay )
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok candidates logmsg]]
	    (with-current-buffer buffer
	      (setq candidates-to-fold (get-candidates-to-fold candidates buffer))
	      (if (equal candidates-to-fold nil)
		  (message "Refactoring finished, and no file has been changed.")
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_fold_against_macro 'fold_against_macro_1(list 
                                      current-file-name candidates-to-fold wrangler-search-paths tab-width logmsg)))
		  (erl-receive (current-file-name line-no column-no)
		      ((['rex ['badrpc rsn]]
			(message "Refactoring failed: %S" rsn))
		       (['rex ['error rsn]]
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok modified]]
			(preview-commit-cancel current-file-name modified)
			(with-current-buffer (get-file-buffer current-file-name)
			  (goto-line line-no)
			  (goto-column column-no))))))))
	    ))))))
	      

(defun erl-refactor-fold-expression()
  "Fold expression(s) against function definition."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(if (y-or-n-p 
	     "Fold expressions against the function clause pointed by cursor (answer 'no' if you would like to input information about the function clause manually)? ")
	    (fold_expr_by_loc buffer current-file-name line-no column-no)
	  (fold_expr_by_name buffer current-file-name (read-string "Module name: ") (read-string "Function name: ") (read-string "Arity: ")
			     (read-string "Clause index (starting from 1): ")))
      (message "Refactoring aborted."))))
	 

(defun fold_expr_by_name(buffer current-file-name module-name function-name arity clause-index)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_expr_by_name(list current-file-name module-name function-name arity clause-index wrangler-search-paths tab-width))
    (erl-receive (buffer current-file-name  line-no column-no highlight-region-overlay)
	((['rex ['badrpc rsn]]
	  (message "Refactoring failed: %S" rsn))
	 (['rex ['error rsn]]
	  (message "Refactoring failed: %s" rsn))
	 (['rex ['ok candidates logmsg]]
	  (with-current-buffer buffer
	    (setq candidates-to-fold (get-candidates-to-fold candidates buffer))
	    (if (equal candidates-to-fold nil)
		(message "Refactoring finished, and no file has been changed.")
	      (erl-spawn
		 (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_fold_expression 'do_fold_expression(list 
                                current-file-name candidates-to-fold wrangler-search-paths tab-width logmsg)))
		 (erl-receive (current-file-name line-no column-no)
		     ((['rex ['badrpc rsn]]
		       (message "Refactoring failed: %S" rsn))
		      (['rex ['error rsn]]
		       (message "Refactoring failed: %s" rsn))
		      (['rex ['ok modified]]
		       (preview-commit-cancel current-file-name modified)
		       (with-current-buffer (get-file-buffer current-file-name)
			 (goto-line line-no)
			 (goto-column column-no))))))))
	  )))))
	      
	    
 (defun fold_expr_by_loc(buffer current-file-name line-no column-no)
  (erl-spawn
    (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fold_expr_by_loc(list current-file-name line-no column-no wrangler-search-paths tab-width))
    (erl-receive (buffer current-file-name line-no column-no highlight-region-overlay)
	((['rex ['badrpc rsn]]
	  (message "Refactoring failed: %S" rsn))
	 (['rex ['error rsn]]
	  (message "Refactoring failed: %s" rsn))
	 (['rex ['ok candidates logmsg]]
	  (with-current-buffer buffer
	    (setq candidates-to-fold (get-candidates-to-fold candidates buffer))
	    (if (equal candidates-to-fold nil)
		(message "Refactoring finished, and no file has been changed.")
	      (erl-spawn
		(erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_fold_expression 'do_fold_expression(list 
                          current-file-name candidates-to-fold wrangler-search-paths tab-width logmsg)))
		(erl-receive (current-file-name line-no column-no)
		    ((['rex ['badrpc rsn]]
		      (message "Refactoring failed: %S" rsn))
		     (['rex ['error rsn]]
		      (message "Refactoring failed: %s" rsn))
		     (['rex ['ok modified]]
		      (preview-commit-cancel current-file-name modified)
		      (with-current-buffer (get-file-buffer current-file-name)
			(goto-line line-no)
			(goto-column column-no))))))))
	  )))))


(defun get-candidates-to-fold (candidates buffer)
  (setq candidates-to-fold nil)
  (setq last-position 0)
  (while (not (equal candidates nil))
    (setq new-cand (car candidates))
    (setq line1 (elt new-cand 0))
    (setq col1  (elt  new-cand 1))
    (setq line2 (elt new-cand 2))
    (setq col2  (elt  new-cand 3))
    (setq funcall (elt new-cand 4))
    (setq fundef (elt new-cand 5))
    (if  (> (get-position line1 col1) last-position)
	(progn 
	  (highlight-region line1 col1 line2  col2 buffer)
	  (let ((answer (read-char-spec "Please answer y/n to fold/not fold this expression, or Y/N to fold all/none of remaining candidates including the one highlighted: "
					'((?y y "Answer y to fold this candidate expression;")
					  (?n n "Answer n not to fold this candidate expression;")
					  (?Y Y "Answer Y to fold all the remaining candidate expressions;")
					  (?N N "Answer N to fold none of remaining candidate expressions")))))
	    (cond ((eq answer 'y)
		   (setq candidates-to-fold  (cons new-cand candidates-to-fold))
		   (setq last-position (get-position line2 col2))
		   (setq candidates (cdr candidates)))
		  ((eq answer 'n)
		   (setq candidates (cdr candidates)))
		  ((eq answer 'Y)
		   (setq candidates-to-fold  (append candidates candidates-to-fold))
		   (setq candidates nil))
		  ((eq answer 'N)
		   (setq candidates nil)))))
      (setq candidates nil)))
  (delete-overlay highlight-region-overlay)
  candidates-to-fold)
	      

(defun erl-refactor-duplicated-code-in-buffer(mintokens minclones maxpars)
  "Find code clones in the current buffer."
  (interactive (list (read-string "Minimum number of tokens a code clone should have (default value: 20): ")
		     (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		     (read-string "Maximum number of parameters of least general common abstraction (default value: 5): ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'wrangler_distel 'duplicated_code_in_buffer
									   (list current-file-name mintokens minclones maxpars tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Duplicated code detection failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Duplicated code detection failed: %s" rsn))
	       (['rex ['ok result]]
		(message "Duplicated code detection finished!")))))
      (message "Duplicated code detection aborted."))))



(defun erl-refactor-duplicated-code-in-dirs(mintokens minclones maxpars)
  "Find code clones in the directories specified by the search paths."
  (interactive (list (read-string "Minimum number of tokens a code clone should have (default value: 20): ")
		     (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		     (read-string "Maximum number of parameters of least general common abstraction (default value: 5): ")  
		     ))
  (if (y-or-n-p (format "Find duplicated code in the following directories: %s" wrangler-search-paths))
      (let ((current-file-name (buffer-file-name))
	    (buffer (current-buffer)))
	(if (buffers-saved)
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'duplicated_code_in_dirs
			    (list wrangler-search-paths mintokens minclones maxpars tab-width))
	      (erl-receive (buffer)
		  ((['rex ['badrpc rsn]]
		    (message "Duplicated code detection failed: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Duplicated code detection failed: %s" rsn))
		   (['rex ['ok result]]
		    (message "Duplicated code detection finished.")))))
	  (message "Duplicated code detection aborted.")
	  ))
    (message "Please customize Wrangler Search Paths to check duplicated code in other directories.")
    ))
		   
  

(defun erl-refactor-similar-code-in-dirs(minlen minfreq simiscore)
  "Similar code detection in dirs."
 (interactive (list (read-string "Minimum length of an expression sequence (default value: 5): ")
		    (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		    (read-string "Please input a similarity score between 0.1 and 1.0 (default value: 0.8):")
		    ))
 (if (y-or-n-p (format "Find similar code in the following directories: %s" wrangler-search-paths))
     (let ((current-file-name (buffer-file-name))
	   (buffer (current-buffer)))
       (if (buffers-saved)
	   (erl-spawn
	     (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_sim_code 'sim_code_detection
			   (list wrangler-search-paths minlen minfreq simiscore wrangler-search-paths tab-width)))
	     (erl-receive (buffer)
		 ((['rex ['badrpc rsn]]
		   (message "Similar code detection failed: %S" rsn))
		  (['rex ['error rsn]]
		   (message "Similar code detection failed: %s" rsn))
		  (['rex ['ok result]]
		   (message "Similar code detection finished.")))))
	 (message "Similar code detection aborted.")
	 ))
     (message "Please customize Wrangler Search Paths to check similar code in other directories.")
    ))

		   
  
(defun erl-refactor-similar-code-in-buffer(minlen minfreq simiscore)
  "Similar code detection in the current buffer."
 (interactive (list (read-string "Minimum length of an expression sequence (default value: 5): ")
		    (read-string "Minimum number of appearance times (minimum and default value: 2): ")
		    (read-string "Please input a similarity score between 0.1 and 1.0 (default value: 0.8):")
		    ))
 (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
   (remove-highlights)
   (if (current-buffer-saved buffer)
       (erl-spawn
	 (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_sim_code 'sim_code_detection_in_buffer
				    (list current-file-name minlen minfreq simiscore  wrangler-search-paths tab-width)))
	 (erl-receive (buffer current-file-name)
	     ((['rex ['badrpc rsn]]
	       (message "Searching failed: %S" rsn))
	      (['rex ['error rsn]]
	       (message "Searching failed: %s" rsn))
	      (['rex ['ok result]]
	       (message "Similar code detection finished.")
	       ))))
       (message "Similar code detection aborted.")
       )))
	

(defun erl-refactor-expression-search(start end)
  "Search an user-selected expression or expression sequence in the current buffer."
  (interactive (list (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (remove-highlights)
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'expression_search_in_buffer
			(list current-file-name start-line-no start-col-no end-line-no end-col-no wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Searching failed: %S" rsn))
	       (['rex ['error rsn]]
	    (message "Searching failed: %s" rsn))
	       (['rex ['ok regions]]
		(with-current-buffer buffer
		  (highlight-instances-1 regions (car regions) buffer)
		  (message "Searching finished; use 'C-c C-e' to remove highlights.\n")
		  )))))
      (message "Refactoring aborted."))))

(defun erl-refactor-expression-search-in-dirs(start end)
  "Search an user-selected expression or expression sequence across the project."
  (interactive (list (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (remove-highlights)
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'expression_search_in_dirs
			(list current-file-name start-line-no start-col-no end-line-no end-col-no wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Searching failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Searching failed: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.\n")
	       ))))
      (message "Refactoring aborted."))))


(defun erl-refactor-similar-expression-search(similarity-score start end)
  "Search expressions that are similar to an user-selected expression or expression sequence in the current buffer."
  (interactive (list (read-string "Please input a similarity score between 0.1 and 1.0 (default value: 0.8):")
		(region-beginning)
		(region-end)
		))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (remove-highlights)
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'similar_expression_search_in_buffer
			(list current-file-name start-line-no start-col-no end-line-no end-col-no similarity-score wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Searching failed: %S" rsn))
	       (['rex ['error rsn]]
	    (message "Searching failed: %s" rsn))
	       (['rex ['ok regions]]
		(with-current-buffer buffer 
		  (highlight-instances-1 regions (car regions) buffer)
		  (message "Searching finished; use 'C-c C-e' to remove highlights.\n")
		  )))))
      (message "Refactoring aborted."))))



(defun erl-refactor-similar-expression-search-in-dirs(similarity-score start end)
  "Search expressions that are similar to an user-selected expression or expression sequence in the current buffer."
  (interactive (list (read-string "Please input a similarity score between 0.1 and 1.0 (default value: 0.8):")
		(region-beginning)
		(region-end)
		))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (remove-highlights)
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'similar_expression_search_in_dirs
			(list current-file-name start-line-no start-col-no end-line-no end-col-no similarity-score wrangler-search-paths tab-width))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Searching failed: %S" rsn))
	       (['rex ['error rsn]]
	    (message "Searching failed: %s" rsn))
	       (['rex ['ok regions]]
		(with-current-buffer buffer 
		  (highlight-instances-1 regions (car regions) buffer)
		  (message "Searching finished; use 'C-c C-e' to remove highlights.\n")
		  )))))
      (message "Refactoring aborted."))))

(defun erl-refactor-fun-to-process (name)
  "From a function to a process."
  (interactive (list (read-string "Process name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'fun_to_process (list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (current-file-name line-no column-no name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['undecidables msg logmsg]]
	     (if (y-or-n-p "Do you still want to continue the refactoring?")
		 (erl-spawn
		   (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_fun_to_process 'fun_to_process_1
				 (list current-file-name line-no column-no  name wrangler-search-paths tab-width logmsg)))
		   (erl-receive (line-no column-no current-file-name)
		       ((['rex ['badrpc rsn]]
			 (message "Refactoring failed: %S" rsn))
			(['rex ['error rsn]]
			 (message "Refactoring failed: %s" rsn))
			(['rex ['ok modified]]
			 (preview-commit-cancel current-file-name modified)
			 (with-current-buffer (get-file-buffer current-file-name)
			   (goto-line line-no)
			   (goto-column column-no)))))))
	     (message "Refactoring aborted!")))
	   (['rex ['ok modified]]
	    (progn
	      (preview-commit-cancel current-file-name modified)
	      (with-current-buffer (get-file-buffer current-file-name)
		(goto-line line-no)
		(goto-column column-no))))
	 ))))


(defun current-line-no ()
  "grmpff. does anyone understand count-lines?"
  (+ (if (eq 0 (current-column)) 1 0)
     (count-lines (point-min) (point)))
  )

(defun current-column-no ()
  "the column number of the cursor"
  (+ 1 (current-column)))


(defun line-no-pos (pos)
  "grmpff. why no parameter to current-column?"
  (save-excursion
    (goto-char pos)
    (+ (if (eq 0 (current-column)) 1 0)
       (count-lines (point-min) (point))))
  )

(defun current-column-pos (pos)
  "grmpff. why no parameter to current-column?"
  (save-excursion
    (goto-char pos) (+ 1 (current-column)))
  )


(defun get-position(line col)
  "get the position at lie (line, col)"
  (save-excursion
    (goto-line line)
    (move-to-column col)
    (- (point) 1)))


(defun goto-column(col)
  (if (> col 0)
      (move-to-column (- col 1))
    (move-to-column col)))
		      

(defvar highlight-region-overlay
  ;; Dummy initialisation
  (make-overlay 1 1)
  "Overlay for highlighting.")

(defface highlight-region-face
  '((t (:background "CornflowerBlue")))
    "Face used to highlight current line.")

(defun highlight-region(line1 col1 line2 col2 buffer)
  "hightlight the specified region"
  (overlay-put highlight-region-overlay
	       'face 'highlight-region-face)
 ;; (message "pos: %s, %s, %s, %s" line1 col1 line2 col2)
  (move-overlay highlight-region-overlay (get-position line1 col1)
		(get-position line2 (+ 1 col2)) buffer)
   (goto-line line2)
   (goto-column col2)
  )


(defun highlight-search-results(regions buffer highlight-region-overlay)
  "highlight the found results one by one"
  (while (not (equal regions nil))
    (setq reg (car regions))
    (setq line1 (elt reg 0))
    (setq col1  (elt  reg 1))
    (setq line2 (elt reg 2))
    (setq col2  (elt  reg 3))
    (highlight-region line1 col1 line2  col2 buffer)
   ;; (message "Press 'Enter' key to go to the next instance, any other key to exit.")
    (let ((input (read-event)))
      (if (equal input 'return)
	  (progn (setq regions (cdr regions))
	         (message  " ")
	   )
	(if (equal input 'escape)
	    (setq regions nil)
	  (message "Press 'Enter' key to go to the next instance, 'Esc' key to exit.")
	  )
	)
      ))
  (delete-overlay highlight-region-overlay)
  )

(defun erl-refactor-instrument-prog ()
  "Instrument an Erlang program to trace process communication."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'instrument_prog(list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	       (dolist (f modified)
		 (let ((buffer (get-file-buffer f)))
		   (if buffer (with-current-buffer buffer (revert-buffer nil t t))
		     ;;(message-box (format "modified unopened file: %s" f))))))
		     nil))))
	       (message "Refactoring succeeded!")))))))

(defun erl-refactor-uninstrument-prog ()
  "Uninstrument an Erlang program to remove the code added by Wrangler to trace process communication."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'uninstrument_prog(list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (with-current-buffer buffer
	       (dolist (f modified)
		 (let ((buffer (get-file-buffer f)))
		   (if buffer (with-current-buffer buffer (revert-buffer nil t t))
		     ;;(message-box (format "modified unopened file: %s" f))))))
		     nil))))
	       (message "Refactoring succeeded!")))))))


(defun erl-refactor-add-a-tag (name)
  "Add a tag to the messages received by a process."
  (interactive (list (read-string "Tag to add: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'add_a_tag(list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (name current-file-name line-no column-no)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok modified]]
	    (progn
	      (preview-commit-cancel current-file-name modified)
	      (with-current-buffer (get-file-buffer current-file-name)
		(goto-line line-no)
		(goto-column column-no)))))))))
	   

(defun erl-refactor-add-a-tag-1 (name)
  "Add a tag to the messages received by a process."
  (interactive (list (read-string "Tag to add: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'add_a_tag(list current-file-name line-no column-no name wrangler-search-paths tab-width))
      (erl-receive (buffer name current-file-name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['ok candidates]]
	    (with-current-buffer buffer (revert-buffer nil t t) 
	      (while (not (equal candidates nil))
		(setq send (car candidates))
		(setq mod (elt send 0))
		(setq fun (elt send 1))
		(setq arity (elt send 2))
		(setq index (elt send 3))
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_add_a_tag 'send_expr_to_region(list 
												current-file-name mod fun arity index tab-width)))
		  (erl-receive (buffer current-file-name name)
		      ((['rex ['badrpc rsn]]
			;;  (setq candidates nil)
			(message "Refactoring failed: %s" rsn))					  
		       (['rex ['error rsn]]
			;;  (setq candidates nil)
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok region]]
			(with-current-buffer buffer 
			(progn (setq line1 (elt region 0))
			       (setq col1 (elt region 1))
			       (setq line2 (elt region 2))
			       (setq col2 (elt region 3))
			       (highlight-region line1 col1 line2  col2 buffer)
			       (if (y-or-n-p "Should a tag be added to this expression? ")
				   (erl-spawn (erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring (list 'refac_add_a_tag 'add_a_tag(list 
                                                 current-file-name name line1 col1 line2 col2 tab-width)))
				     (erl-receive (buffer)
					 ((['rex ['badrpc rsn]]
					   (message "Refactoring failed: %s" rsn))
					  (['rex ['error rsn]]
					   (message "Refactoring failed: %s" rsn))
					  (['rex ['ok res]]
					   (with-current-buffer buffer (revert-buffer nil t t)
						(delete-overlay highlight-region-overlay))
					  ))))
				(delete-overlay highlight-region-overlay)
			       )))))))
		(setq candidates (cdr candidates)))
	      (with-current-buffer buffer (revert-buffer nil t t))
	      ;; (delete-overlay highlight-region-overlay)
	      (message "Refactoring succeeded!"))))))))
 
(defun erl-refactor-tuple-funpar (start end)
  "Tuple function argument."
  (interactive (list (region-beginning)
		     (region-end)
		     ))
  (let((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end))) 
    (if (buffers-saved)
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'tuple_funpar (list current-file-name start-line-no start-col-no end-line-no end-col-no 
									   wrangler-search-paths tab-width))
      (erl-receive (start-line-no start-col-no current-file-name)
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['warning msg]]
	    (progn
	      (if (y-or-n-p msg)
		  (erl-spawn
		    (erl-send-rpc wrangler-erl-node 'refac_distel 'tuple_funpar_1(list current-file-name start-line-no start-col-no end-line-no end-col-no 
										       wrangler-search-paths tab-width))
		    (erl-receive (line-no column-no current-file-name)
			((['rex ['badrpc rsn]]
			  (message "Refactoring failed: %S" rsn))
			 (['rex ['error rsn]]
			  (message "Refactoring failed: %s" rsn))
			 (['rex ['ok modified]]
			  (progn
			    (preview-commit-cancel current-file-name modified)
			    (with-current-buffer (get-file-buffer current-file-name)
			      (goto-line line-no)
			      (goto-column column-no)))))))
		(message "Refactoring aborted.")
		)))
	   (['rex ['ok modified]]
	    (progn
	      (preview-commit-cancel current-file-name modified)
	      (with-current-buffer (get-file-buffer current-file-name)
		(goto-line start-line-no)
		(goto-column start-col-no))))
	   )))
    (message "Refactoring aborted."))))
  	    


(defun erl-refactor-normalise-record-expr ()
  "Normalise a record expression."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (current-buffer-saved buffer)
	(if (y-or-n-p "Show record fields with default values?")	    
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'normalise_record_expr(list current-file-name line-no column-no 'true wrangler-search-paths tab-width))
	      (erl-receive (line-no column-no current-file-name)
		  ((['rex ['badrpc rsn]]
		    (message "Refactoring failed: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Refactoring failed: %s" rsn))
		   (['rex ['ok modified]]
		    (progn
		      (if (equal modified nil)
			  (message "Refactoring finished, and no file has been changed.")
			(if (y-or-n-p "Do you want to preview the changes to be performed?")
			    (wrangler-ediff current-file-name (concat (file-name-sans-extension current-file-name) ".erl.swp"))
			  (commit)))
		      (with-current-buffer (get-file-buffer current-file-name)
			(goto-line line-no)
			(goto-column column-no))))
		   )))
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler_distel 'normalise_record_expr(list current-file-name line-no column-no 'false wrangler-search-paths tab-width))
	    (erl-receive (line-no column-no current-file-name)
		((['rex ['badrpc rsn]]
		  (message "Refactoring failed: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Refactoring failed: %s" rsn))
		   (['rex ['ok modified]]
		    (progn
		      (if (equal modified nil)
			  (message "Refactoring finished, and no file has been changed.")
			(if (y-or-n-p "Do you want to preview the changes to be performed?")
			    (wrangler-ediff current-file-name (concat (file-name-sans-extension current-file-name) ".erl.swp"))
			  (commit)))
		      (with-current-buffer (get-file-buffer current-file-name)
			(goto-line line-no)
			(goto-column column-no))))
		   ))))
      (message "Refactoring aborted.")
      )))
		  


(defun erl-refactor-introduce-let(name start end)
  "Introduce dependence between quickcheck generators."
  (interactive (list (read-string "Pattern variable name: ")
		     (region-beginning)
		     (region-end)
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer))
	(start-line-no (line-no-pos start))
	(start-col-no  (current-column-pos start))
	(end-line-no   (line-no-pos end))
	(end-col-no    (current-column-pos end)))
    (if (current-buffer-saved buffer)
  	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'new_let
			(list current-file-name start-line-no start-col-no end-line-no (- end-col-no 1) name wrangler-search-paths tab-width))
	  (erl-receive (start-line-no start-col-no current-file-name name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['question msg expr parent-expr cmd]]
		(progn
		  (if (y-or-n-p msg)
		      (erl-spawn
			(erl-send-rpc wrangler-erl-node 'wrangler 'try_refactoring(list 'refac_new_let 'new_let_1(list 
								current-file-name name expr parent-expr wrangler-search-paths tab-width cmd)))
			(erl-receive (current-file-name)
			    ((['rex ['badrpc rsn]]
			      (message "Refactoring failed: %S" rsn))
			     (['rex ['error rsn]]
			      (message "Refactoring failed: %s" rsn))
			     (['rex ['ok modified]]
			      (preview-commit-cancel current-file-name modified)
			      ))))
		    (message "Refactoring failed: the expression selected is not a QuickCheck generator.")
		    )))		
	       (['rex ['ok modified]]
		(preview-commit-cancel current-file-name modified)
		(with-current-buffer (get-file-buffer current-file-name)
		  (goto-line start-line-no)
		  (goto-column start-col-no))))))
      (message "Refactoring aborted."))))


(defun erl-refactor-merge-let()
  "Merge undependent ?LET applications."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'merge_let
		    (list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name highlight-region-overlay )
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['not_found msg]]
	    (message "%s" msg))
	   (['rex ['ok candidates logmsg]]
	    (with-current-buffer buffer
	      (setq candidates-to-fold (get-candidates-to-merge candidates buffer))
	      (if (equal candidates-to-fold nil)
		  (message "Refactoring finished, and nothing has been changed.")
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'merge_let_1 (list 
                                      current-file-name candidates-to-fold wrangler-search-paths tab-width logmsg))
		  (erl-receive (current-file-name)
		      ((['rex ['badrpc rsn]]
			(message "Refactoring failed: %S" rsn))
		       (['rex ['error rsn]]
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok modified]]
			(preview-commit-cancel current-file-name modified)
			))))))
	    ))))))
	      
      

(defun erl-refactor-merge-forall()
  "Merge undependent ?FORALL applications."
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))       
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler_distel 'merge_forall
		    (list current-file-name wrangler-search-paths tab-width))
      (erl-receive (buffer current-file-name highlight-region-overlay )
	  ((['rex ['badrpc rsn]]
	    (message "Refactoring failed: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Refactoring failed: %s" rsn))
	   (['rex ['not_found msg]]
	    (message "%s" msg))
	   (['rex ['ok candidates logmsg]]
	    (with-current-buffer buffer
	      (setq candidates-to-fold (get-candidates-to-merge candidates buffer))
	      (if (equal candidates-to-fold nil)
		  (message "Refactoring finished, and nothing has been changed.")
		(erl-spawn
		  (erl-send-rpc wrangler-erl-node 'wrangler 'merge_forall_1 (list 
                                      current-file-name candidates-to-fold wrangler-search-paths tab-width logmsg))
		  (erl-receive (current-file-name)
		      ((['rex ['badrpc rsn]]
			(message "Refactoring failed: %S" rsn))
		       (['rex ['error rsn]]
			(message "Refactoring failed: %s" rsn))
		       (['rex ['ok modified]]
			(preview-commit-cancel current-file-name modified)
			))))))
	    ))))))

(defun get-candidates-to-merge (candidates buffer)
  (setq candidates-to-merge nil)
  (setq last-position 0)
  (while (not (equal candidates nil))
    (setq new-cand (car candidates))
    (setq loc (elt new-cand 0))
    (setq line1 (elt loc 0))
    (setq col1  (elt  loc 1))
    (setq line2 (elt loc 2))
    (setq col2  (elt  loc 3))
    (setq newletapp (elt new-cand 1))
    (if  (> (get-position line1 col1) last-position)
	(progn 
	  (highlight-region line1 col1 line2  col2 buffer)
	  (let ((answer (read-char-spec "Please answer y/n to merge/not merge this expression, or Y/N to merge all/none of remaining candidates including the one highlighted: "
					'((?y y "Answer y to merge this candidate expression;")
					  (?n n "Answer n not to merge this candidate expression;")
					  (?Y Y "Answer Y to merge all the remaining candidate expressions;")
					  (?N N "Answer N to merge none of remaining candidate expressions")))))
	    (cond ((eq answer 'y)
		   (setq candidates-to-merge  (cons new-cand candidates-to-merge))
		   (setq last-position (get-position line2 col2))
		   (setq candidates (cdr candidates)))
		  ((eq answer 'n)
		   (setq candidates (cdr candidates)))
		  ((eq answer 'Y)
		   (setq candidates-to-merge  (append candidates candidates-to-merge))
		   (setq candidates nil))
		  ((eq answer 'N)
		   (setq candidates nil)))))
      (setq candidates nil)))
  (delete-overlay highlight-region-overlay)
  candidates-to-merge)

(defun erl-refactor-eqc-statem-to-record()
   "Turn a non-record eqc-statem state to a recrod."
   (interactive) 
   (let ((current-file-name (buffer-file-name))
 	(buffer (current-buffer)))
     (if (current-buffer-saved buffer)
	 (erl-spawn
	   (erl-send-rpc wrangler-erl-node 'wrangler_distel 'eqc_statem_to_record (list current-file-name wrangler-search-paths tab-width))
	   (erl-receive (current-file-name)
 	      ((['rex ['badrpc rsn]]
 		(message "Refactoring failed: %S" rsn))
 	       (['rex ['error rsn]]
 		(message "Refactoring failed: %s" rsn))
 	       (['rex ['ok ['tuple no-of-fields] state-funs ]]
		(erl-refactor-state-to-record-1 current-file-name no-of-fields state-funs 'true 'eqc_statem_to_record_1))
	       (['rex ['ok non-tuple state-funs]]
		(if (yes-or-no-p "The current type of the state is not tuple; create a record with a single field?")
		    (erl-refactor-state-to-record-1 current-file-name 1 state-funs 'false 'eqc_statem_to_record_1)
		  (message "Refactoring aborted.")))		      
	       )))
       (message "Refactoring aborted."))))


(defun erl-refactor-eqc-fsm-to-record()
   "Turn a non-record eqc-fsm state to a recrod."
   (interactive) 
   (let ((current-file-name (buffer-file-name))
 	(buffer (current-buffer)))
     (if (current-buffer-saved buffer)
	 (erl-spawn
	   (erl-send-rpc wrangler-erl-node 'wrangler_distel 'eqc_fsm_to_record (list current-file-name wrangler-search-paths tab-width))
	   (erl-receive (current-file-name)
 	      ((['rex ['badrpc rsn]]
 		(message "Refactoring failed: %S" rsn))
 	       (['rex ['error rsn]]
 		(message "Refactoring failed: %s" rsn))
 	       (['rex ['ok ['tuple no-of-fields] state-funs]]
		(erl-refactor-state-to-record-1 current-file-name no-of-fields state-funs 'true 'eqc_fsm_to_record_1))
	       (['rex ['ok non-tuple state-funs]]
		(if (yes-or-no-p "The current type of the state is not tuple; create a record with a single field?")
		    (erl-refactor-state-to-record-1 current-file-name 1 state-funs 'false 'eqc_fsm_to_record_1)
		  (message "Refactoring aborted.")))		      
	       )))
       (message "Refactoring aborted."))))


(defun erl-refactor-gen-fsm-to-record()
   "Turn a non-record gen-fsm state to a recrod."
   (interactive) 
   (let ((current-file-name (buffer-file-name))
 	(buffer (current-buffer)))
     (if (current-buffer-saved buffer)
	 (erl-spawn
	   (erl-send-rpc wrangler-erl-node 'wrangler_distel 'gen_fsm_to_record (list current-file-name wrangler-search-paths tab-width))
	   (erl-receive (current-file-name)
 	      ((['rex ['badrpc rsn]]
 		(message "Refactoring failed: %S" rsn))
 	       (['rex ['error rsn]]
 		(message "Refactoring failed: %s" rsn))
 	       (['rex ['ok ['tuple no-of-fields] state-funs]]
		(erl-refactor-state-to-record-1 current-file-name no-of-fields state-funs 'true 'gen_fsm_to_record_1))
	       (['rex ['ok non-tuple state-funs]]
		(if (yes-or-no-p "The current type of the state is not tuple; create a record with a single field?")
		    (erl-refactor-state-to-record-1 current-file-name 1 state-funs 'false 'gen_fsm_to_record_1)
		  (message "Refactoring aborted.")))		      
	       )))
       (message "Refactoring aborted."))))

(defun erl-refactor-state-to-record-1(current-file-name no-of-fields state-funs is-tuple function-name)
  "Turn a non-record state to a record."
  (interactive)
  (setq num 1)
  (setq field-names nil)
  (let ((record-name (read-string "Record name: "))
	(buffer (get-file-buffer current-file-name)))    
    (while (not (> num no-of-fields))
      (let ((str (format "Field name %d of %d : " num no-of-fields)))
	(setq field-names (cons (read-string str) field-names))
	(setq num (+ num 1))))
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler function-name 
			(list current-file-name record-name (reverse field-names) state-funs is-tuple wrangler-search-paths tab-width))
	  (erl-receive (current-file-name)
 	      ((['rex ['badrpc rsn]]
 		(message "Refactoring failed: %S" rsn))
 	       (['rex ['error rsn]]
 		(message "Refactoring failed: %s" rsn))
 	       (['rex ['ok modified]]
		(preview-commit-cancel current-file-name modified)
	       ))))
	  (message "Refactoring aborted."))))


(defun erl-refactor-statem-to-fsm (name)
  "From eqc_statem to eqc_fsm."
  (interactive (list (read-string "Initial state name: ")
		     ))
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (if (current-buffer-saved buffer)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler_distel 'eqc_statem_to_fsm (list current-file-name name wrangler-search-paths tab-width))
	  (erl-receive (current-file-name)
	      ((['rex ['badrpc rsn]]
		(message "Refactoring failed: %S" rsn))
	       (['rex ['error rsn]]
		(message "Refactoring failed: %s" rsn))
	       (['rex ['ok modified]]
		(progn
		  (if (equal modified nil)
		      (message "Refactoring finished, and no file has been changed.")
		    (preview-commit-cancel current-file-name modified)
		    )))))
      (message "Refactoring aborted.")))))

  
(defun erl-wrangler-code-inspector-var-instances()
  "Sematic search of instances of a variable"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (remove-highlights)
    (save-buffer)
    (erl-spawn
      (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'find_var_instances(list 
											   current-file-name line-no column-no wrangler-search-paths tab-width)))
      (erl-receive (buffer)
	  ((['rex ['badrpc rsn]]
	    (message "Error: %S" rsn))
	   (['rex ['error rsn]]
	    (message "Error: %s" rsn))
	   (['rex ['ok regions defpos]]
	    (with-current-buffer buffer (highlight-instances regions defpos buffer)
				 (message "\nUse 'C-c C-e' to remove highlights.\n")
				 )
				       		
	    ))))))

(defun remove-highlights()
  "remove highligths in the buffer"
  (interactive)
  (dolist (ov (overlays-in  1 10000))
    (delete-overlay ov))				 
  (remove-overlays))

(defun highlight-instances(regions defpos buffer)
  "highlight regions in the buffer"
  (dolist (r regions)
     (if (member (elt r 0) defpos)
	 (highlight-def-instance r buffer)
       (highlight-use-instance r buffer))))


(defun highlight-instances-1(regions selected buffer)
  "highlight regions in the buffer"
  (dolist (r regions)
    (if (equal r selected)
	(highlight-def-instance (elt r 1) buffer)
      (highlight-use-instance (elt r 1) buffer))))

;; shouldn't code this really.
(defun highlight-def-instance(region buffer)
   "highlight one region in the buffer"
   (let ((line1 (elt (elt region 0) 0))
	  (col1 (elt (elt region 0) 1))
	  (line2 (elt (elt region 1) 0))
	  (col2 (elt (elt region 1) 1))
	 (overlay (make-overlay 1 1)))
     (overlay-put overlay  'face '((t (:background "orange"))))
     (move-overlay overlay (get-position line1 col1)
		   (get-position line2 (+ col2 1)) buffer)
     ))


(defun highlight-use-instance(region buffer)
   "highlight one region in the buffer"
   (let ((line1 (elt (elt region 0) 0))
	  (col1 (elt (elt region 0) 1))
	  (line2 (elt (elt region 1) 0))
	  (col2 (elt (elt region 1) 1))
	 (overlay (make-overlay 1 1)))
     (overlay-put overlay  'face '((t (:background "CornflowerBlue"))))
     (move-overlay overlay (get-position line1 col1)
		   (get-position line2 (+ col2 1)) buffer)
     ))


(defun erl-wrangler-code-inspector-nested-cases(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(if (y-or-n-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 
			  'wrangler
			  'try_inspector(list 'wrangler_code_inspector 'nested_case_exprs_in_file 
						(list current-file-name level wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 
			'wrangler
			'try_inspector(list 'wrangler_code_inspector 'nested_case_exprs_in_dirs 
					      (list level wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		)))))
      (message "Searching aborted."))))



(defun erl-wrangler-code-inspector-nested-ifs(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
      	(if (y-or-n-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'nested_if_exprs_in_file(list 
                                           current-file-name level wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 
                                           'nested_if_exprs_in_dirs(list level wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		)))))
      (message "Searching aborted."))))
       

(defun erl-wrangler-code-inspector-nested-receives(level)
  "Sematic search of instances of a variable"
  (interactive (list (read-string "Nest level: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
   	(if (y-or-n-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'nested_receive_exprs_in_file(list 
                                   current-file-name level wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'nested_receive_exprs_in_dirs(list 
                                                 level wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		)))))
      (message "Searching aborted."))))
      



(defun erl-wrangler-code-inspector-caller-called-mods()
  "Sematic search of instances of a variable"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if  (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'caller_called_modules(list
                     current-file-name wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Analysis finished.")
	       ))))
      (message "Refactoring aborted."))))


(defun erl-wrangler-code-inspector-long-funs(lines)
  "Search for long functions"
  (interactive (list (read-string "Number of lines: ")))
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
      	(if (y-or-n-p "Only check the current buffer?")
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'long_functions_in_file(list 
                      current-file-name lines wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'long_functions_in_dirs(list 
                             lines wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	      ((['rex ['badrpc rsn]]
		(message "Error: %S" rsn))
	       (['rex ['error rsn]]
		(message "Error: %s" rsn))
	       (['rex ['ok regions]]
		(message "Searching finished.")
		)))))
      (message "Searching aborted."))))


(defun erl-wrangler-code-inspector-large-mods(lines)
  "Search for large modules"
  (interactive (list (read-string "Number of lines: ")))
  (let 	(buffer (current-buffer))
    (if (buffers-saved)
      (erl-spawn
	(erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'large_modules(list lines wrangler-search-paths tab-width)))
	(erl-receive (buffer)
	    ((['rex ['badrpc rsn]]
	      (message "Error: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Error: %s" rsn))
	     (['rex ['ok mods]]
	      (message "Searching finished.")
	      ))))
      (message "Searching aborted."))))

(defun erl-wrangler-code-inspector-caller-funs()
  "Search for caller functions"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(line-no           (current-line-no))
        (column-no         (current-column-no))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(erl-spawn
	  (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'caller_funs(list 
                            current-file-name line-no column-no  wrangler-search-paths tab-width)))
	  (erl-receive (buffer)
	    ((['rex ['badrpc rsn]]
	      (message "Error: %S" rsn))
	     (['rex ['error rsn]]
	      (message "Error: %s" rsn))
	     (['rex ['ok funs]]
	      (message "Searching finished.")))))
      (message "Searching aborted.")
      )))


(defun erl-wrangler-code-inspector-non-tail-recursive-servers()
  "Search for non tail-recursive servers"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (if (buffers-saved)
	(if (y-or-n-p "Only check the current buffer?")
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'non_tail_recursive_servers_in_file(list 
                            current-file-name wrangler-search-paths tab-width)))
	      (erl-receive (buffer)
		  ((['rex ['badrpc rsn]]
		    (message "Error: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Error: %s" rsn))
		   (['rex ['ok regions]]
		    (message "Searching finished.")
		    ))))
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 
			  'wrangler 'try_inspector (list 'wrangler_code_inspector  'non_tail_recursive_servers_in_dirs(list wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  )))))
      (message "Searching aborted.")
      )))
      
	  

(defun erl-wrangler-code-inspector-no-flush()
  "Search for servers without flush of unknown messages"
  (interactive)
  (let ((current-file-name (buffer-file-name))
	(buffer (current-buffer)))
    (if (buffers-saved)
  	(if (y-or-n-p "Only check the current buffer?")
	    (erl-spawn
	      (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'not_flush_unknown_messages_in_file(list 
                          current-file-name wrangler-search-paths tab-width)))
	      (erl-receive (buffer)
		  ((['rex ['badrpc rsn]]
		    (message "Error: %S" rsn))
		   (['rex ['error rsn]]
		    (message "Error: %s" rsn))
		   (['rex ['ok regions]]
		    (message "Searching finished.")
		    ))))
	  (erl-spawn
	    (erl-send-rpc wrangler-erl-node 'wrangler 'try_inspector (list 'wrangler_code_inspector 'not_flush_unknown_messages_in_dirs(list 
                       wrangler-search-paths tab-width)))
	    (erl-receive (buffer)
		((['rex ['badrpc rsn]]
		  (message "Error: %S" rsn))
		 (['rex ['error rsn]]
		  (message "Error: %s" rsn))
		 (['rex ['ok regions]]
		  (message "Searching finished.")
		  ))))
	  )
      (message "Searching aborted."))))
 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The following functions are for monitoring refactoring activities purpose, and ;;
;; will be moved to a separate module.                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun write-to-refac-logfile(dir-to-monitor logmsg)
  "write log infomation to the log file and check in to the repository"
  (let* ((refac-monitor-path (concat (file-name-as-directory refac-monitor-repository-path)
				     (file-name-nondirectory dir-to-monitor)))
	 (logfile (concat (file-name-as-directory refac-monitor-path) "refac_cmd_log"))
	 (exist (file-regular-p logfile)))
    (write-region (concat "\n" logmsg) nil logfile 'true)
    (setq olddir default-directory)
    (cd refac-monitor-repository-path)
    (setq logfile1 (file-relative-name logfile refac-monitor-repository-path))
    (if (eq exist nil)
	(vc-call-backend (backend-used) 'register (list logfile1) nil "new file")
      nil)
    (vc-call-backend (backend-used) 'checkin (list logfile1) nil "new command")
    (cd olddir)))


(defun backend-used()
  "Get the version control system used by the monitor"
     (vc-responsible-backend (concat (file-name-as-directory  refac-monitor-repository-path) ".")))

(defun update-repository(files logmsg)
  "commit refactoring files to the monitoring repository if they should be monitored"
  (if (or (equal files nil) (equal dirs-to-monitor nil))
      nil
    (let ((dir (is-a-monitored-file (elt (car files) 0))))
      (if (equal nil dir)
	  (message-box "Reminder: the file under refactoring is not being monitored by Wrangler's refactoring monitor.")
	(setq olddir default-directory)
	(cd refac-monitor-repository-path)
	(update-repository-1 dir (concat wrangler-version logmsg))
	(cd olddir)
	))))
	   

(defun update-repository-1 (dir-to-monitor logmsg)
  "copy changed files to the working copy of refactor monitor"
   (require 'dired-aux)
  (let* ((refac-monitor-path (concat (file-name-as-directory refac-monitor-repository-path)
				     (file-name-nondirectory dir-to-monitor)))
	 (logfile (concat (file-name-as-directory refac-monitor-path) "refac_cmd_log")))
    (copy-dir-recursive  dir-to-monitor refac-monitor-path 'true nil nil 'always)
    (write-region (concat "\n" logmsg) nil logfile 'true)
    (register-and-checkin-new-files refac-monitor-path logmsg)
    ))
    
(defun copy-dir-recursive (from to ok-flag &optional preserve-time top recursive)
  (let ((attrs (file-attributes from))
	dirfailed)
    (if (and recursive
	     (eq t (car attrs))
	     (or (eq recursive 'always)
		 (yes-or-no-p (format "Recursive copies of %s? " from))))
	;; This is a directory
	(if (or (member (file-name-nondirectory from) vc-directory-exclusion-list)
	    (and (string-equal (substring (file-name-nondirectory from) 0 1) ".")
		 (not (or (string-equal (file-name-nondirectory from) ".")
			  (string-equal (file-name-nondirectory from) "..")))))
	    nil
	  (let ((mode (or (file-modes from) #o700))
		(files
		 (condition-case err
		     (directory-files from nil dired-re-no-dot)
		   (file-error
		  (push (dired-make-relative from)
			dired-create-files-failures)
		  (dired-log "Copying error for %s:\n%s\n" from err)
		  (setq dirfailed t)
		  nil))))
	    (if (eq recursive 'top) (setq recursive 'always)) ; Don't ask any more.
	    (unless dirfailed
	      (if (file-exists-p to)
		  (or top (dired-handle-overwrite to))
		(condition-case err
		    ;; We used to call set-file-modes here, but on some
		    ;; Linux kernels, that returns an error on vfat
		    ;; filesystems
		    (let ((default-mode (default-file-modes)))
		      (unwind-protect
			  (progn
			    (set-default-file-modes #o700)
			    (make-directory to))
			(set-default-file-modes default-mode)))
		  (file-error
		   (push (dired-make-relative from)
			 dired-create-files-failures)
		   (setq files nil)
		   (dired-log "Copying error for %s:\n%s\n" from err)))))
	    (dolist (file files)
	      (let ((thisfrom (expand-file-name file from))
		    (thisto (expand-file-name file to)))
		;; Catch errors copying within a directory,
		;; and report them through the dired log mechanism
		;; just as our caller will do for the top level files.
		(condition-case err
		    (copy-dir-recursive
		     thisfrom thisto
		     ok-flag preserve-time nil recursive)
		  (file-error
		   (push (dired-make-relative thisfrom)
			 dired-create-files-failures)
		   (dired-log "Copying error for %s:\n%s\n" thisfrom err)))))
	    (when (file-directory-p to)
	      (set-file-modes to mode))))
      ;; Not a directory.
      (or top (dired-handle-overwrite to))
      (condition-case err
	  (if (stringp (car attrs))
	      ;; It is a symlink
	      (make-symbolic-link (car attrs) to ok-flag)
	    (if (and (or (equal (file-name-extension from) "erl")
			 (equal (file-name-extension from) "hrl"))
		     (not (backup-file-name-p from)))
		(progn
		;;  (message "filetocopy:%s" from)
		  (copy-file from to ok-flag dired-copy-preserve-time)
		  )
	      nil))
	(file-date-error
	 (push (dired-make-relative from)
	       dired-create-files-failures)
	 (dired-log "Can't set date on %s:\n%s\n" from err))))))

     
(defun register-and-checkin-new-files(dir-to-check logmsg)
  "Register and check new files into the version control system."
  (if (and (equal 'unregistered (vc-call-backend (backend-used) 'state dir-to-check))
	   (not (equal (backend-used) 'Git)))
      (progn
	(vc-call-backend (backend-used) 'register (list dir-to-check) nil "new directory")
	(vc-call-backend (backend-used) 'checkin (list dir-to-check) nil "new direcotry"))
    (let ((files (collect-files dir-to-check)))
      (when files 
	(progn
	  (setq files1 (mapcar #'(lambda (f) (file-relative-name f refac-monitor-repository-path)) files))
	  (setq files2 (cons (backend-used) (list files1)))
	  (register nil files2 "new files")
	  (checkin files2 logmsg)
	  ))
      )))

(defun collect-files (dir-to-check)
  "Expands directories in a file list specification.
      Within directories, only files not already under version control are noticed."
  (let ((file-or-dir-list (list dir-to-check)))
    (let ((flattened '()))
      (dolist (node file-or-dir-list)
	(when (file-directory-p node)
	  (file-tree-walk
	   (expand-file-name node) 
	   (lambda (f) 
	     (if (or (equal (file-name-extension f) "erl") (equal (file-name-extension f) "hrl"))
		 (push f flattened)
	       flattened))
	   nil))
	(unless (file-directory-p node) (push node flattened)))
      flattened)))


(defun file-tree-walk (file func args)
  (if (not (file-directory-p file))
      (apply func file args)
    (let ((dir (file-name-as-directory file)))
      (mapcar
       (lambda (f) (or
		    (string-equal f ".")
		    (string-equal f "..")
		    (member f vc-directory-exclusion-list)
		    (let ((dirf (expand-file-name f dir)))
		      (file-tree-walk dirf func args))))
       (directory-files dir)))))

(defun checkin (vc-fileset comment)
  (let* ((backend (car vc-fileset))
	 (files (nth 1 vc-fileset))
	 (ready-for-commit files))
    (dolist (file files)
       (unless (file-writable-p file)
     	(set-file-modes file (logior (file-modes file) 128))
     	(let ((visited (get-file-buffer file)))
     	  (when visited
     	    (with-current-buffer visited
    	    (toggle-read-only -1))))))
    (if (not ready-for-commit)
	nil
      (if (not (equal backend 'Git))
	  (vc-call-backend backend 'checkin ready-for-commit nil comment)
	(progn
	  (vc-git-command nil 'async ready-for-commit "commit" "-m" comment "--only" "--"))))
      ))

(defun register (&optional set-revision vc-fileset comment)
  (let* ((fileset-arg  vc-fileset)
	  (backend (car fileset-arg))
	  (files (nth 1 fileset-arg)))
     (vc-call-backend backend 'register files nil comment)
     (dolist (file files)
       (vc-file-setprop file 'vc-backend backend)
       )))
   
