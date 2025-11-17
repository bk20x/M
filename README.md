# λ ((M))

```


(define length (-> (xs) (let ((acc 0)) (each (x xs) (setf acc (+ acc 1))) acc)))


(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define factorial (-> (n acc)
  (if (= n 0)
       acc
      (factorial (- n 1) (* acc n)))))

(define counter (let ((x 0)) (-> () (setf x (+ x 1)))))

(echo "Hello World!")


(define xs (map (filter (range 1 1000) (-> (x) (= (mod x 2) 0))) (-> (x) (fact x 1))))




(open Json)

(define jnums (parseJson "[1, 2, 3, 4, 5, 6]"))

(define nums (map (listJson jnums) unbox))



(define fun (-> () (echo "Hey everybody!")))

(fun)

(setq (body fun) (echo "Goodbye!"))

(fun)


```
