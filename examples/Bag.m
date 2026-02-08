(load "class-macro.m")
(define Tables (let () (open Tables) (interned-symbols)))

(class Bag () (
  items {}
  add (-> (x) 
       (let ((count (Tables.get x self.items)))
        (if count
	  (Tables.put x (+ count 1) self.items)
	  (Tables.put x 1 self.items))))
  
))

(define examples {
    countWords: (-> (text) 
                 (let ((result (Bag))) 
		   (open Strings)
		   (each (word (split text " "))
		    (result.add word))
		       result.items))

})
