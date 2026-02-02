(load "Prelude.m")
(define Seq (require Seq))
(define Streams (require Streams))



(macro with-file-stream (binding body)
  (let ((stream   (car binding))
        (filename (car (cdr binding)))) 
  `(let ((,stream (Streams.openFileStream ,filename)))
     (try ,body
   (Streams.close ,stream)
   (Streams.close ,stream)))))


(macro with-string-stream (binding body)
 (let ((stream (car binding))
       (buffer (car (cdr binding)))) 
       `(let ((,stream (Streams.openStringStream ,buffer)))
         (try ,body
          (Streams.close ,stream)
	  (Streams.close ,stream)))))


(define tokenize (-> (string)
 (let ((result [])) 
  (with-string-stream (stream string) 
   (while (not (Streams.atEnd stream)) 
    ((Seq.add result (Streams.readChar stream)))))
    result)))
