(open Math Strings)

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
(let ()
 (echo (p1.image))
 (echo (p2.image)))
