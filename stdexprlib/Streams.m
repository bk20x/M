(load "Prelude.m")
(define Streams (require Streams))


(macro with-file-stream (binding body)
 (let ((stream   (car binding))
       (filename (car (cdr binding)))) 
 `(let ((,stream (Streams.openFileStream ,filename)))
    (try ,body
  (Streams.close ,stream)
  (Streams.close ,stream)))))


