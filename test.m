




(define length (-> (xs) (let ((acc 0)) (doList (x xs) (setf acc (+ acc 1))) acc)))

(open Strings)

(define joinStr (-> (lines)
 (let ((result ""))
  (doList (ln lines)
   (setf result (strConcat result ln)))
    result)))






(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))



(define fact (-> (n acc)
  (if (= n 0)
      acc
      (fact (- n 1) (* acc n)))))


