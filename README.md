# λx.(M)

```
(define xs (map '(2 4 6 8) (-> (x) (* x x))))

(open Strings)

(define joinStr
 (-> (lines)
  (let ((result ""))
   (doList (ln lines)
    (setf result (strConcat result ln)))
    result)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define fact (-> (n acc)
  (if (= n 0)
      acc
      (fact (- n 1) (* acc n)))))


(define fun (-> () (putLn "Hey everybody!")))

(fun)

(setq (body fun) (putLn "Goodbye!"))

(fun)


```
