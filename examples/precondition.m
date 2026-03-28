(define len (let nil (open Seq) len))
(define fmt (let nil (open Strings) fmt))

(macro requires (cond body)
 `(if ,cond ,body
   (failwith (fmt"precondition failed $" (image ',cond)))))

(define factorial (-> (x acc)
 (requires (>= x 0)
  (if (= x 0) acc
   (factorial (- x 1) (* acc x))))))


(if (and (safe ~args).success (> (len ~args) 1))
  (let* ((x 	 (~read ~args[1]))
         (result (safe (factorial x 1))))
   (if result.success (echo (fmt"factorial of $ is $" x result.value))
     	(echo (fmt"Error: $" result.value))))
  (echo "Please provide a number"))
