(load "../Prelude.m")
(load "class-macro.m")
(open Strings)

(define constraintError (-> (obj tname) 
 (failwith (fmt"Object $ does not conform to type $" obj tname))))

(macro constrained (name pred)
 `(class ,name (value)
   (  pred   (if (not (,pred value)) (constraintError value ',name) ,pred) 
      value  (-> () value)
      value= (-> (v) (do (if (not (,pred v)) (constraintError v ',name)) (setf value v)))
   )
))

(constrained Even (-> (x) (= (mod x 2) 0)))

