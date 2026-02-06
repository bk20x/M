(load "class-macro.m")

(class Counter (init) (
  inc (-> () (setf init (+ init 1)))
  dec (-> () (setf init (- init 1)))
  get (-> () init)
  set (-> (x) (setf init x))
))
