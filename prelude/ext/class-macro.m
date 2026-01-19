(open Tables)

(macro class (name params iface)
 (let () (define ~gen-table (-> (fs)
    (if (= fs ()) 
        ()
        (cons `(put ',(car fs) ,(car (cdr fs)) self) 
              (~gen-table (cdr (cdr fs)))))))
  
  `(define ,name (-> ,params
    (let ((self {}))
     (let ()
        ,@(~gen-table iface))
       self)))))
