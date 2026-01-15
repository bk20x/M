(open Math)

(define Vector2 (-> (x y)
  {
    getX: (-> () x),
    getY: (-> () y),
    setX: (-> (~x) (setf x ~x)),
    setY: (-> (~y) (setf y ~y)),
    distance: (-> (dest) 
      (let ((dx (- (dest.getX) x))
            (dy (- (dest.getY) y))) 
	    (sqrt (+ (* dx dx) (* dy dy))))
    )
  }
))
