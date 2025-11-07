(open Strings Tables)

(define joinStr (-> (lines)
 (let ((result ""))
  (each (ln lines)
   (setf result (strConcat result ln)))
    result)))



(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n)))))



(defmacro make-record (pairs)
  (let ((insertions (map pairs (-> (pair) `(putHash ',(car pair) ,(car (cdr pair)) result)))))
    `(let ((result (makeTable)))
      ,@(append insertions 'result)))))
