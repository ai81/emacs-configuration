(defcustom browse-url-opera-program "opera"
  "*The name by which to invoke Opera."
  :type 'string
  :group 'browse-url)

(defcustom browse-url-opera-arguments '("-newwindow")
  "*A list of strings to pass to Opera as arguments."
  :type '(repeat (string :tag "Argument"))
  :group 'browse-url)

(defun browse-url-opera (url &optional new-window)
  (interactive (browse-url-interactive-arg "URL: "))
  (apply 'start-process (concat "opera " url)
         nil
         browse-url-opera-program
         (append
          browse-url-opera-arguments
          (list url))))

(defcustom browse-url-chrome-program "google-chrome"
  "*The name by which to invoke Chrome."
  :type 'string
  :group 'browse-url)

(defcustom browse-url-chrome-arguments '("")
  "*A list of strings to pass to Chrome as arguments."
  :type '(repeat (string :tag "Argument"))
  :group 'browse-url)

(defun browse-url-chrome (url &optional new-window)
  (interactive (browse-url-interactive-arg "URL: "))
  (apply 'start-process (concat "google-chrome " url)
         nil
         browse-url-chrome-program
         (append
          browse-url-chrome-arguments
          (list url))))

;;функция для опередения браузера для открытия
(defun browse-url-my-browser (url &rest args)
 (setq browse-url-new-window-flag t);;что бы открыть в новом окне
 (apply
  (cond
     ((executable-find browse-url-chrome-program) 'browse-url-chrome)
     ((executable-find browse-url-opera-program) 'browse-url-opera)
     ((executable-find browse-url-firefox-program) 'browse-url-firefox)
     ((executable-find browse-url-kde-program) 'browse-url-kde)
     (t
      (lambda (&ignore args) (error "No usable browser found"))))
     url args))

(setq browse-url-browser-function 'browse-url-my-browser);;устанавливаем наш собственный 
                                                         ;;браузер по-умолчанию
