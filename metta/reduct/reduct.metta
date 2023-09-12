!(import! &self /usr/local/lib/metta/synthesis/Synthesize.metta)
!(import! &self /usr/local/lib/metta/common/Record.metta)

!(import! &self axioms.metta)

!(import! &self rules.metta)

(= (reduce $depth)
   (let (: $proof (examplar $e))
         (synthesize (: $proof $y) $depth (get-kb) (get-rb))
         (examplar $e)))
