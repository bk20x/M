(open SysIo Strings)
(load "prelude/Prelude.m")

(while t (
  (try (eval (~read (input)))
	(echo (strConcat "=> "     (image result.value)))
	(echo (strConcat "Error: " (image result.value))))
))
