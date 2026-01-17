(define Counter (-> (x) {
    inc: (-> () (setf x (+ x 1))),
    dec: (-> () (setf x (- x 1))),
    get: (-> () x)
}))

(define makeCounter (-> () (let ((x 0)) (Counter x))))

