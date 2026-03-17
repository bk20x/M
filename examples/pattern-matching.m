(macro case (scrutinee [clauses])
 `(let ((~val ,scrutinee))
   ,(let () 
      (define ~expand (-> (cs)
        (if (= cs ())
            nil
            (let ((pair (car cs)))
              `(if (= ~val ,(car pair))
                   ,(car (cdr pair))
                   ,(~expand (cdr cs)))))))
      (~expand clauses))))



(define check (-> (x)
  (case (typeOf x)
    ('Int    (echo "Its an int!"))
    ('String (echo "Its a String!"))
    (        (echo "Its something else!")))))


(define int 50)
(define str "Yoben")
(define none nil)

(check int)
(check str)
(check none)
