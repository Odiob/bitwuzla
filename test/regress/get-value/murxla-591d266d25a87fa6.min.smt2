(set-logic QF_BVFP)
(set-info :status sat)
(set-info :status sat)
(set-option :produce-models true)
; Querying the value of a partial operator word-blasts it on demand. Make sure
; that querying it again after the model cache was invalidated by another
; check-sat still yields the same value.
(define-fun f () (_ FloatingPoint 8 24) ((_ to_fp 8 24) RTZ (_ bv3 8)))
(check-sat)
(get-value (((_ fp.to_sbv 8) RTZ f) ((_ fp.to_ubv 8) RTZ f)))
(check-sat)
(get-value (((_ fp.to_sbv 8) RTZ f) ((_ fp.to_ubv 8) RTZ f)))
(exit)
