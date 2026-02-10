(open Math)
(load "class-macro.m")

(class Counter (initval) (
  get (-> () initval)
  inc (-> () (setf initval (+ initval 1)))
  dec (-> () (setf initval (- initval 1)))
))

(define x (Counter 0))
(doTimes 1000 (echo (x.inc)))


(class Vector2 (x y) (
    getX     (-> () x)
    setX     (-> (~x) (setf x ~x))
    getY     (-> () y)
    setY     (-> (~y) (setf y ~y))
    set      (-> (~x ~y) (let () (self.setX ~x) (self.setY ~y)))
    distance (-> (dest)
    		 (let ((dx (- (dest.getX) (self.getX)))
		       (dy (- (dest.getY) (self.getY))))
		   (sqrt (+ (* dx dx) (* dy dy)))))
))


(define point1 (Vector2 25.0 25.0))
(define point2 (Vector2 50.0 50.0))

(echo "Distance: ")
(echo (point1.distance point2))
