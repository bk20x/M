

(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))


(macro collectIf (pred binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map (filter ,collection ,pred) (-> (,var) ,body))))
