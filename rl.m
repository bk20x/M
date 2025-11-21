(load "test.m")

(define not
 (-> (x) (if (!= x nil) nil t)))


(define Blue '(0 0 255 255))








(open Raylib)

(initWindow 1920 1080 "Test")
(setTargetFps 144)

(define x      50.0)
(define y      50.0)
(define width  256.0)
(define height 256.0)


(while (not (windowShouldClose))
  (do ((beginDrawing)
       (clearBackground 255 0 0 255)
       (if (isKeyDown 'D) (setf x (+ x 10)))
       (if (isKeyDown 'A) (setf x (- x 10)))
       (if (isKeyDown 'W) (setf y (- y 10)))
       (if (isKeyDown 'S) (setf y (+ y 10)))
       (drawRectangle x y width height Blue)
       (endDrawing))))

(closeWindow)
