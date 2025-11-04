




(define length
 (-> (xs)
  (let ((acc 0))
   (doList (x xs)
    (setf acc (+ acc 1)))
    acc)))


(define sum
 (-> (xs)
  (let ((sum 0))
   (doList (x xs)
    (setf sum (+ sum x)))
   sum)))



(define xs (map '(2 4 6 8) (-> (x) (* x x))))
