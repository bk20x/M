(open SysIo)
(load "Prelude.m")

(define readDir (-> (dir)
 (collectIf isFile? (file (listDir dir)) (readFile file))))


(define contents (readDir "."))
(define x 0)
(each (c contents) (setf x (+ x 1)))
(echo x)
