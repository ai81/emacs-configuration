(require 'ps-mule)
(setq printer-name 'PRINTER);;ставим имя принтера
(setq ps-print-color-p nil);;отключаем цвета
(setq ps-multibyte-buffer nil);;используем наши шрифты
(setq bdf-directory-list (list "/usr/share/fonts/bdf"));;путь к шрифтам
(setq ps-font-family 'Times);;настройка шрифтов
(setq ps-font-size   '(7 . 9.5));;размер шрифтов
(setq ps-mule-font-info-database-default ps-mule-font-info-database-bdf);;настройки шрифтов
