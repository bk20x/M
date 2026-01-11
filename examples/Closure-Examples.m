(open Strings)


(define counter (let ((x 0)) (-> () (setf x (+ x 1)))))

(doTimes 10 (echo (counter)))

(define Person (-> (name) {
  getName: (-> () name),
  setName: (-> (newName) (setf name newName)),
  sayHi:   (-> (other) (echo (fmt "Hello $! mi llamo es $" other name)))
}))


(define bobby (Person "Boben"))

(bobby.sayHi 'Yober)

(bobby.setName "Bobenjames")

(bobby.sayHi "Yobert Kringle")



