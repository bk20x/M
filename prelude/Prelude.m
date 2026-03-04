(macro do ([forms])
 `(let ()
   ,@forms))

(macro require (modname)
 `(let () 
   (open ,modname)
  (interned-symbols)))
  
(macro module (name [forms])
 `(define ,name
   (let ()
    ,@forms
    (interned-symbols))))

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

