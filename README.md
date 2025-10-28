```
(putLn (strLen "My18CharLongString"))



(fn printNames (names)
 (doList (name names)
  (putLn (strUpcase name))))

(putLn printNames) ;; functions are regular values, like in scheme they are just named lambdas


(defvar myList (list "Bober" "Cerny" "Yoben"))

(printNames myList)


(fn isNil? (obj)
 (if obj nil t))


(putLn (isNil? 5))

```
