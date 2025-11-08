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

(macro $ (object field)
 `(getHash ',field ,object))

(macro $<- (field val object)
 `(putHash ',field ,val ,object))

(macro >> (obj message args)
 `((getHash ',message ,obj) ,@args))


(macro withKeys (binding body)
 (let ((k     (car binding))
       (table (car (cdr binding))))
  `(each (,k (tableKeys ,table))
    ,body)))


(define Boben
 (makeRecord
  ((Name "Jaquarius Ebenezer Boben Jr. III")
   (Id   92)
   (sayHi (-> (name) (putLn (fmt "Yoben $! my name $" name ($ Boben Name))))))))



