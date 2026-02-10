(open Strings)


(define counter (let ((x 0)) (-> () (setf x (+ x 1)))))

(doTimes 10 (echo (counter)))

(define Person (-> (name) {
  getName: (-> () name),
  setName: (-> (newName) (setf name newName)),
  sayHi:   (-> (other) (echo (fmt "Hello $! my name is $" (other.getName) name)))
}))


(define terry (Person "Terry Davis"))

(define bobby (Person "Bobby Boben"))

(terry.sayHi bobby)
(bobby.sayHi terry)


