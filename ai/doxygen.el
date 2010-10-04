;;     *  Default key bindings are:
;;           o C-c d ? will look up documentation for the symbol under the point.
;;           o C-c d r will rescan your Doxygen tags file.
;;           o C-c d f will insert a Doxygen comment for the next function.
;;           o C-c d i will insert a Doxygen comment for the current file.
;;           o C-c d ; will insert a Doxygen comment for a member variable on the current line (like M-;).
;;           o C-c d m will insert a blank multi-line Doxygen comment.
;;           o C-c d s will insert a blank single-line Doxygen comment.
;;           o C-c d @ will insert grouping comments around the current region.


(require 'doxymacs)
(add-hook 'c-mode-common-hook'doxymacs-mode)
(setq doxymacs-doxygen-style "C++")

(defun my-doxymacs-font-lock-hook ()
  (if (or (eq major-mode 'c-mode) (eq major-mode 'c++-mode))
        (doxymacs-font-lock)))
(add-hook 'font-lock-mode-hook 'my-doxymacs-font-lock-hook)

(setq doxymacs-doxygen-dirs 
'(
  ("^/home/ai/DevelMail/drweb-maild/Filters/shared/"
   "file:///home/ai/DevelMail/drweb-maild/Filters/shared/sdk_build/DwRsSDK_tag.xml"
   "file:///home/ai/DevelMail/drweb-maild/Filters/shared/sdk_build/dwrssdk/docs/ru/html")
  
  ("^/home/ai/DevelMail/drweb-maild/Engine/plugin/"
   "file:///home/ai/DevelMail/drweb-maild/Engine/plugin/sdk_build/DwPluginsSDK_tags.xml"
   "file:///home/ai/DevelMail/drweb-maild/Engine/plugin/sdk_build/dwpluginsdk/docs/ru/html")
  ))
