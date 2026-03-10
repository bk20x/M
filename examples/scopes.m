'("interned-symbols" is a special form that captures the innermost scope to the callers symbol table and returns it)

(define obj (let ((x 5) (y 15)) (interned-symbols)))
(echo obj)

(define String (let () (open Strings) (interned-symbols)))
(echo (String.fmt "Strings module=$" String))


(macro module (name [body])
 `(define ,name 
   (let ()
     ,@body
     (interned-symbols))))

(module MyModule 
  (define hello (-> (name) (echo (String.fmt "Hello $!" name))))
)

(MyModule.hello "Boben")
