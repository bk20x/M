(open Math Strings)

(define Vector2 {
  new     : (-> (x y) {x: x, y: y}),
  distance: (-> (src dest) (let* ((dx (- dest.x src.x))
			          (dy (- dest.y src.y)))
		            (sqrt (+ (* dx dx) (* dy dy)))))
})


(define p1 (Vector2.new 25.0 25.0))

(define p2 (Vector2.new 50.0 75.0))

(echo (fmt "p1=$ p2=$ ;; the distance between them is $" p1 p2 (Vector2.distance p1 p2)))



