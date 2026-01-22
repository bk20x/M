(open Raylib)

(define not (-> (x) (= x nil)))

(define start (-> (w h)
 (let ()
  (initWindow w h "Yoben!")
  (while (not (windowShouldClose)) (
	(beginDrawing)
         (clearBackground '(255 255 255 255))
	(endDrawing)))
  (closeWindow))))
