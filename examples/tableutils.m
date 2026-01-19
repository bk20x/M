(open Tables)

(macro withKeys (binding body)
     (let ((k     (car binding))
       (table (car (cdr binding))))
      `(each (,k (tableKeys ,table))
	,body)))

