;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;add auto-comlite-mode                ;;
;; http://cx4a.org/software/auto-complete/manual.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(add-to-list 'load-path "~/.emacs.d/src/auto-complete")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/src/auto-complete/ac-dict")
(ac-config-default)
(ac-flyspell-workaround)
(setq ac-delay 0.5)
(setq ac-auto-show-menu 0.8)
(setq ac-auto-start 2)
(ac-set-trigger-key "TAB")
(setq ac-use-menu-map t)
;; Default settings
(define-key ac-menu-map "\C-n" 'ac-next)
(define-key ac-menu-map "\C-p" 'ac-previous)