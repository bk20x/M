(open Tables)

(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))


(macro collectIf (pred binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map (filter ,collection ,pred) (-> (,var) ,body))))

(macro try (call body catcher)
  `(let ((result (safe ,call))) 
    (if result.success ,body ,catcher)))

(macro withKeys (binding body)
     (let ((k     (car binding))
       (table (car (cdr binding))))
      `(each (,k (tableKeys ,table))
	,body)))

(macro destructuring-bind (vars collection body)
 (let () (define ~gen-bindings (-> (vs coll)
    (if (= vs ())
        ()
        (cons `(,(car vs) (car ,coll))
              (~gen-bindings (cdr vs) `(cdr ,coll))))))
  `(let (,@(~gen-bindings vars collection))
    ,body)))
