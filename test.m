(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n)))))


(load "record.m")

(define rec (
  makeRecord (
   (Name "Boben")
   (Bober "Cerny")
   (speak (-> () (putLn ($ rec Name))))
)))
