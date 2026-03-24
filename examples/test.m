(open SysIo)

(define len 
 (let* ((impl (-> (xs result) (if xs (impl (cdr xs) (+ result 1)) result)))) 
   (-> (xs) (impl xs 0))))


(define Seq (let nil (open Seq) (interned-symbols)))

(if (<= 2 (Seq.len ~args))
 (echo (len (listDir ~args[1])))
 (echo "Please provide a directory name"))
