# λ ((M))
```
(echo "Hello World!")

(define range (-> (lo hi)
 (if (> lo hi) ()
  (cons lo (range (+ lo 1) hi)))))


(define fact (-> (n acc)
  (if (= n 0)
       acc
      (fact (- n 1) (* acc n)))))

(define counter (let ((x 0)) (-> () (setf x (+ x 1)))))

(define xs (map (filter (range 1 1000) (-> (x) (= (mod x 2) 0))) (-> (x) (fact x 1))))


(open SysIo Strings)

(define files (map (listDir ".") (-> (f) (strReplace f "./" ""))))

(define fileContents (map (filter files isFile?) readFile))


(open Json)

(define jnums (parseJson "[1, 2, 3, 4, 5, 6]"))

(define nums (map (listJson jnums) unbox))

```
