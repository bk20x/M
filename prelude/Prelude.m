(macro do ([forms])
 `(let ()
   ,@forms))

(macro require ([modnames])
 `(let () 
   (open ,@modnames)
  (interned-symbols)))
  
(macro using (modname [forms])
 `(let () 
   (open ,modname)
   ,@forms))

(macro try (call body catcher)
  `(let ((result (safe ,call))) 
    (if result.success ,body 
     ,catcher)))

(macro defined? (sym)
 `(try ,sym
    result.success
    nil))

(macro printf (format [xs])
`(using Strings (echo (fmt ,format ,@xs))))

(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  (if (= (typeOf body) 'Cons)
   `(map ,collection (-> (,var) ,body))
   `(map ,collection ,body))))

(macro collectIf (pred binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  (if (= (typeOf body) 'Cons)
    `(map (filter ,collection ,pred) (-> (,var) ,body))
    `(map (filter ,collection ,pred) ,body))))

(macro destructuring-bind (vars collection body)
 (let ()
  (define ~gen-bindings (-> (vs coll)
    (if (= vs ())
        ()
        (cons `(,(car vs) (car ,coll))
              (~gen-bindings (cdr vs) `(cdr ,coll))))))
  `(let (,@(~gen-bindings vars collection))
    ,body)))

(macro case (scrutinee [clauses])
 `(let ((val ,scrutinee))
   ,(let () 
      (define ~expand (-> (cs)
        (if (= cs ())
            nil
            (let ((pair (car cs)))
              `(if (= val ,(car pair))
                   ,(car (cdr pair))
                   ,(~expand (cdr cs)))))))
      (~expand clauses))))

