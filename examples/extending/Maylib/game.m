(open Raylib)


(define not (-> (x) (= x nil)))


(initWindow 800 600 "Hello From M!")
(setTargetFPS 60)

(while (not (windowShouldClose))
  ((beginDrawing)
     (clearBackground {r: 255, g: 255, b: 255, a: 255})
     (drawRectangle 150 150 256 256 {r: 255, g: 0, b: 125, a: 255})
   (endDrawing)))


(closeWindow)
