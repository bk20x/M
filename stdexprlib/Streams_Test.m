(load "Streams.m")

(with-file-stream (f "Streams.m")
 (while (not (Streams.atEnd f))
   ((echo (Streams.readChar f)))))


(define Tables (require Tables))
(define countCharacters (-> (string)
 (let ((result {})) 
   (with-string-stream (stream string)
     (while (not (Streams.atEnd stream))
      ((let* ((char  (Streams.readChar stream))
              (count (Tables.get char result)))
	(if count 
	   (Tables.put char (+ count 1) result)
	   (Tables.put char 1 result))))))
	result)))



