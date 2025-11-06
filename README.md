# ((M))

```


(open Strings)

(define joinStr
 (-> (lines)
  (let ((result ""))
   (each (ln lines)
    (setf result (strConcat result ln)))
    result)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define fact (-> (n acc)
  (if (= n 0)
      acc
      (fact (- n 1) (* acc n)))))


(define xs (map (filter (range 1 1000) (-> (x) (= (mod x 2) 0))) (-> (x) (fact x 1))))


(define fun (-> () (putLn "Hey everybody!")))

(fun)

(setq (body fun) (putLn "Goodbye!"))

(fun)


```
