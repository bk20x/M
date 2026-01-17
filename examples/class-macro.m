(open Tables)
(load "collect.m")

(macro class (name params fields)
 (let () (define build-table (-> (fs)
    (if (= fs ()) 
        ()
        (cons `(put ',(car fs) ,(car (cdr fs)) self) 
              (build-table (cdr (cdr fs)))))))
  
  `(define ,name (-> ,params
    (let ((self {}))
     (let ()
        ,@(build-table fields))
       self)))))



(let ()
  (class Vector2 (x y) (
      getX (-> () x)
      getY (-> () y)
      setX (-> (~x) (setf x ~x))
      setY (-> (~y) (setf y ~y))
  ))
  (define p1 (Vector2 9.7 6.8))
  (echo (p1.getX))
)

