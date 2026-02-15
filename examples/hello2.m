(define String (let () (open Strings) (interned-symbols)))

(define hello (-> (name) (echo (String.fmt "Hello there $!" name))))

(hello 'Bober)
