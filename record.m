(open Tables Strings)



(macro makeRecord (pairs)
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



(macro >> (obj message args)
 `((getHash ',message ,obj) ,@args))




