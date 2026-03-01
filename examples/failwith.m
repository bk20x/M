(open Strings)

(define indexOf (-> (thing xs)
 (safe (each (idx x xs) (if (= thing x) (failwith idx)))).value))


(define names ["Yoben","Goben","Zoben","Shrapnel"])
(define idx (indexOf "Zoben" names))
(echo (fmt"names[$]=$" idx names[idx]))

