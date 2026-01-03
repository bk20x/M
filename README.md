# λ ((M))  
#### This is designed to be something one person can master; The core of the language excluding Stdlib is only about 1400 lines of structured self documenting code; Using nothing but the Nim standard library (Besides BigInts which is made and maintained by the Nim team as well)
#### Still a work in progress but it is already a capable tool for systems scripting or embedding in any Nim Application.  you can instantiate the interpreter in 1 line of code and its trivial to extend with builtins 

# Features
* Safe and fast Infinite recursion
* First class functions and symbols
* Powerful Macros and Backquote
* Direct metaprogramming (Lambdas are structures allowing for hot reloading / hot swapping); code is data in a much more literal sense than Scheme or CL
* Object literals and dot notation
* Batteries included Standard library (Still WIP)
* Trivially extensible with native code and embedded within applications
* Completely cross platform; can fit in flash memory
* many more ...

# Some Examples :)
```
(open SysIo Strings)

;; table examples
;; support for table literals inspired by Lua

(define table {x: 250.0, y: 250.0}) 



;; you can even use them as modules

(define Vectors {
  newVector2: (-> (x y) {x: x, y: y})
})


(define pos (Vectors.newVector2 25.0 25.0)) 


;; recursion examples, recursion is fast, completely separated from the hardware callstack

(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) 


;; retrieve a functions body as a mutable cons
(echo (body factorial)) 



;; macro examples

(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))  ; macros and backquote inspired by CL

(define xs (collect (x (range 1 1000)) (* x x))) 



;; IO and data transformation capabilities 

(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile))) ; clean one liner

```
