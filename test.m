(open SysIo Strings)

(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))

(macro defun (name params body)
`(define ,name (-> ,params ,body)))

(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n)))))

(define counter (let ((x 0)) (-> () (setf x (+ x 1)))))



(define files (map (listDir ".") (-> (f) (strReplace f "./" ""))))

(define fileContents (map (filter files isFile?) readFile))


