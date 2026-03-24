(define fmt (let nil (open Strings) fmt))

(macro requires (cond body)
 `(if ,cond ,body
   (failwith (fmt"precondition failed $" (image ',cond)))))

(define factorial (-> (x acc)
 (requires (> x 0)
  (if (= x 0) acc
   (factorial (- x 1) (* acc x))))))

