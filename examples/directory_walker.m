(load "Prelude.m")
(open SysIo Seq)

(define mapDirRec 
 (let ()
  (define walk (-> (dir result) 
   (let ((files []))
    (each (path (listDir dir))
     (if (isFile? path) (add files path)
       (do (add files path) (walk path result))))
    (put dir files result)
    result)))
   (-> (dir) (walk dir {}))))
