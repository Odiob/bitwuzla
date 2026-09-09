; Only a subset of the variables of a quantifier prefix can be eliminated,
; the remaining ones must stay bound.
(set-logic BV)
(set-info :status unsat)
(declare-const t (_ BitVec 8))
(assert (forall ((x (_ BitVec 8)) (y (_ BitVec 8)) (z (_ BitVec 8)))
  (or (not (= (bvadd z t) #b00000000)) (= (bvadd x y) t))))
(check-sat)
