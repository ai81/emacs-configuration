;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ThreeWindows
;; http://www.emacswiki.org/emacs-en/ThreeWindows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  +-----------------------+----------------------+
;  |                       |                      |
;  |                       |                      |
;  |                       |                      |
;  +-----------------------+----------------------+
;  |                       |                      |
;  |                       |                      |
;  |                       |                      |
;  +-----------------------+----------------------+
(defun split-window-4()
 "Splite window into 4 sub-window"
 (interactive)
 (if (= 1 (length (window-list)))
     (progn (split-window-vertically)
	    (split-window-horizontally)
	    (other-window 2)
	    (split-window-horizontally)
	    )
   )
)

;  +----------------------+                 +----------- +-----------+ 
;  |                      |           \     |            |           | 
;  |                      |   +-------+\    |            |           | 
;  +----------------------+   +-------+/    |            |           |
;  |                      |           /     |            |           | 
;  |                      |                 |            |           | 
;  +----------------------+                 +----------- +-----------+ 

(defun split-v ()
  (interactive)
  (if (= 2 (length (window-list)))
    (let (( thisBuf (window-buffer))
	  ( nextBuf (progn (other-window 1) (buffer-name))))
	  (progn   (delete-other-windows)
		   (split-window-horizontally)
		   (set-window-buffer nil thisBuf)
		   (set-window-buffer (next-window) nextBuf)
		   ))
    )
)


;  +----------- +-----------+                  +----------------------+ 
;  |            |           |            \     |                      | 
;  |            |           |    +-------+\    |                      | 
;  |            |           |    +-------+/    +----------------------+ 
;  |            |           |            /     |                      | 
;  |            |           |                  |                      | 
;  +----------- +-----------+                  +----------------------+ 

(defun split-h ()
  (interactive)
  (if (= 2 (length (window-list)))
    (let (( thisBuf (window-buffer))
	  ( nextBuf (progn (other-window 1) (buffer-name))))
	  (progn   (delete-other-windows)
		   (split-window-vertically)
		   (set-window-buffer nil thisBuf)
		   (set-window-buffer (next-window) nextBuf)
		   ))
    )
)

;  +----------------------+                 +----------- +-----------+ 
;  |                      |           \     |            |           | 
;  |                      |   +-------+\    |            |           | 
;  +----------------------+   +-------+/    |            |-----------|
;  |         |            |           /     |            |           | 
;  |         |            |                 |            |           | 
;  +----------------------+                 +----------- +-----------+ 


(defun split-v-3 ()
  "Change 3 window style from horizontal to vertical"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (length (window-list)))
      (let ((winList (window-list)))
	    (let ((1stBuf (window-buffer (car winList)))
		  (2ndBuf (window-buffer (car (cdr winList))))
		  (3rdBuf (window-buffer (car (cdr (cdr winList))))))
	      (message "%s %s %s" 1stBuf 2ndBuf 3rdBuf)
	      (delete-other-windows)
	      (split-window-horizontally)
	      (set-window-buffer nil 1stBuf)
	      (other-window 1)
	      (set-window-buffer nil 2ndBuf)
	      (split-window-vertically)
	      (set-window-buffer (next-window) 3rdBuf)
	      (select-window (get-largest-window))
	    )
	  )
    )
)

;  +----------- +-----------+                  +----------------------+ 
;  |            |           |            \     |                      | 
;  |            |           |    +-------+\    |                      | 
;  |            |-----------|    +-------+/    +----------------------+ 
;  |            |           |            /     |          |           | 
;  |            |           |                  |          |           | 
;  +----------- +-----------+                  +----------------------+ 


(defun split-h-3 ()
  "Change 3 window style from vertical to horizontal"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (length (window-list)))
      (let ((winList (window-list)))
	    (let ((1stBuf (window-buffer (car winList)))
		  (2ndBuf (window-buffer (car (cdr winList))))
		  (3rdBuf (window-buffer (car (cdr (cdr winList))))))
		(message "%s %s %s" 1stBuf 2ndBuf 3rdBuf)
		(delete-other-windows)
		(split-window-vertically)
		(set-window-buffer nil 1stBuf)
		(other-window 1)
		(set-window-buffer nil 2ndBuf)
		(split-window-horizontally)
		(set-window-buffer (next-window) 3rdBuf)
		(select-window (get-largest-window))
	      )
	    )
    )
)

;  +----------- +-----------+                    +----------- +-----------+ 
;  |            |     C     |            \       |            |     A     | 
;  |            |           |    +-------+\      |            |           | 
;  |     A      |-----------|    +-------+/      |     B      |-----------| 
;  |            |     B     |            /       |            |     C     | 
;  |            |           |                    |            |           | 
;  +----------- +-----------+                    +----------- +-----------+ 
;
;  +------------------------+                     +------------------------+ 
;  |           A            |           \         |           B            | 
;  |                        |   +-------+\        |                        | 
;  +------------------------+   +-------+/        +------------------------+ 
;  |     B     |     C      |           /         |     C     |     A      | 
;  |           |            |                     |           |            | 
;  +------------------------+                     +------------------------+ 


(defun roll-v-3 ()
  "Rolling 3 window buffers clockwise"
  (interactive)
  (select-window (get-largest-window))
  (if (= 3 (length (window-list)))
      (let ((winList (window-list)))
	    (let ((1stWin (car winList))
		  (2ndWin (car (cdr winList)))
		  (3rdWin (car (cdr (cdr winList)))))
	      (let ((1stBuf (window-buffer 1stWin))
		    (2ndBuf (window-buffer 2ndWin))
		    (3rdBuf (window-buffer 3rdWin))
		    )
		    (set-window-buffer 1stWin 3rdBuf)
		    (set-window-buffer 2ndWin 1stBuf)
		    (set-window-buffer 3rdWin 2ndBuf)
		    )
	      )
	    )
    )
)

;;  +----------------------+                +---------- +----------+
;;  |                      |          \     |           |          |
;;  |                      |  +-------+\    |           |          |
;;  +----------------------+  +-------+/    |           |          |
;;  |                      |          /     |           |          |
;;  |                      |                |           |          |
;;  +----------------------+                +---------- +----------+
;;
;;  +--------- +-----------+                +----------------------+
;;  |          |           |          \     |                      |
;;  |          |           |  +-------+\    |                      |
;;  |          |           |  +-------+/    +----------------------+
;;  |          |           |          /     |                      |
;;  |          |           |                |                      |
;;  +--------- +-----------+                +----------------------+

(defun change-split-type ()
  "Changes splitting from vertical to horizontal and vice-versa"
  (interactive)
  (if (= 2 (length (window-list)))
      (let ((thisBuf (window-buffer))
            (nextBuf (progn (other-window 1) (buffer-name)))
            (split-type (if (= (window-width)
                               (frame-width))
                            'vertical
                            'horizontal)))
        (progn
          (delete-other-windows)
          (cond
            ((eq split-type 'horizontal)
             (split-window-vertically))
            ((eq split-type 'vertical)
             (split-window-horizontally)))
          (set-window-buffer nil thisBuf)
          (set-window-buffer (next-window) nextBuf)))))
