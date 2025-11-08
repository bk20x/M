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


(macro defrecord (name record)
 `(define ,name (makeRecord ,record)))

(macro withKeys (binding body)
 (let ((k     (car binding))
       (table (car (cdr binding))))
  `(each (,k (tableKeys ,table))
    ,body)))


(defrecord boben
 ((Name "Jaquarius Ebenezer Boben Junior III")
  (Bobenized t)))


(withKeys (key boben)
 (putLn (getHash key boben)))



(macro >> (obj message args)
 `((getHash ',message ,obj) ,@args))



