(define makeCounter (-> ()
  (let ((x 0)) {
    inc: (-> () (setf x (+ x 1))),
    dec: (-> () (setf x (- x 1)))
})))
