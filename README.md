# λ ((M))
## "The Power to Serve"
```
(open SysIo Strings)

(echo "Hello World!")

(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))

(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) ; recursion is fast, and there is no callstack. You can use recursion in place of while loops

(echo (body factorial)) ; retrieve a functions body as a mutable cons


(define counter (let ((x 0)) (-> () (setf x (+ x 1))))) ; full support for closures


(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile)))


(define collectIf (-> (pred xs)
 (let ((result ()))
  (each (x xs)
   (if (pred x) (setf result (append result x))))
  result)))


(macro defun (name params body)
`(define ,name (-> ,params ,body))) ; macros and backquote inspired by CL

(defun isEven? (x) (= (mod x 2) 0))


(open Json)

(define jnums (parseJson "[1,2,3,4]"))
(define nums (map (listJson jnums) unbox))




```
