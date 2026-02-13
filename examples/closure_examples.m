(open Math Strings)


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
(terry.sayHi {
  getName: (-> () "Gambas")
})


(define Vector2 (-> (x y)
  {
    getX: (-> () x),
    getY: (-> () y),
    setX: (-> (~x) (setf x ~x)),
    setY: (-> (~y) (setf y ~y)),
    distance: (-> (dest) 
      (let ((dx (- (dest.getX) x))
            (dy (- (dest.getY) y))) 
	    (sqrt (+ (* dx dx) (* dy dy))))),
    image: (-> () (fmt "(x: $; y: $)" x y))
  }
))


(define p1 (Vector2 57.7 98.243))
(define p2 (Vector2 99.21 33.8))
(echo (p1.distance p2))

(echo (p1.image))

