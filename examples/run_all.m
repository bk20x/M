(open SysIo)
(each (f (filter (listDir ".") (-> (f) (and (isFile? f) (!= "./run_all.m" f))))) (load f))
