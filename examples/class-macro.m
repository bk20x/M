(open Tables)
(load "collect.m")

(macro class (name params fields)
 (let () (define ~gen-table (-> (fs)
    (if (= fs ()) 
        ()
        (cons `(put ',(car fs) ,(car (cdr fs)) self) 
              (~gen-table (cdr (cdr fs)))))))
  
  `(define ,name (-> ,params
    (let ((self {}))
     (let ()
        ,@(~gen-table fields))
       self)))))



