;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;add auto-comlite-mode                ;;
;; http://cx4a.org/software/auto-complete/manual.html
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(add-to-list 'load-path "~/.emacs.d/src/auto-complete")
(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories "~/.emacs.d/src/auto-complete/ac-dict")
(ac-config-default)
(ac-flyspell-workaround)
