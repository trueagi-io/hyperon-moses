!(import! &self ../reduct/reduct.metta)


!(add-examplar (examplar (andd (nott (nott (andd x True))) (andd y False))))

!(reduce (fromNumber 4))
