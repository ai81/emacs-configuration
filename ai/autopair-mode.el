;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; натройка autopair              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'autopair)
(autopair-global-mode 1)
(setq autopair-autowrap t)
(put 'autopair-insert-opening 'delete-selection t)
(put 'autopair-skip-close-maybe 'delete-selection t)
(put 'autopair-insert-or-skip-quote 'delete-selection t)
(put 'autopair-extra-insert-opening 'delete-selection t)
(put 'autopair-extra-skip-close-maybe 'delete-selection t)
(put 'autopair-backspace 'delete-selection 'supersede)
(put 'autopair-newline 'delete-selection t)
;; remove (delete-selection-mode t) to use cua mode insteed. see
;; http://emacs-fu.blogspot.com/2010/06/automatic-pairing-of-brackets-and.html
;; http://emacs-fu.blogspot.com/2010/01/rectangles-and-cua.html
;; http://www.emacswiki.org/emacs/CuaMode
;; 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cua mode                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; only for rectangles
(setq cua-enable-cua-keys nil) 
(cua-mode t)

