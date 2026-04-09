(load "Streams.m")
(define String (require Strings))

(define parseIni (-> (str)
 (let ((result  {})
       (key     "")
       (val     "")
       (char    # ))
  (with-string-stream (stream str)
   (while (not (Streams.atEnd stream))
    (
       (setf char (Streams.readChar stream))
       (while (not (= char #=))
         (
	   (setf key (String.concat key (image char)))
	   (setf char (Streams.readChar stream))
	 )
	)
	(setf char (Streams.readChar stream))
	(while (not (String.whitespace? char))
	 (
	   (setf val (String.concat val (image char)))
	   (setf char (Streams.readChar stream))
	 )
	)
    ))) 
    (using Tables (put key (~read val) result) result))))

(define ini (using SysIo
 (collectIf (-> (ln) (not (String.whitespace? ln)))
  (ln (String.splitLines (readFile "test.ini"))) parseIni)))

(each (pair ini) (echo pair))
