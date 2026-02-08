(load "class-macro.m")
(open Tables Strings)

(class Bag () (
  items {}
  add (-> (x) 
       (let ((count (get x self.items)))
        (if count
	  (put x (+ count 1) self.items)
	  (put x 1 self.items))))
  
))

(define examples {
    countWords: (-> (text) 
                 (let ((result (Bag))) 
		   (each (word (split text " "))
		    (result.add word))
		       result.items))

})
