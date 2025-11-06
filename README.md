# λx.(M)

```
(define xs (map '(2 4 6 8) (-> (x) (* x x))))


(define range
 (-> (lo hi)
  (if (> lo hi) ()
   (cons lo (range (+ lo 1) hi)))))


(define fun (-> () (putLn "Hey everybody!")))

(fun)

(setq (body fun) (putLn "Goodbye!"))

(fun)


```
