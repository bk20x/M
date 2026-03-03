(open SysIo Strings)
(load "prelude/Prelude.m")

(while t (
  (try (eval (~read (input)))
    (echo (concat "=> "     (image result.value)))
    (echo (concat "Error: " (image result.value))))
))
