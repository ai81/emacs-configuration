(require 'projects)
(setq project-buffer-name-directory-limit 40)
(setq project-root-alist '(
                           ("icapd" . "~/icapd/drweb-icapd")
                           ("icapd-4.44" . "~/icapd/icapd-4-44-branch")
                           ("icapd-5.0" . "~/icapd/icapd-5_0-branch")
                           ("maild-5.0" . "~/DevelMail/maild-5_0-branch")
                           ("maild-rel" . "~/DevelMail/release-drweb-maild/")
                           ("maild" . "~/DevelMail/drweb-maild/")
                           ("nss" . "~/private/drweb/nss/drweb-nss")
                           ("gui" . "~/gui/DrWebGUI_Unix/")
                           ("gui-new" . "~/gui/DrWebGUI_Unix_new/")

                           ("appsearch" . "~/svn/arcadia/mobileapp-version/arcadia/")
                           ("arcadia-trunk" . "~/svn/arcadia/trunk/arcadia/")
                           ("rabota-arcadia" . "~/svn/arcadia/rabota/arcadia/")
                           ("review" . "~/review/")
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
      '((basedir          "~/private/drweb/nss/drweb-nss/")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "drweb-nss"  "drweb-nss-qcontrol"
                            "Entries" "Makefile" "Makefile.in" "config.status"
                            "configure"))
        (tags-file        "~/private/drweb/nss/drweb-nss/TAGS")
        (file-list-cache  "~/private/drweb/nss/drweb-nss/files")
        (open-files-cache "~/private/drweb/nss/drweb-nss/open-files")
        (vcs              git)
        (compile-cmd      "make -j8 -k")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "mobileapps"
      '((basedir          "~/svn/arcadia/mobileapp-version/arcadia")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "Entries" "Makefile" "basesearch"))
        (tags-file        "~/svn/arcadia/mobileapp-version/arcadia/TAGS")
        (file-list-cache  "~/svn/arcadia/mobileapp-version/arcadia/files")
        (open-files-cache "~/svn/arcadia/mobileapp-version/arcadia/open-files")
        (vcs              svn)
        (compile-cmd      "cd ~/svn/arcadia/mobileapp-version/release; make -j8 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "arcadia-trunk"
      '((basedir          "~/svn/arcadia/trunk/arcadia")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "Entries" "Makefile"))
        (tags-file        "~/svn/arcadia/trunk/arcadia/TAGS")
        (file-list-cache  "~/svn/arcadia/trunk/arcadia/files")
        (open-files-cache "~/svn/arcadia/trunk/arcadia/open-files")
        (vcs              svn)
        (compile-cmd      "cd ~/svn/arcadia/trunk/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "rabota-arcadia"
             '((basedir          "~/svn/arcadia/rabota/arcadia")
               (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
               (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                                  "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                                  "*.a" "Entries" "Makefile" "basesearch"))
        (tags-file        "~/svn/arcadia/rabota/TAGS")
        (file-list-cache  "~/svn/arcadia/rabota/files")
        (open-files-cache "~/svn/arcadia/rabota/open-files")
        (vcs              svn)
        (compile-cmd      "cd ~/svn/arcadia/rabota/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))

(project-def "review"
             '((basedir          "~/review")
               (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
               (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                                  "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                                  "*.a" "Entries" "Makefile"))
        (tags-file        "~/review/TAGS")
        (file-list-cache  "~/review/files")
        (open-files-cache "~/review/open-files")
        (vcs              git)
        (compile-cmd      "cd ~/review/release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))


(project-def "webapps"
      '((basedir          "~/svn/arcadia/mobileapp-version/arcadia")
        (src-patterns     ("*.H" "*.C" "*.h" "*.c" "*.cxx" "*.cpp" "*.hpp" "*.hh"))
        (ignore-patterns  ("*cvs*" "*.png" "*.map" "*.md5" "*.html" "*~" 
                            "*.Po" "*.Tpo" "*.supp" "ChangeLog" "*.o" "files"
                            "*.a" "Entries" "Makefile" "basesearch"))
        (tags-file        "~/svn/arcadia/mobileapp-version/arcadia/web-TAGS")
        (file-list-cache  "~/svn/arcadia/mobileapp-version/arcadia/web-files")
        (open-files-cache "~/svn/arcadia/mobileapp-version/arcadia/web-open-files")
        (vcs              svn)
        (compile-cmd      "cd ~/svn/arcadia/mobileapp-version/web-release; make -j4 -k; cd -")
        (ack-args         "--flush")
        (startup-hook     nil)
        (shutdown-hook    nil)))
