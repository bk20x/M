# λ ((M))  
#### A Simple, Flexible, and Extensible Lisp-1 like language; The core excluding Stdlib is only about 2000 lines of structured self documenting code; Using nothing but the Nim standard library Besides `bigints`
#### Still a work in progress and this is my first attempt at a language but it is already usable for scripting or embedding in Nim programs or making DSLs. you can instantiate the interpreter in 1 line of code and its easy to extend with builtins. I mostly add things as I need them and treat this as more of a personal tool and there are some bugs, but I am open to help. 
###### to install M from nimble run: `nimble install m`. to build from source , clone the repo and run: `nimble build`, to launch the interpreter in repl mode run `m -i` otherwise run `m filename.m`;  code examples are below the Features section and in the `examples` directory

# Features
* Comparable in speed to compiled languages or interpreters like lua; recursive factorial of 10000 computes at `|real 0m0.034s| | sys 0m0.003s |` on my machine (Ryzen 7 7900x).
* Extremely lightweight; uses about 1.6 to 2.2 mb of memory on startup and will only use memory that is actually in use.
* Supports recursing infinitely.
* First class functions and closures.
* CL inspired Macros and backquote.
* Direct metaprogramming (Lambdas are structures allowing for hot swapping of code); code is data in a much more literal sense than Scheme or CL.
* The Reader can natively parse JSON into Tables.
* Seq/Table literals and dot notation for field access.
* Slicing and indexing for Seqs and Strings as well as mutating these slices.
* Easily embedded within applications and extensible with native code with a universal calling convention `proc(args: LispObject): LispObject`  where builtins receive their arguments as a list that you destructure in their implementation.
* Non optimizing but fast; M will never rewrite or elide your code. the closest thing to this is the reader parsing dot access into a specialzed object for lookups.
* Completely cross platform

# Some Examples ^_^
- Flexible macros and syntax
<img src="doc/classex.png" width="800">
- Embed in any nim app in 2 lines
<img src="doc/embedex1.png" width="400">
- JSON is a subset of M, so you can parse it directly into a table just by invoking the reader
<img src="doc/jsonex.png" width="800">
- No startup time
<img src="doc/bench.png" width="800">

```
(open SysIo)

(echo "Hello World!")

'(table examples
  support for table literals inspired by Lua
  you can even use them as modules)

'(interned-symbols returns the innermost scope from the caller's symbol table)
(define String (let () (open Strings) (interned-symbols)))

(define vec2 {x: 250.0, y: 250.0}) 

(define Vectors {
  Vector2: (-> (x y) {x: x, y: y})
})

(define pos (Vectors.Vector2 25.0 25.0)) 
(echo (String.fmt "x=$  y=$" pos.x pos.y))


'(macro examples)

(macro using (modname [forms])
 (if (= 'Cons (typeOf modname)) `(let () (open ,@modname) ,@forms)
  `(let () (open ,modname) ,@forms)))
  
(macro printf (format [xs])
 `(using Strings (echo (fmt ,format ,@xs))))

(define name 'Gobenezer)
(printf "Hello $!" name)

(macro collect (binding body)
 (let ((var        (car binding))
       (collection (car (cdr binding))))
  `(map ,collection (-> (,var) ,body))))  '(macros and backquote inspired by CL)

(define xs (collect (x '(2 4 6 8)) (* x x))) 


'(recursion examples, recursion is fast, separated from the hardware callstack)

(define last (-> (xs) (if (cdr xs) (last (cdr xs)) (car xs))))

(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n))))) 


'(IO and data transformation capabilities)
(define readDir (-> (dir) (map (filter (listDir dir) isFile?) readFile))) 


'(indexing/slicing)

(define str "Yoben Boben")
(echo str[5..(- (String.len str) 1)])

'(there are sequences along with the cons lists for when you need random access or slicing.
  builtins like map and filter or special forms like each work with both of these the same)

(define nums [1,2,3,4,5])
(echo nums[1..3])
(setf nums[1..3] [9, +, 10, =, 21])
(echo nums)

'(mutate/inspect a function directly)

(define f (-> (x) (* x x)))
(echo (f 10))
(setb f '(echo "I dont square numbers anymore!"))
(f 10)

(echo (body f))
(echo (lparams f))
```
Syntax highlighting for emacs: [m-mode](https://github.com/bk20x/m-mode)
