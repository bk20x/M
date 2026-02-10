'(in M lambdas are mutable and inspectable basically to the extent of any other data
  M provides builtins "body" and "lparams" which return a reference to the lambdas body and parameters respectively.
  as well as "setb" and "setp" for setting the parameters and body directly)


(open Strings)

(define f (-> (x) (* x x)))
(echo (f 10))

(echo (fmt "params = $ body = $" (lparams f) (body f)))

(echo (fmt "f before mutation=$" f))
(setq (car (body f)) +)
(echo (fmt "f after mutation=$" f))
(echo (f 10))

(setp f nil)
(setb f '(echo "I dont do any kind of math anymore!"))
(echo (fmt "someone hacked the system and mutated our function again $" f))
(f)
