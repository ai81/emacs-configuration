;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;dvc - distributed VCS                
;;
;; C-x V s - changeset
;; C-x V = - show diff
;; C-x V d - diff in plain text in buffer
;; C-x V e - ediff
;; C-x V L/l - show log/changelog (prefix - how much)
;; C-x V f a - add new files
;; C-x V f X - remove files
;; C-x V f M - rename files
;; C-x V I - creation of new repository
;; C-x V m - diff from remote repository
;; C-x V M - apply changes from remote repository
;; C-x V F - download changes from remote repository
;; C-x V u - apply downloaded changes to current repository
;; C-x V P - make push
;; C-x V p - send changes by email
;; C-x V b - bookmarks with addresses of remote repository
;; C-x V C - clone
;; C-x V o c - create branch
;; C-x V o s - select branch
;; C-x V o l - branches list
;; C-x V C-h - all global keys list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(load-file  "~/.emacs.d/src/dvc/++build/dvc-load.el")
(require 'dvc-autoloads)
;; (custom-set-variables
;;  '(dvc-prompt-active-dvc nil)
;;  '(dvc-select-priority '(xgit xhg bzr baz))
;;  '(dvc-tips-enabled nil)
;;  )

;; mo-git-blame
(add-to-list 'load-path "~/.emacs.d/src/mo-git-blame")
(autoload 'mo-git-blame-file "mo-git-blame" nil t)
(autoload 'mo-git-blame-current "mo-git-blame" nil t)

;; gitsum
(add-to-list 'load-path "~/.emacs.d/src/gitsum")
(require 'gitsum)

;; egit
(add-to-list 'load-path "~/.emacs.d/src/egit")
(autoload 'egit "egit" "Emacs git history" t)
(autoload 'egit-file "egit" "Emacs git history file" t)
(autoload 'egit-dir "egit" "Emacs git history directory" t)

