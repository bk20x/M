(open Tables)


(define recordImpl (-> (pairs)
  (let ((result (makeTable)))
    (each (pair pairs)
      (let* ((key       (car pair))
             (valueExpr (car (cdr pair)))
             (val       (eval valueExpr)))
        (putHash key val result)))
    result)))

(macro makeRecord (pairs)
 `(recordImpl ',pairs))

(macro >> (obj message args)
 `((getHash ',message ,obj) ,@args))

(macro $ (obj field)
 `(getHash ',field ,obj))

(macro $<- (obj field value)
  `(putHash ',field ,value ,obj))


