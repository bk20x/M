import reader, lispobject, environment, tables






var env = newEnv()






env.eval (parse """
     (if t (putLn "yo") (putLn "in elt"))
""")




