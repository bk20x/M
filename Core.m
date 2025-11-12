

(macro do (forms)
 `(let (())
   ,@forms))


(define replace (-> (xs old new) (map xs (-> (x) (if (= x old) new x)))))

