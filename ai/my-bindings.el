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

(global-set-key (kbd "M-SPC") 'toggle-input-method)