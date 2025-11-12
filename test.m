(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n)))))



(load "record.m")

(@Record Vector2
 ((x 0) (y 0)))

(define velocity (new Vector2 ((x 150) (y 150))))

(define counter
 (let ((x 0))
  (-> () (setf x (+ x 1)))))



