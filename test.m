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

(define flatten (-> (xs)
  (let ((result ()))
    (each (x xs)
     (if (= (typeOf x) 'Cons)
        (setf result (append result (flatten x)))
        (setf result (append result (list x)))))
   result)))


(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile)))

(macro do (forms)
	    `(let (())
	     ,@forms))


(define isEven? (-> (x) (= (mod x 2) 0)))


(define collectIf (-> (pred xs)
		   (let ((result ()))
		    (each (x xs)
		     (if (pred x) (setf result (append result x))))
		    result)))
