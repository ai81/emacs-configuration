
(defun yas/org-very-safe-expand ()
  (let ((yas/fallback-behavior 'return-nil)) (yas/expand)))

(add-hook 'org-mode-hook
          (lambda ()
            (local-set-key "\M-\C-n" 'outline-next-visible-heading)
            (local-set-key "\M-\C-p" 'outline-previous-visible-heading)
            (local-set-key "\M-\C-u" 'outline-up-heading)
            ;; table
            (local-set-key "\M-\C-w" 'org-table-copy-region)
            (local-set-key "\M-\C-y" 'org-table-paste-rectangle)
            (local-set-key "\M-\C-l" 'org-table-sort-lines)
            ;; display images
            (local-set-key "\M-I" 'org-toggle-iimage-in-org)
            ;; yasnippet (using the new org-cycle hooks)
            (make-variable-buffer-local 'yas/trigger-key)
            (setq yas/trigger-key [tab])
            (add-to-list 'org-tab-first-hook 'yas/org-very-safe-expand)
            (define-key yas/keymap [tab] 'yas/next-field)
            ))

(setq org-use-speed-commands t)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (sh . t)
   (R . t)
   (perl . t)
   (ruby . t)
   (python . t)
   (js . t)
   (haskell . t)
   (clojure . t)
   (ditaa . t)))

(setq org-src-fontify-natively t)
(setq org-src-tab-acts-natively t)

(org-babel-lob-ingest
 (expand-file-name
  "library-of-babel.org"
  (expand-file-name
   "babel"
   (expand-file-name
    "contrib"
    (expand-file-name
     "org"
     (expand-file-name "src" dotfiles-dir))))))

(unless (boundp 'Info-directory-list)
  (setq Info-directory-list Info-default-directory-list))
(setq Info-directory-list
      (cons (expand-file-name
             "doc"
             (expand-file-name
              "org"
              (expand-file-name "src" dotfiles-dir)))
            Info-directory-list))

(unless (boundp 'org-publish-project-alist)
  (setq org-publish-project-alist nil))
(let ((this-dir (file-name-directory (or load-file-name buffer-file-name))))
  (add-to-list 'org-publish-project-alist
               `("starter-kit-documentation"
                 :base-directory ,this-dir
                 :base-extension "org"
                 :style "<link rel=\"stylesheet\" href=\"emacs.css\" type=\"text/css\"/>"
                 :publishing-directory ,this-dir
                 :index-filename "starter-kit.org"
                 :auto-postamble nil)))
