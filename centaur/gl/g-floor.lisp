
(in-package "GL")

(include-book "g-if")
(include-book "g-primitives-help")
(include-book "symbolic-arithmetic-fns")
(include-book "eval-g-base")
;(include-book "tools/with-arith5-help" :dir :system)
(local (include-book "symbolic-arithmetic"))
(local (include-book "eval-g-base-help"))
(local (include-book "hyp-fix-logic"))
;(local (allow-arith5-help))

(defun g-floor-of-numbers (x y)
  (declare (xargs :guard (and (gobjectp x)
                              (general-numberp x)
                              (gobjectp y)
                              (general-numberp y))))
  (b* (((mv xrn xrd xin xid)
        (general-number-components x))
       ((mv yrn yrd yin yid)
        (general-number-components y)))
    (if (and (eq (=-uu xrd '(t)) t)
             (eq (=-uu yrd '(t)) t)
             (eq (bfr-or (=-ss xin nil)
                       (=-uu xid nil)) t)
             (eq (bfr-or (=-ss yin nil)
                       (=-uu yid nil)) t))
        (mk-g-number (floor-ss xrn yrn))
      (g-apply 'floor (list x y)))))

(in-theory (disable (g-floor-of-numbers)))

(local
 (defthm gobjectp-g-floor-of-numbers
   (implies (and (gobjectp x)
                 (general-numberp x)
                 (gobjectp y)
                 (general-numberp y))
            (gobjectp (g-floor-of-numbers x y)))))

(local (include-book "arithmetic/top-with-meta" :dir :system))

(local (defthm not-integerp-floor-ss
         (implies (and (bfr-listp a) (bfr-listp b))
                  (not (integerp (floor-ss a b))))
         :hints (("goal" :use ((:instance bfr-listp-floor-ss))
                  :in-theory (e/d (bfr-listp) (bfr-listp-floor-ss))))))

(local (add-bfr-fn-pat =-uu))
(local (add-bfr-fn-pat =-ss))

(local
 (defthm g-floor-of-numbers-correct
   (implies (and (gobjectp x)
                 (general-numberp x)
                 (gobjectp y)
                 (general-numberp y))
            (equal (eval-g-base (g-floor-of-numbers x y) env)
                   (floor (eval-g-base x env)
                          (eval-g-base y env))))
   :hints (("goal" :in-theory
            (e/d* ((:ruleset general-object-possibilities))
                  (general-numberp
                   general-number-components
                   floor))
            :do-not-induct t)
           (bfr-reasoning))))

(in-theory (disable g-floor-of-numbers))




(def-g-binary-op floor
  (b* ((i-num (if (general-numberp i) i 0))
       (j-num (if (general-numberp j) j 0)))
    (g-floor-of-numbers i-num j-num)))

(def-gobjectp-thm floor
  :hints `(("goal" :in-theory (e/d* (general-concretep-atom)
                                    ((:definition ,gfn)
                                     (force)
                                     general-concretep-def
                                     hyp-fix
                                     gobj-fix-when-not-gobjectp
                                     gobj-fix-when-gobjectp
                                     (:rules-of-class :type-prescription :here)
                                     (:ruleset gl-wrong-tag-rewrites)))
            :induct (,gfn i j hyp clk)
            :do-not-induct t
            :expand ((,gfn i j hyp clk)
                     (gobjectp (floor (gobj-fix i) (gobj-fix j)))))))

(verify-g-guards
 floor
 :hints `(("goal" :in-theory
           (disable* ,gfn bfr-p-of-boolean
                     (:rules-of-class :type-prescription :here)
                     (:ruleset gl-wrong-tag-rewrites)))))

(local (defthm floor-when-not-numberp
         (and (implies (not (acl2-numberp i))
                       (equal (floor i j) (floor 0 j)))
              (implies (not (acl2-numberp j))
                       (equal (floor i j) (floor i 0))))))

(def-g-correct-thm floor eval-g-base
  :hints
  `(("goal" :in-theory (e/d* (general-concretep-atom
                              (:ruleset general-object-possibilities))
                             ((:definition ,gfn)
                              tag-when-g-boolean-p
                              tag-when-g-apply-p
                              tag-when-g-concrete-p
                              tag-when-g-var-p
                              general-numberp-eval-to-numberp
                              general-boolean-value-correct
                              bool-cond-itep-eval
                              general-consp-car-correct-for-eval-g-base
                              general-consp-cdr-correct-for-eval-g-base
                              boolean-listp
                              components-to-number-alt-def
                              member-equal bfr-p-of-boolean
                              general-number-components-ev
                              general-concretep-def
                              v2n-is-v2i-when-sign-nil
                              general-concretep-def
                              floor
                              hons-assoc-equal
                              rationalp-implies-acl2-numberp
                              (:rules-of-class :type-prescription :here))
                             ((:type-prescription bfr-eval)))
     :induct (,gfn i j hyp clk)
     :do-not-induct t
     :expand ((,gfn i j hyp clk)))
    (and stable-under-simplificationp
         (flag::expand-calls-computed-hint
          clause '(eval-g-base)))))