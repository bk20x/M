(macro destructuring-bind (vars collection body)
 (let () (define ~gen-bindings (-> (vs coll)
    (if (= vs ())
        ()
        (cons `(,(car vs) (car ,coll))
              (~gen-bindings (cdr vs) `(cdr ,coll))))))
  `(let (,@(~gen-bindings vars collection))
    ,body)))


(open Strings)

(define xs '(2 4 6 8))

(destructuring-bind (x y) xs (echo (* x y)))
(destructuring-bind (x y z) xs (echo (fmt "x=$ y=$ z=$" x y z)))
