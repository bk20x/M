
(macro Type (tVar tName subT _ contract)
 `(define ,tName
   (-> (,tVar)
    (and
    (= (typeOf ,tVar) ',subT)
      ,contract))))

(macro Subtype (tVar tName subT _ contract)
 `(define ,tName
   (-> (,tVar)
    (and
     (,subT ,tVar)
     ,contract))))




(Type a Even Int where (= (mod a 2) 0))

(Type day Monthday Int where (and (> day 0) (> 32 day)))

(Subtype a BigEven Even where (> a 35000))

