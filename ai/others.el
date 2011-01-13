;; use russian spell check by default
(ispell-change-dictionary "russian" 1)

;; time in 24-hour format
(setq display-time-24hr-format t)

(setq calendar-week-start-day 1);;календарь начинаем с понедельника
(setq calendar-latitude 59.57);;устанавливаем ширину и долготу Санкт-Петербурга
(setq calendar-longitude 30.19)
(setq european-calendar-style t);;календарь выводим в европейском стиле
(setq make-backup-files nil);;запретить создание backup-файлов
(setq compilation-scroll-output t);;устанавливаем возможность прокрутки
                                  ;;окна компиляции
(setq compilation-window-height 8);;устанавливаем количество строк в окне
                                   ;;компиляции
(setq max-lisp-eval-depth 10000);;устанавливаем максимальный уровень рекурсии
(setq max-specpdl-size 6000);;максимальное ограничение на переменные ЛИСПА
(mouse-avoidance-mode 'animate) ;;убираем курсор с пути

;;added in Emacs 22.0/1
(setq isearch-allow-scroll 't);;во время инкрементного поиска
                              ;;допускаем к примеру C-l (прокрутку)
(setq history-delete-duplicates 't);;удаляем дубликаты в history
(setq next-error-highlight (quote fringe-arrow));;выделяем ошибочные строки через 
                                                ;;стрелочку во fringer 
(setq next-error-highlight-no-select (quote t));;выделяет ошибочную строку постоянным 
                                               ;;выделением
(size-indication-mode);;включаем показ размер файла

(setq initial-scratch-message nil);;сбрасываем текст в scratch буффере

(setq fill-column 78);;ширина текста по-умолчанию

(require 'grep)
(add-to-list 'grep-files-aliases '("a" . "*[CcHhxp]"));;синоним для ускорения rgrep
(global-set-key [f2] 'rgrep)

(setq tramp-default-method "scp");;так как в локальном режиме(ssh) 
;;неверно перекодируется русский
;;текст

(setq mouse-wheel-progressive-speed nil);;убираем ускорение прокрутки при ускорении 
                                        ;;кручения колесика

(setq default-input-method "russian-computer")

;;умный режим автозаполнения
(require 'filladapt)
(add-hook 'text-mode-hook 'turn-on-filladapt-mode)

;;tab-дополнение в shell-mode
(require 'shell-command)
(shell-command-completion-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; WinnerMode
;; ‘C-c left’ and ‘C-c right’
;; http://www.emacswiki.org/emacs-en/WinnerMode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(when (fboundp 'winner-mode)
      (winner-mode 1))
(windmove-default-keybindings 'meta) ;; Alt+direction

;; ido
(ido-mode 'all)
(setq ido-enable-regexp nil)
(setq ido-enable-flex-matching t) ;; enable fuzzy matching



;; rfc support
(setq auto-mode-alist
      (cons '("/rfc[0-9]+\\.txt\\(\\.gz\\)?\\'" . rfcview-mode)
            auto-mode-alist))
(autoload 'get-rfc-view-rfc "get-rfc" "Get and view an RFC" t nil)
(autoload 'get-rfc-view-rfc-at-point "get-rfc" "View the RFC at point" t nil)
(autoload 'get-rfc-grep-rfc-index "get-rfc" "Grep rfc-index.txt" t nil)
(setq get-rfc-local-rfc-directory "~/")
(setq get-rfc-save-new-rfcs-locally t)
