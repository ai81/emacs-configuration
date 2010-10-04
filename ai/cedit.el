;; Load CEDET
;; See cedet/common/cedet.info for configuration details.
(load-file "~/.emacs.d/src/cedet/common/cedet.el")
;;(semantic-mode);;for emacs 23.2 and above

;; Enable EDE (Project Management) features
(global-ede-mode 1)

;; Enabling Semantic (code-parsing, smart completion) features
;; Select one of the following:

;; * This enables the database and idle reparse engines
;;(semantic-load-enable-minimum-features)

;; * This enables some tools useful for coding, such as summary mode
;;   imenu support, and the semantic navigator
;;(semantic-load-enable-code-helpers)

;; * This enables even more coding tools such as intellisense mode
;;   decoration mode, and stickyfunc mode (plus regular code helpers)
(semantic-load-enable-gaudy-code-helpers)
;; add for emacs 23.2
;; (setq semantic-default-submodes 
;; '(global-semantic-idle-scheduler-mode 
;;   global-semanticdb-minor-mode
;;   global-semantic-decoration-mode
;;   global-semantic-highlight-func-mode
;;   global-semantic-stickyfunc-mode
;;   global-semantic-mru-bookmark-mode))

;; complitition stuff
(require 'semantic-ia)

;; gcc setup
(require 'semantic-gcc)

;; Enable SRecode (Template management) minor-mode.
(global-srecode-minor-mode 1)

(semantic-add-system-include "/usr/local/include" 'c++-mode)
(setq stl-base-dir "/usr/include/c++/4.4")
(semantic-add-system-include stl-base-dir 'c++-mode)

;; ;;and ecb
;; (add-to-list 'load-path "/home/ai/work/emacs-libs/ecb-2.40")
;; (require 'ecb)
;; ;;(require 'ecb-autoloads)

(setq maild-base-dir "/home/ai/DevelMail/drweb-maild")

( ede-cpp-root-project 
  "maild"
  :name "MailD Project (head)"
  :version "6.0"
  :file (concat maild-base-dir "/configure.in" )
  :include-path '("/"
                  "/shared"
                  "/Engine/plugins"
                  "/Filters/shared"
                  "/mimepp"
                  )
  :spp-table '(("HAVE_CONFIG_H" . "1")
               )
  )


(setq nss-base-dir "/home/ai/nss/drweb-nss")

( ede-cpp-root-project 
  "nss"
  :name "Dr.Web NSS project (head)"
  :version "6.0"
  :file (concat nss-base-dir "/configure.ac" )
  :include-path '("/"
                  "/maild"
                  "/key"
                  "/src"
                  "/src/maild"
                  "/src/key"
                  )
  :spp-table '(("HAVE_CONFIG_H" . "1")
               )
  )


(add-to-list 'semantic-lex-c-preprocessor-symbol-file (concat maild-base-dir "/mainconfig.h")  (concat nss-base-dir "/mainconfig.h") )

;; configuration for stl
;; (add-to-list 'semantic-lex-c-preprocessor-symbol-file (concat stl-base-dir "/i586-suse-linux/bits/os_defines.h"))
;; (add-to-list 'semantic-lex-c-preprocessor-symbol-file "/usr/include/features.h")
;; (add-to-list 'semantic-lex-c-preprocessor-symbol-file (concat stl-base-dir "/i586-suse-linux/bits/c++config.h"))

(defun semantic-ia-fast-jump-with-save-pos (point)
  "Save pos in tag ring to return to original pos by M-*"
  (interactive "d")
  (ring-insert find-tag-marker-ring (point-marker))
  (semantic-ia-fast-jump point)
 )

;; customisation of modes
(defun my-cedet-hook ()
  (local-set-key [(control return)] 'semantic-ia-complete-symbol-menu)
  (local-set-key "\C-c?" 'ac-complete-semantic);;semantic-ia-complete-symbol)
  ;;
  (local-set-key "\C-c>" 'semantic-complete-analyze-inline)
  (local-set-key "\C-c=" 'semantic-decoration-include-visit)

  (local-set-key "\C-cj" 'semantic-ia-fast-jump-with-save-pos)
  (local-set-key "\C-cq" 'semantic-ia-show-doc)
  (local-set-key "\C-cs" 'semantic-ia-show-summary)
  (local-set-key "\C-cp" 'semantic-analyze-proto-impl-toggle)
  )
(add-hook 'c-mode-common-hook 'my-cedet-hook)
(add-hook 'lisp-mode-hook 'my-cedet-hook)
(add-hook 'emacs-lisp-mode-hook 'my-cedet-hook)

(defun my-c-mode-cedet-hook ()
  ;;(local-set-key "." 'semantic-complete-self-insert)
  ;; (local-set-key ">" 'semantic-complete-self-insert)
  (local-set-key "\C-xt" 'eassist-switch-h-cpp)
  (local-set-key "\C-ce" 'eassist-list-methods)
  (local-set-key "\C-c\C-r" 'semantic-symref)
  )
(add-hook 'c-mode-common-hook 'my-c-mode-cedet-hook)

(global-set-key [f3] 'eassist-switch-h-cpp) ;;обмен C/H файлов

