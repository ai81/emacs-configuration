(setq maild-base-dir "/home/ai/DevelMail/drweb-maild")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;specific maild mode                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(setq maild-templates-mode-file 
      (concat maild-base-dir "/Template/maild-templates-mode.el"))
(if (file-readable-p maild-templates-mode-file)
    (load-file maild-templates-mode-file))

