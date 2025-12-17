

(macro do (forms)
 `(let (())
   ,@forms))


(define replace (-> (xs old new) (map xs (-> (x) (if (= x old) new x)))))

(define replaceIf (-> (xs pred new) (map xs (-> (x) (if (pred x) new x)))))
