'("interned-symbols" is a special form that captures the innermost scope to the callers symbol table and returns it)


(define obj (let ((x 5) (y 15)) (interned-symbols)))
(echo obj.y)

(define String (let () (open Strings) (interned-symbols)))
(echo (String.fmt "Strings module=$" String))


