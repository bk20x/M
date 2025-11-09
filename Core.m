

(macro progn (forms)
 `(let (())
   ,@forms))


(define val (progn (
  (putLn "Yoben")
  (putLn "Boben")
  (+ 5 20))))
