(load "Prelude.m")
(define Streams (require Streams))


(macro with-file-stream (binding body)
 (let ((var      (car binding))
       (filename (car (cdr binding)))) 
 `(let ((,var (Streams.openFileStream ,filename)))
    (try ,body
	  t
  (Streams.close ,var)))))


