(require 'projects)
(setq project-buffer-name-directory-limit 40)
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

                           ("mobileapp-basesearch" . "/home/antonio/svn/arcadia/mobileapp-version/arcadia/")
                           ("arcadia-trunk" . "/home/antonio/svn/arcadia/trunk/arcadia/")
                           ("rabota-arcadia" . "/home/antonio/svn/arcadia/rabota/arcadia/")
                           ("review" . "/home/antonio/review/")
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
                            "*.a" "drweb-nss"  "drweb-nss-qcontrol"
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

(project-def "mobileapp-basesearch"
      '((basedir          "/home/antonio/svn/arcadia/mobileapp-version/arcadia")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "Entries" "Makefile" "basesearch"))
        (tags-file        "/home/antonio/svn/arcadia/mobileapp-version/arcadia/TAGS")
        (file-list-cache  "/home/antonio/svn/arcadia/mobileapp-version/arcadia/files")
        (open-files-cache "/home/antonio/svn/arcadia/mobileapp-version/arcadia/open-files")
        (vcs              svn)
        (compile-cmd      "cd /home/antonio/svn/arcadia/mobileapp-version/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "arcadia-trunk"
      '((basedir          "/home/antonio/svn/arcadia/trunk/arcadia")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "Entries" "Makefile"))
        (tags-file        "/home/antonio/svn/arcadia/trunk/arcadia/TAGS")
        (file-list-cache  "/home/antonio/svn/arcadia/trunk/arcadia/files")
        (open-files-cache "/home/antonio/svn/arcadia/trunk/arcadia/open-files")
        (vcs              svn)
        (compile-cmd      "cd /home/antonio/svn/arcadia/trunk/debug; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "rabota-arcadia"
             '((basedir          "/home/antonio/svn/arcadia/rabota/arcadia")
               (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
               (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                                  "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                                  "*.a" "Entries" "Makefile" "basesearch"))
        (tags-file        "/home/antonio/svn/arcadia/rabota/TAGS")
        (file-list-cache  "/home/antonio/svn/arcadia/rabota/files")
        (open-files-cache "/home/antonio/svn/arcadia/rabota/open-files")
        (vcs              svn)
        (compile-cmd      "cd /home/antonio/svn/arcadia/rabota/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "review"
             '((basedir          "/home/antonio/review")
               (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
               (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                                  "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                                  "*.a" "Entries" "Makefile"))
        (tags-file        "/home/antonio/review/TAGS")
        (file-list-cache  "/home/antonio/review/files")
        (open-files-cache "/home/antonio/review/open-files")
        (vcs              git)
        (compile-cmd      "cd /home/antonio/review/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

