(open Tables)



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

(macro $ (obj field)
 `(getHash ',field ,obj))

(macro $<- (obj field value)
  `(putHash ',field ,value ,obj))


