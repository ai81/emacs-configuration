(add-to-list 'load-path "~/.emacs.d/src/")

;;расширения строки режима
(require 'modeline-posn)
(column-number-mode 1)
(size-indication-mode 0) ; Turn off Size Indication mode.
(setq modelinepos-column-limit 79)

;;закрытие давно не используемых буферов
(require 'tempbuf)
(add-hook 'dired-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'custom-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'w3-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'Man-mode-hook 'turn-on-tempbuf-mode)
(add-hook 'view-mode-hook 'turn-on-tempbuf-mode)

;;подсветка табуляции, пробелы в конце строки и тп
(require 'show-wspace)
(add-hook 'font-lock-mode-hook 'show-ws-highlight-tabs)
(add-hook 'font-lock-mode-hook 'show-ws-highlight-hard-spaces)
;;(add-hook 'font-lock-mode-hook 'show-ws-highlight-trailing-whitespace)

;;настройка либы query
(require 'query)
(setq confirm-level 'single)
(setq allow-confirm-defaults t)
(fset 'yes-or-no-p 'y-or-n-p);;воспринимать <RET> или y как yes и n

;;возможность редактирования прямо в grep буфере
;; C-c C-e : apply the highlighting changes to file.
;; C-c C-u : abort
;; C-c C-r : Remove the highlight in the region
(require 'grep-edit)

;;простая подсветка highlight-*
(require 'highlight)

;; подключаем одноименную функцию для показа ascii-таблицы
(require 'ascii-table)
