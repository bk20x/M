(open Tables)


(define recordImpl (-> (pairs)
  (let ((result (makeTable)))
    (each (pair pairs)
      (let* ((key       (car pair))
             (valueExpr (car (cdr pair)))
             (val       (eval valueExpr)))
        (putHash key val result)))
    result)))

(defmacro makeRecord (pairs)
 `(recordImpl ',pairs))

(defmacro >> (obj message args)
 `((getHash ',message ,obj) ,@args))

(defmacro $ (obj field)
 `(getHash ',field ,obj))

(defmacro $<- (obj field value)
  `(putHash ',field ,value ,obj))


