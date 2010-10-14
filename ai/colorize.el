;;подсветка табуляции, пробелы в конце строки и тп

;; can't use whitespace mode - VERY slow
;; (require 'whitespace)
;; (setq whitespace-line-column 78)
;; (setq whitespace-style '(tabs tab-mark))
;; (add-hook 'c-mode-common-hook 'whitespace-mode)
;; (add-hook 'text-mode-hook 'whitespace-mode)
;; (add-hook 'makefile-mode-hook 'whitespace-mode)
;; (setq whitespace-action '(abort-on-bogus))

(require 'show-wspace)
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(show-ws-tab ((t (:background "gray")))))
;; (add-hook 'font-lock-mode-hook 'show-ws-highlight-tabs)
;; (add-hook 'font-lock-mode-hook 'show-ws-highlight-hard-spaces)
(add-hook 'c-mode-common-hook 'show-ws-highlight-tabs)
(add-hook 'text-mode-hook 'show-ws-highlight-tabs)
(add-hook 'makefile-mode-hook 'show-ws-highlight-tabs)
(add-hook 'c-mode-common-hook 'show-ws-highlight-hard-spaces)
(add-hook 'text-mode-hook 'show-ws-highlight-hard-spaces)
(add-hook 'makefile-mode-hook 'show-ws-highlight-hard-spaces)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; add lineker mode - highlight long lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'lineker)
(add-hook 'c-mode-common-hook 'lineker-mode)
;;(add-hook 'text-mode-hook 'lineker-mode)
