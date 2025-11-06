




(define length (-> (xs) (let ((acc 0)) (doList (x xs) (setf acc (+ acc 1))) acc)))

(open Strings)

(define joinStr
 (-> (lines)
  (let ((result ""))
   (doList (ln lines)
    (setf result (strConcat result ln)))
    result)))

(define xs (map '(2 4 6 8) (-> (x) (* x x))))


(define range (-> (lo hi) (if (> lo hi) () (cons lo (range (+ lo 1) hi)))))
