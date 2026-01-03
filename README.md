# λ ((M))  
## "The Power to Serve"
```
(open SysIo Strings)


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) ; recursion is fast, completely separated from the hardware callstack


(echo (body factorial)) ; retrieve a functions body as a mutable cons


(define table {x: 250.0, y: 250.0}) ; support for table literals inspired by Lua


(define Vectors {
  newVector2: (-> (x y) {x: x, y: y})
})


(define pos (Vectors.newVector2 25.0 25.0)) ; you can even use them as modules



(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))  ; macros and backquote inspired by CL

(define xs (collect (x (range 1 1000)) (* x x))) 


(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile))) ; clean one liner

```
