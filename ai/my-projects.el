(require 'projects)
(setq buffer-name-directory-limit 40)
(setq project-root-alist '(
                           ("icapd" . "~/icapd/drweb-icapd")
                           ("icapd-4.44" . "~/icapd/icapd-4-44-branch")
                           ("icapd-5.0" . "~/icapd/icapd-5_0-branch")
                           ("maild-5.0" . "~/DevelMail/maild-5_0-branch")
                           ("maild-rel" . "~/DevelMail/release-drweb-maild/")
                           ("maild" . "~/DevelMail/drweb-maild/")
                           ("nss" . "~/nss/drweb-nss")
                           ("gui" . "~/gui/DrWebGUI_Unix/")
                           ("gui-new" . "~/gui/DrWebGUI_Unix_new/")
))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;mk-project specification             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'mk-project)
(global-set-key (kbd "C-x p c") 'project-compile)
(global-set-key (kbd "C-x p l") 'project-load)
(global-set-key (kbd "C-x p a") 'project-ack)
(global-set-key (kbd "C-x p g") 'project-grep)
(global-set-key (kbd "C-x p o") 'project-multi-occur)
(global-set-key (kbd "C-x p u") 'project-unload)
(global-set-key (kbd "C-x p f") 'project-find-file-ido) ; or project-find-file
(global-set-key (kbd "C-x p i") 'project-index)
(global-set-key (kbd "C-x p s") 'project-status)
(global-set-key (kbd "C-x p h") 'project-home)
(global-set-key (kbd "C-x p d") 'project-dired)
(global-set-key (kbd "C-x p t") 'project-tags)

(project-def "maild"
      '((basedir          "/home/ai/DevelMail/drweb-maild/")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "ip_set_check" "*.a" "drweb-maild" "drweb-receiver"
                            "drweb-sender" "drweb-notifier" "drweb-qcontrol"
                            "Entries" "Makefile" "Makefile.in" "config.status"
                            "configure"))
        (tags-file        "/home/ai/DevelMail/drweb-maild/build/TAGS")
        (file-list-cache  "/home/ai/DevelMail/drweb-maild/build/files")
        (open-files-cache "/home/ai/DevelMail/drweb-maild/build/open-files")
        (vcs              git)
        (compile-cmd      "make -j8 -k")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "nss"
      '((basedir          "/home/ai/nss/drweb-nss/")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "drweb-nss"
                            "Entries" "Makefile" "Makefile.in" "config.status"
                            "configure"))
        (tags-file        "/home/ai/nss/drweb-nss/TAGS")
        (file-list-cache  "/home/ai/nss/drweb-nss/files")
        (open-files-cache "/home/ai/nss/drweb-nss/open-files")
        (vcs              git)
        (compile-cmd      "make -j8 -k")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

