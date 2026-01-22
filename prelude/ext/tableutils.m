(open Tables)

(macro withKeys (binding body)
     (let ((k     (car binding))
       (table (car (cdr binding))))
      `(each (,k (tableKeys ,table))
	,body)))


(macro pairs (binding body)
 (let ((k     (car binding))
       (v     (car (cdr binding)))
       (table (car (cdr (cdr binding))))) 
    `(each (,k (tableKeys ,table)) 
      (let ((,v (get ,k ,table)))
        ,body))))


(define mapvs (-> (table fn) 
  (let ((result {})) 
    (pairs (k v table) (put k (fn v) result))
  result)))

(define filtervs (-> (table pred)
 (let ((result {})) 
   (pairs (k v table) 
     (if (pred v) (put k v result)))
  result)))


(define consume (-> (src dest)
 (let () (pairs (k v src) (put k v dest)) dest)))
