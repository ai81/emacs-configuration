;;dired работает в одном буфере
(add-to-list 'load-path "~/.emacs.d/src/")

(require 'dired-single)
(defun my-dired-init ()
  "Bunch of stuff to run for dired, either immediately or when it's
         loaded."
  ;; <add other stuff here>
  (define-key dired-mode-map [return] 'joc-dired-single-buffer)
  (define-key dired-mode-map [mouse-1] 'joc-dired-single-buffer-mouse)
  (define-key dired-mode-map "^"
    (function
     (lambda nil (interactive) (joc-dired-single-buffer "..")))))

;; if dired's already loaded, then the keymap will be bound
(if (boundp 'dired-mode-map)
    ;; we're good to go; just add our bindings
    (my-dired-init)
  ;; it's not loaded yet, so add our bindings to the load-hook
  (add-hook 'dired-load-hook 'my-dired-init))
(global-set-key [(f5)] 'joc-dired-magic-buffer)
(global-set-key [(control f5)] (function
                                (lambda nil (interactive)
                                  (joc-dired-magic-buffer default-directory))))
(global-set-key [(shift f5)] (function
                              (lambda nil (interactive)
                                (message "Current directory is: %s" default-directory))))
(global-set-key [(meta f5)] 'joc-dired-toggle-buffer-name)

;;расширенная сортировка в dired
;;(press s then s, x, t or n to sort by Size, eXtension, Time or Name)
(require 'dired-sort-map)

