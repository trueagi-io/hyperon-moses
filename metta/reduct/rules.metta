(: chain-reduction-rule (-> Atom))
(: recurse-reduction-rule (-> Atom))
(: commutative-reduction-rule (-> Atom))

(= (chain-reduction-rule)
   (: ChainReduction
      (-> (examplar $a)
          (reduced $a $b)
          (examplar $b)))
)

(= (commutative-reduction-rule)
   (: CommutativeReduction
      (-> (reduced (andd $b $c) $r)
            (is-commutative andd)
            (reduced (andd $c $b) $r)))
)

(= (commutative-reduction-rule)
   (: CommutativeReduction
      (-> (reduced (orr $b $c) $r)
            (is-commutative orr)
            (reduced (orr $c $b) $r)))
)

(= (recurse-reduction-rule)
   (: RecurseReduction
      (-> (examplar (orr $b $c))
            (reduced $c $rc)
            (reduced (orr $b $c) (orr $b $rc))))
)

(= (recurse-reduction-rule)
   (: RecurseReduction
      (-> (examplar (orr $c $b))
            (reduced $c $rc)
            (reduced (orr $c $b) (orr $rc $b))))
)

(= (recurse-reduction-rule)
   (: RecurseReduction
      (-> (examplar (andd $b $c))
            (reduced $c $rc)
            (reduced (andd $b $c) (andd $b $rc))))
)

(= (recurse-reduction-rule)
   (: RecurseReduction
      (-> (examplar (andd $c $b))
            (reduced $c $rc)
            (reduced (andd $c $b) (andd $rc $b))))
)

(: rb (-> Atom))
(= (rb) (superpose ((chain-reduction-rule) 
                     (recurse-reduction-rule)
                     (commutative-reduction-rule))))

(= (get-rb) rb)
