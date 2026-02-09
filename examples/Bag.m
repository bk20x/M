(load "class-macro.m")
(open Tables Strings)

(define getOrDefault (-> (key default table)
 (let ((v (get key table)))
  (if v v default))))

(class Bag () 
 (
   items {}

   add (-> (x) 
        (let ((count (+ 1 (getOrDefault x 0 self.items))))
         (put x count self.items)))

   occurencesOf (-> (x) (getOrDefault x 0 self.items))
 )
)

(define countWords (-> (text)
 (let ((result (Bag)))
  (each (word (split text " "))
   (result.add word))
   result)))

(echo ((countWords "Boben Goben Boben Zambas Gambas Yobert Boben").occurencesOf "Boben"))
