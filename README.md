# λ ((M))  
## "The Power to Serve"
```
(open SysIo Strings)


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) ; recursion is fast, and there is no callstack. You can use recursion in place of while loops

(echo (body factorial)) ; retrieve a functions body as a mutable cons



(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define counter (let ((x 0)) (-> () (setf x (+ x 1))))) ; full support for closures


(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile)))


(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))


(define xs (collect (x (range 1 1000)) (* x x)))


(macro defun (name params body)
`(define ,name (-> ,params ,body))) ; macros and backquote inspired by CL


(defun isEven? (x) (= (mod x 2) 0))


(define table {x: 250.0, y: 250.0}) ; support for table literals inspired by Lua

```
