(load "class-macro.m")
(load "Tables.m")
(open Strings)

(define getOrDefault (-> (key default table)
 (let ((v (Tables.get key table)))
  (if v v default))))

(class Bag () 
 (
   items {}

   add (-> (x) 
        (let ((count (+ 1 (getOrDefault x 0 self.items))))
         (Tables.put x count self.items)))

   occurencesOf (-> (x) (getOrDefault x 0 self.items))

   mostFrequent (-> () 
   		 (let ((result  nil)
		       (biggest 0)) 
		  (pairs (k v self.items) 
		   (if (> v biggest)
		    (let () (setf biggest v) (setf result k))))
		    result))
 )
)


(define countWords (-> (text)
 (let ((result (Bag)))
  (each (word (split text " "))
   (result.add word))
   result)))

(echo ((countWords "Boben Goben Boben Zambas Gambas Yobert Boben").occurencesOf "Boben"))

