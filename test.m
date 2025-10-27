


(putLn (strLen "My18CharLongString"))

(if (> 10 5) (putLn (strUpcase "True!!!"))
 (putLn "Not true!!"))



(putLn (typeOf 5))


(fn sayHi (name)
  (putLn (strConcat "Hello!, " name)))

(defvar name "Dad!!")

(sayHi name)

(doList (x (list 2 4 6 8))
 (putLn x))
