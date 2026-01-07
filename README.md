# λ ((M))  
#### This is designed to be something one person can master; The core of the language excluding Stdlib is only about 1400 lines of structured self documenting code; Using nothing but the Nim standard library Besides BigInts from the Nim Team
#### Still a work in progress but it is already a capable tool for systems scripting or embedding in any Nim Application.  you can instantiate the interpreter in 1 line of code and its trivial to extend with builtins 
###### to install M from nimble run: `nimble install m`. to build from source , clone the repo and run: `nimble build`, to launch the interpreter in repl mode run `m -i` otherwise run `m filename.m`;  code examples are below the Features section and in the `examples` directory 

# Features
* Close to Native speed; recursive factorial of 10000 computes at `|real 0m0.034s| | sys 0m0.003s |`
* Extremely lightweight; uses about 1.6 to 2.2 mb of memory on startup and ALWAYS will only use memory that is actually in use
* Safe and fast Infinite recursion
* First class functions and symbols
* Powerful Macros and Backquote
* Direct metaprogramming (Lambdas are structures allowing for hot reloading / hot swapping); code is data in a much more literal sense than Scheme or CL
* Object literals and dot notation
* Batteries included Standard library (Still WIP)
* Trivially extensible with native code and embedded within applications
* Completely cross platform; can fit in flash memory
* many more ...

# Some Examples ^_^
![](doc/ex1.png)
```
(open SysIo Strings)

(echo "Hello World!")

;; table examples
;; support for table literals inspired by Lua
;; you can even use them as modules

(define vec2 {x: 250.0, y: 250.0}) 

(define Vectors {
  Vector2: (-> (x y) {x: x, y: y})
})

(define pos (Vectors.Vector2 25.0 25.0)) 

(echo (fmt "x=$  y=$" pos.x pos.y))

;; recursion examples, recursion is fast, completely separated from the hardware callstack

(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) 

(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))
  

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
