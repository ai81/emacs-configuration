;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; add GCCSense support                ;; 
;; http://cx4a.org/software/gccsense/manual.html
;; http://cx4a.org/software/gccsense/                                    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'gccsense)

(add-hook 'c-mode-common-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c") 'ac-complete-gccsense)))

;; (add-hook 'c-mode-common-hook
;;           (lambda ()
;;             (flymake-mode)
;;             (gccsense-flymake-setup)))

