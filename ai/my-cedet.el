;;Load CEDET
(load-file "/Applications/Emacs.app/Contents/Resources/lisp/cedet/cedet.elc")
(setq cedet-root-path (file-name-as-directory "~/.emacs.d/cedet/"))
(add-to-list 'load-path (concat cedet-root-path "contrib"))

;; Enable EDE (Project Management) features
(global-ede-mode t)
(ede-enable-generic-projects)

;; select which submodes we want to activate
(add-to-list 'semantic-default-submodes 'global-semantic-mru-bookmark-mode)
(add-to-list 'semantic-default-submodes 'global-semanticdb-minor-mode)
(add-to-list 'semantic-default-submodes 'global-semantic-idle-scheduler-mode)
(add-to-list 'semantic-default-submodes 'global-semantic-stickyfunc-mode)
(add-to-list 'semantic-default-submodes 'global-semantic-highlight-func-mode)
(add-to-list 'semantic-default-submodes 'global-semanticdb-minor-mode)

;; turn on sematic mode
(semantic-mode 1)

;; complitition stuff
(require 'semantic/ia)

;; Enable SRecode (Template management) minor-mode.
;;(global-srecode-minor-mode 1)

(require 'semantic/bovine/gcc)

(semanticdb-enable-gnu-global-databases 'c-mode t)
(semanticdb-enable-gnu-global-databases 'c++-mode t)
 
(setq stl-base-dir "/opt/local/include/gcc44/c++")

(semantic-add-system-include "/usr/local/include" 'c++-mode)
(semantic-add-system-include "/opt/local/include" 'c++-mode)
(semantic-add-system-include stl-base-dir 'c++-mode)

;; load contrib library
(require 'eassist)

;; ;;and ecb
;; (add-to-list 'load-path "/home/ai/work/emacs-libs/ecb-2.40")
;; (require 'ecb)
;; ;;(require 'ecb-autoloads)

(setq maild-base-dir "/home/ai/DevelMail/drweb-maild")
(when (file-accessible-directory-p maild-base-dir)
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
    :spp-files '( "mainconfig.h" )
    )
  )


(setq nss-base-dir "/User/antonio/private/drweb/nss/drweb-nss")
(when (file-accessible-directory-p nss-base-dir)
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
    :spp-files '("mainconfig.h")
    )
  )

(setq ma-base-dir "/Users/antonio/svn/arcadia/mobileapp-version/arcadia")
(when (file-accessible-directory-p ma-base-dir)
  ( ede-cpp-root-project 
    "mobileapp-basesearch"
    :name "mobileapp-basesearch"
    :version "1.0"
    :file (concat ma-base-dir "/dont_notify_success.users" )
    :include-path '("/"
                    )
    :system-include-path '("/"
                    )
    :spp-table '(("HAVE_CONFIG_H" . "1")
                 ("BUILD_FOR_APPS_SEARCH" . "1")
                 )
    )
  )

(setq trunk-base-dir "~/svn/arcadia/trunk/arcadia")
(when (file-accessible-directory-p trunk-base-dir)
  ( ede-cpp-root-project 
    "arcadia-trunk"
    :name "arcadia-trunk"
    :version "1.0"
    :file (concat trunk-base-dir "/dont_notify_success.users" )
    :include-path '("/"
                    )
    :system-include-path '("/"
                    )
    :spp-table '(("HAVE_CONFIG_H" . "1")
                 )
    )
  )

(setq rabota-base-dir "/Users/antonio/svn/arcadia/rabota/arcadia")
(when (file-accessible-directory-p rabota-base-dir)
  ( ede-cpp-root-project 
    "rabota-arc"
    :name "rabota-arc"
    :version "1.0"
    :file (concat rabota-base-dir "/dont_notify_success.users" )
    :include-path '("/"
                    )
    :system-include-path '("/"
                    )
    :spp-table '(("HAVE_CONFIG_H" . "1")
                 ("BUILD_FOR_APPS_SEARCH" . "1")
                 )
    )
  )

(setq review-base-dir "/Users/antonio/review")
(when (file-accessible-directory-p review-base-dir)
  ( ede-cpp-root-project 
    "review-arc"
    :name "review-arc"
    :version "1.0"
    :file (concat review-base-dir "/files" )
    :include-path '("/"
                    "/git/arcadia/arcadia"
                    "/git/otzyv_filter/src"
                    "/git"
                    )
    :system-include-path '("/"
                    )
    :spp-table '(("HAVE_CONFIG_H" . "1")
                 ("BUILD_FOR_APPS_SEARCH" . "1")
                 )
    )
  )

(defun semantic-ia-fast-jump-with-save-pos (point)
  "Save pos in tag ring to return to original pos by M-*"
  (interactive "d")
  (ring-insert find-tag-marker-ring (point-marker))
  (semantic-ia-fast-jump point)
 )

(defun semantic-decoration-include-visit-with-save-pos ()
  "Save pos in tag ring to return to original pos by M-*"
  (interactive)
  (ring-insert find-tag-marker-ring (point-marker))
  (semantic-decoration-include-visit)
 )

;; customisation of modes
(defun my-cedet-hook ()
  (local-set-key [(control return)] 'semantic-ia-complete-symbol-menu)
  (local-set-key "\C-c?" 'ac-complete-semantic);;semantic-ia-complete-symbol)
  ;;
  (local-set-key "\C-c>" 'semantic-complete-analyze-inline)
  (local-set-key "\C-c=" 'semantic-decoration-include-visit-with-save-pos)

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

(global-set-key (kbd "C-c , <up>") 'senator-transpose-tags-up)
(global-set-key (kbd "C-c , <down>") 'senator-transpose-tags-down)
(global-set-key '[(S-mouse-1)] 'semantic-ia-fast-mouse-jump)

;; with ede-locate-locate VERY low speed 
;;(setq ede-locate-setup-options '(ede-locate-locate ede-locate-base))

;; i don't use speedbar...
;;(require 'semantic/sb)
