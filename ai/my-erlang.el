
(setq my-path-to-erlang-emacs "/usr/lib/erlang/lib/tools-2.6.6/emacs/")

(if (file-directory-p my-path-to-erlang-emacs)
    (let (temp)
      (setq load-path (cons my-path-to-erlang-emacs load-path))
      (setq erlang-root-dir "/usr/lib/erlang")
      (setq exec-path (cons "/usr/lib/erlang/bin" exec-path))
      (setq erlang-man-root-dir (concat erlang-root-dir "/man"))
      (require 'erlang-start)
      (defun my-erlang-mode-hook ()
        ;; when starting an Erlang shell in Emacs, default in the node name
        (setq inferior-erlang-machine-options '("-sname" "emacs"))
        ;; add Erlang functions to an imenu menu
        (imenu-add-to-menubar "imenu")
        ;; customize keys
        (local-set-key [return] 'newline-and-indent)
        )

      ;; Some Erlang customizations
      (add-hook 'erlang-mode-hook 'my-erlang-mode-hook)

      ;; distel
      (add-to-list 'load-path "~/.emacs.d/src/distel/elisp")
      (require 'distel)
      (distel-setup)

      (defconst distel-shell-keys
        '(("\C-\M-i"   erl-complete)
          ("\M-?"      erl-complete)
          ("\M-."      erl-find-source-under-point)
          ("\M-,"      erl-find-source-unwind)
          ("\M-*"      erl-find-source-unwind)
          )
        "Additional keys to bind when in Erlang shell.")

      (add-hook 'erlang-shell-mode-hook
                (lambda ()
                  ;; add some Distel bindings to the Erlang shell
                  (dolist (spec distel-shell-keys)
                    (define-key erlang-shell-mode-map (car spec) (cadr spec)))))

      ;; ESense
      ;; (setq path-to-esense "~/.emacs.d/src/esense-1.12")
      ;; (add-to-list 'load-path path-to-esense)
      ;; (require 'esense-start)
      ;; (setq esense-indexer-program (concat path-to-esense "/esense.sh"))

      ;; wrangler
      ;; (add-to-list 'load-path "~/.emacs.d/src/wrangler-0.8.7/elisp")
      ;; (require 'wrangler)

      ;; flymake for erlang
      (require 'erlang-flymake)
      (erlang-flymake-only-on-save)
      
      );; if erlang is present in system
  )

