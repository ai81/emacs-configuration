;; set up C-w for remove previous word
(defun backward-kill-word-or-kill-region (arg)
  (interactive "p")
  (if (region-active-p)
      (kill-region (region-beginning) 
                   (region-end))
    (backward-kill-word arg)))

(global-set-key (kbd "C-w") 'backward-kill-word-or-kill-region)

(define-key minibuffer-local-map (kbd "C-w") 'backward-kill-word-or-kill-region)

(add-hook 'ido-setup-hook 
          (lambda ()
            (define-key ido-completion-map (kbd "C-w") 'ido-delete-backward-word-updir)))

;; for speed up Alt-x command
(global-set-key "\C-c\C-m" 'execute-extended-command)

;; remove annoying emacs close
(global-set-key "\C-x\C-c" (lambda () (interactive)(message "for exit use save-buffers-kill-emacs")))

;; fast move between buffers
(global-set-key [(shift control right)] 'next-buffer)
(global-set-key [(shift control left)] 'previous-buffer)

(global-set-key (kbd "C-q") ' undo)
(global-set-key (kbd "C-z") 'quoted-insert)

(global-set-key [f11] '(lambda ()  (interactive) (revert-buffer-with-coding-system 'koi8-r)))
(global-set-key [shift f11] '(lambda ()  (interactive) (revert-buffer-with-coding-system 'utf8)))



(defun my-check-buffer (lang)
  (ispell-change-dictionary lang)
  (setq flyspell-generic-check-word-predicate 'flyspell-generic-progmode-verify)
  (flyspell-buffer)
  )

;; check whole buffer with program for errors in English text
;; (comments and strings)
(global-set-key [f8] '(lambda () (interactive)(my-check-buffer "american")))

;; check whole buffer with program for errors in Russian text
;; (comments and strings)
(global-set-key [shift f8] '(lambda () (interactive)(my-check-buffer "russian")))
