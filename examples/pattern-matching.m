(macro case (scrutinee clauses)
 `(let ((val ,scrutinee))
   ,(let () 
      (define ~expand (-> (cs)
        (if (= cs ())
            nil
            (let ((pair (car cs)))
              `(if (= val ,(car pair))
                   ,(car (cdr pair))
                   ,(~expand (cdr cs)))))))
      (~expand clauses))))



(define check (-> (x)
  (case (typeOf x)
   (('Int    (echo "Its an int!"))
    ('String (echo "Its a string!"))
    (        (echo "Something else!"))))))


(define i 50)

(define s "Yoben")

(define n nil)

(check i)

(check s)

(check n)
