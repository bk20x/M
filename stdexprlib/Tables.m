(define Tables (let () (open Tables) (interned-symbols)))

(macro withKeys (binding body)
     (let ((k     (car binding))
       (table (car (cdr binding))))
      `(each (,k (Tables.keys ,table))
	,body)))


(macro pairs (binding body)
 (let ((k     (car binding))
       (v     (car (cdr binding)))
       (table (car (cdr (cdr binding))))) 
    `(each (,k (Tables.keys ,table)) 
      (let ((,v (Tables.get ,k ,table)))
        ,body))))


(define mapvs (-> (table fn) 
  (let ((result {})) 
    (pairs (k v table) (Tables.put k (fn v) result))
  result)))

(define filtervs (-> (table pred)
 (let ((result {})) 
   (pairs (k v table) 
     (if (pred v) (Tables.put k v result)))
  result)))


(define consume (-> (src dest)
 (let () (pairs (k v src) (Tables.put k v dest)) dest)))
