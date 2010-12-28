 ;; for C-c C-e command (macroprocessing)
;; (setq c-macro-cppflags (concat "-DHAVE_CONFIG_H -I. -I/usr/local/include -I" 
;;                                 stl-base-dir ) )


(defun upward-find-file (filename &optional startdir)
  "Move up directories until we find a certain filename. If we
  manage to find it, return the containing directory. Else if we
  get to the toplevel directory and still can't find it, return
  nil. Start at startdir or . if startdir not given"

  (let ((dirname (expand-file-name
		  (if startdir startdir ".")))
	(found nil) ; found is set as a flag to leave loop if we find it
	(top nil))  ; top is set when we get
		    ; to / so that we only check it once

    ; While we've neither been at the top last time nor have we found
    ; the file.
    (while (not (or found top))
      ; If we're at / set top flag.
      (if (string= (expand-file-name dirname) "/")
	  (setq top t))
      
      ; Check for the file
      (if (file-exists-p (expand-file-name filename dirname))
	  (setq found t)
	; If not, move up a directory
	(setq dirname (expand-file-name ".." dirname))))
    ; return statement
    (if found dirname nil)))


;; Helper for compilation. Close the compilation window if
;; there was no error at all.
(setq compilation-finish-functions 'compile-autoclose)
(defun compile-autoclose (buffer string)
  (cond ((and 
          (string-match "finished" string) 
          (not (string-match "*grep*" (buffer-name (get-buffer buffer)))))
         (bury-buffer "*compilation*")
         (winner-undo)
         (message "Build successful."))
        (t                                                                    
         (message "Compilation exited abnormally: %s" string))))

;;функция сохраняет содержимое всех буферов
;;и затем вызывает make из католога где находится текущий файл
(defun my-compile-file ()
  "Save all files and compile"
    (interactive)
    (save-some-buffers 1)
    (let ((default-directory (or (upward-find-file "Makefile") ".")))
      (compile (format "cd %s && make -k -j8" default-directory))
      )
  )

;; support for compile tests
(defun my-compile-tests-file ()
  "Save all files and compile"
    (interactive)
    (save-some-buffers 1)
    (let ((default-directory (or (upward-find-file "Makefile") ".")))
      (compile (format "cd %s && make -k -j8 check" default-directory))
      )
  )


(defun my-ppp-comment-region (top bottom)
  ""
  (interactive "r")
  (setq macro [home ?\M-m ?\C-z ?/ ?\C-z ?/ ? ])
;;  (apply-macro-to-region-lines top bottom macro
  (save-excursion
    (let ((end-marker (copy-marker bottom))
          next-line-marker)
      (goto-char top)
      (if (not (bolp))
          (forward-line 1))
      (setq next-line-marker (point-marker))
      (while (< next-line-marker end-marker)
        (goto-char next-line-marker)
        (save-excursion
          (forward-line 1)
          (set-marker next-line-marker (point)))
        (unless (looking-at "[ \t]*$")
            (save-excursion
              (let ((mark-active nil))
                (execute-kbd-macro (or macro last-kbd-macro)))))
        );;while
      (set-marker end-marker nil)
      (set-marker next-line-marker nil))))

;;стиль выравнивания по умолчанию
(setq c-default-style "gnu")

(defun my-c-mode-common-hook ()
  ;; включить режимы auto-newline и hungry-delete
  (c-toggle-auto-hungry-state 1)
  (flyspell-prog-mode);;включаем проверку правописания в комментариях и строках 
  (ispell-change-dictionary "american")
  ;;<RET> работает как C-j  
  (define-key c-mode-base-map "\C-m" 'c-context-line-break)
  ;;добавлеям комментарии для Проектирования с Помощью Псевдокода
  (define-key c-mode-base-map (kbd "C-M-;") 'my-ppp-comment-region)
  (setq c-basic-offset 4)               ; делаем нужный отступ
  (setq tab-width 4)                    ; ширина tab 
  (setq fill-column 78)
  (c-setup-filladapt)                   ;включаем выравнивание
  (filladapt-mode 1)
  (setq comment-style 'indent)
  (subword-mode 1);включаем распознование отдельных слов в идентификаторах вида 'GetParam' (c-subword-mode on old 23.1 and older)
  ;;устанавлиавет отступы так как нам нравиться 
  (setq c-hanging-braces-alist
        '((brace-list-open)
          (brace-entry-open)
          (statement-cont)
          (substatement-open after)
          (block-close . c-snug-do-while)
          (extern-lang-open after)
          (namespace-open after)
          (module-open after)
          (composition-open after)
          (inexpr-class-open after)
          (inexpr-class-close before)
          ;;это от меня
          (inline-close after)
          (inline-open)
          (defun-open after)
          )
        )
  (setq c-cleanup-list '(scope-operator 
                         brace-else-brace 
                         brace-elseif-brace 
                         brace-catch-brace
;;                       empty-defun-braces
                         defun-close-semi
                         list-close-comma
;;                       one-liner-defun
                         comment-close-slash
                         ));;настраиваем атоматическое удаление лишних пробелов
  
  (setq c-offsets-alist 
        (append '((arglist-intro . +)
                  (arglist-cont . 0)
                  (arglist-cont-nonempty . +)
                  (arglist-close . +)
                  (member-init-intro . +)
                  (member-init-cont . 0)
                  (innamespace . 0)
                  ) c-offsets-alist)
        );;настройка отступов

  (setq c-hanging-semi&comma-criteria
        (append '(
                  ;;не переводим строка после ; если дальше не пустая строка
                  c-semi&comma-no-newlines-before-nonblanks
                  ;;не переводим строка после ; в inline функциях
                  c-semi&comma-no-newlines-for-oneline-inliners
                  ) c-hanging-semi&comma-criteria)
        );;настройка создания новых строк после  , и ;
  )

(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(setq-default font-lock-maximum-decoration
           '((c-mode . 3) (c++-mode . 3)));;установить уровень подсветки
(setq auto-mode-alist
      (append '(("\\.h\\'" . c++-mode)
                ("\\.ipp\\'" . c++-mode) ;; for asio implimitation files
                ) auto-mode-alist));;файлы с расширением .h подключаем в
                                   ;;режиме С++
;;устанавливаем нашу функцию
(global-set-key  [f7] 'my-compile-file)
(global-set-key  [(shift f7)] 'my-compile-tests-file)

(global-set-key [f4] 'my-insert-function-description)
(global-set-key [(shift f4)] 'my-insert-copyright)
(defun my-insert-function-description ()
  (interactive)
  (insert "///////////////////////////////////////////////////////////////////////\n"
          "///\n"
          "///////////////////////////////////////////////////////////////////////\n"
  )
)

(defun my-insert-copyright ()
  (interactive)
  (insert "/*---------------------------------------------------------------------------\n"
          " * Copyright 2010 Igor Daniloff.\n"
          " * \n"
          " * Following source code is the property of Doctor Web, Ltd.\n"
          " * Use is subject to license terms.\n"
          " * The reproduction in any form without written permission of\n"
          " * Doctor Web, Ltd. and proper attribution is strongly prohibited.\n"
          " ----------------------------------------------------------------------------*/\n"
  )
)

;;поддержка расширенного парсера в C/C++
(require 'ctypes)
