(open Tables Strings)



(macro make-record (pairs)
 (let* ((result (makeTable))
	(fn (-> (pairs)
	    (each (pair pairs)
	     (let* ((key (car pair))
		    (valueExpr (car (cdr pair)))
		    (val (eval valueExpr)))
	      (putHash key val result)))
	    result)))
  (fn pairs)
 `',result))

(macro @Record (name bindings)
 `(define ,name (make-record ,bindings)))

(macro withKeys (binding body)
 (let ((k     (car binding))
       (table (car (cdr binding))))
  `(each (,k (tableKeys ,table))
    ,body)))

(macro $ (obj field)
 `(getHash ',field ,obj))


(macro >> (obj message args)
   `((getHash ',message ,obj) ,@args))

(macro isDefined? (sym)
 `(hasKey ',sym (interned-symbols)))


(macro new (name binds)
 `(if (= (typeOf ,name) 'HashTable)
     (let ((result (clone ,name)))
      (each (bind ',binds)
       (let* ((valueExpr (car (cdr bind)))
	     (val       (eval valueExpr)))
	(if (hasKey (car bind) result) (putHash (car bind) val result))))
      result)))
