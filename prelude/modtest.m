(load "Prelude.m")

(echo module)

(module MyModule (
    (define add (-> (a) (-> (b) (+ a b))))
))

(define add5 (MyModule.add 5))

(echo add5)

(echo (add5 10))
