```
(define xs (map '(2 4 6 8) (-> (x) (* x x))))


(define length
 (-> (xs)
  (let ((acc 0))
   (doList (x xs)
    (setf acc (+ acc 1)))
    acc)))


(define fun (-> () (putLn "Hello World!")))

(fun)

(setq (body fun) (putLn "Goodbye!"))

(fun)


```
