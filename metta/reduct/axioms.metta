(= (add-examplar $e) 
    (add-atom &self $e))

(= (get-examplar) (match &self (examplar $x) (examplar $x)))

(: kb (-> Atom))

(= (kb) (superpose ((: examplar_1 (get-examplar))
                (: identity_and_true_red (reduced (andd $y True) $y))
                (: identity-and-false-red (reduced (andd $y False) False))
                (: identity_or_false_red (reduced (orr $y False) $y))
                (: andd-is-commutative (is-commutative andd))
                (: orr-is-commutative (is-commutative orr))
                (: double-not (reduced (nott (nott $x)) $x)))))

(= (get-kb) kb)
