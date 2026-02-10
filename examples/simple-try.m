'(safe is special form that wraps an expression and returns a table with the fields "success" and "result"
  success being either T or Nil and result being either the result of the expression or the error message on failure)


(macro try (call body catcher)
  `(let ((result (safe ,call))) 
    (if result.success ,body ,catcher)))


(open Strings)

(try (* "boben" 'gambas) 
 (echo (fmt "success! value=$"         result.value))
 (echo (fmt "failure! error message=$" result.value)))


(try (* 5 5) 
 (echo (fmt "success! value=$"         result.value))
 (echo (fmt "failure! error message=$" result.value)))
