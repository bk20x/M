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









