
(in-package "GL")

(include-book "gtypes")

(include-book "gobjectp-thms")


;; -------------------------
;; Concrete-gobjectp
;; -------------------------

(defun concrete-gobjectp-ind (x)
  (if (atom x)
      x
    (and (not (g-concrete-p x))
         (not (g-boolean-p x))
         (not (g-number-p x))
         (not (g-ite-p x))
         (not (g-apply-p x))
         (not (g-var-p x))
         (list (concrete-gobjectp-ind (car x))
               (concrete-gobjectp-ind (cdr x))))))
    

(defthm concrete-gobjectp-def
  (equal (concrete-gobjectp x)
         (if (atom x)
             (not (g-keyword-symbolp x))
           (and (not (g-concrete-p x))
                (not (g-boolean-p x))
                (not (g-number-p x))
                (not (g-ite-p x))
                (not (g-apply-p x))
                (not (g-var-p x))
                (concrete-gobjectp (car x))
                (concrete-gobjectp (cdr x)))))
  :hints (("goal" :induct (concrete-gobjectp-ind x)
           :expand ((gobject-hierarchy x))
           :in-theory
           (e/d*
            (concrete-gobjectp)
            (gobject-hierarchy 
             (:rules-of-class :type-prescription :here)
             equal-of-booleans-rewrite
             gobjectp-tag-rw-to-types
             not-g-keyword-symbol-when-not-symbol
             default-car gobjectp-def default-cdr
             not gobjectp-apply-case atom
             gobjectp-number-case
             gobjectp-boolean-case
             (:ruleset gl-wrong-tag-rewrites)
             (:ruleset gl-tag-forward)
             ;; Jared: I got rid of these.
             ;;g-var-p-forward-to-consp
             ;;g-apply-p-forward-to-consp
             ;;g-ite-p-forward-to-consp
             ;;g-number-p-forward-to-consp
             ;;g-boolean-p-forward-to-consp
             ;;g-concrete-p-forward-to-consp
             iff-implies-equal-not
             )))
          ("Subgoal *1/2"
           :use ((:instance gobject-hierarchy-possibilities
                            (x (cdr x)))
                 (:instance gobject-hierarchy-possibilities
                            (x (car x))))))
  :rule-classes :definition)


(defthmd concrete-gobjectp-gobjectp
  (implies (concrete-gobjectp x)
           (gobjectp x))
  :hints(("Goal" :in-theory
          (enable concrete-gobjectp gobjectp))))

(defthmd eval-concrete-gobjectp
  (implies (concrete-gobjectp x)
           (equal (generic-geval x env) x))
  :hints (("goal" :induct (concrete-gobjectp-ind x)
           :expand ((generic-geval x env))
           :in-theory
           (e/d** (generic-geval
                   concrete-gobjectp-ind
                   gobjectp-tag-rw-to-types
                   concrete-gobjectp-gobjectp
                   concrete-gobjectp-def
                   gobj-fix-when-gobjectp
                   acl2::cons-car-cdr)))))

(in-theory (disable concrete-gobjectp-def))






(defthm gobjectp-mk-g-concrete
  (gobjectp (mk-g-concrete x))
  :hints (("goal" :in-theory
           (enable gobjectp gobject-hierarchy mk-g-concrete
                   concrete-gobjectp-def))))


(defthm gobjectp-g-concrete
  (gobjectp (g-concrete x))
  :hints(("Goal" :in-theory
          (enable gobjectp gobject-hierarchy))))

(defthm mk-g-concrete-correct
  (equal (generic-geval (mk-g-concrete x) b)
         x)
  :hints(("Goal" :in-theory
          (enable eval-concrete-gobjectp
                  mk-g-concrete))))





(defthm gobjectp-g-ite
  (implies (and (gobjectp x)
                (gobjectp y)
                (gobjectp c))
           (gobjectp (g-ite c x y)))
  :hints(("Goal" :in-theory (enable gobjectp gobject-hierarchy))))


(defthm gobjectp-mk-g-ite
  (gobjectp (mk-g-ite c x y))
  :hints(("Goal" :in-theory (enable mk-g-ite))))

(encapsulate nil
  (local
   (defthm generic-geval-equal-when-gobj-fix-equal
     (implies (equal (gobj-fix x) (gobj-fix y))
              (equal (equal (generic-geval x b)
                            (generic-geval y b))
                     t))
     :hints (("goal" :expand ((generic-geval x b)
                              (generic-geval y b))))))
  (defthm mk-g-ite-correct
    (equal (generic-geval (mk-g-ite c x y) b)
           (if (generic-geval c b)
               (generic-geval x b)
             (generic-geval y b)))
    :hints(("Goal" :in-theory (enable mk-g-ite)
            :do-not-induct t)
           (and stable-under-simplificationp
                '(:expand ((generic-geval c b)))))
    :otf-flg t))




(defthm gobjectp-g-boolean
  (implies (bfr-p x)
           (gobjectp (g-boolean x)))
  :hints(("Goal" :in-theory (enable gobjectp gobject-hierarchy))))


(defthm booleanp-gobjectp
  (implies (booleanp x)
           (gobjectp x))
  :hints (("goal" :in-theory (enable booleanp))))

(defthm gobjectp-mk-g-boolean
  (gobjectp (mk-g-boolean x))
  :hints(("Goal" :in-theory (enable mk-g-boolean))))

(defthm mk-g-boolean-correct
  (equal (generic-geval (mk-g-boolean x) env)
         (bfr-eval x (car env)))
  :hints(("Goal" :in-theory (enable mk-g-boolean))))

(in-theory (disable booleanp-gobjectp))




;; (defthm car-mk-g-number
;;   (implies (consp (mk-g-number a b c d e f))
;;            (eq (car (mk-g-number a b c d e f)) :g-number)))


(defthm mk-g-number-gobjectp
  (implies (and (or (bfr-listp rnum) (integerp rnum))
                (or (bfr-listp rden) (natp rden))
                (or (bfr-listp inum) (integerp inum))
                (or (bfr-listp iden) (natp iden)))
           (gobjectp (mk-g-number rnum rden inum iden)))
  :hints (("goal" :in-theory
           (e/d* (wf-g-numberp gobjectp-def mk-g-number)
                 (n2v i2v bfr-p bfr-listp
                      default-car default-cdr
                      (:ruleset gl-wrong-tag-rewrites)
                      (:ruleset gl-tag-rewrites)
                      (:rules-of-class :type-prescription :here)
                      equal-of-booleans-rewrite
                      default-<-1 default-<-2
                      default-*-1 default-*-2
                      rationalp-implies-acl2-numberp)
                 (g-concrete-p-when-wrong-tag
                  g-boolean-p-when-wrong-tag
                  (:type-prescription components-to-number-fn))))))

(defthm nonzero-natp-implies-us
  (implies (and (natp x) (not (eql x 0)))
           (n2v x))
  :hints(("Goal" :in-theory (enable n2v))))

(encapsulate nil
  (local (include-book "arithmetic/top-with-meta" :dir :system))
  (local (in-theory (enable components-to-number-fn)))
  (defthm components-to-number-norm-zeros1
    (implies (syntaxp (not (equal iden ''1)))
             (equal (components-to-number rnum rden 0 iden)
                    (components-to-number rnum rden 0  1))))

  (defthm components-to-number-norm-zeros2
    (implies (syntaxp (not (equal inum ''0)))
             (equal (components-to-number rnum rden inum 0)
                    (components-to-number rnum rden 0    1))))

  (defthm components-to-number-norm-zeros3
    (implies (syntaxp (not (equal rden ''1)))
             (equal (components-to-number 0 rden inum iden)
                    (components-to-number 0 1    inum iden))))
  (defthm components-to-number-norm-zeros4
    (implies (syntaxp (not (equal rnum ''0)))
             (equal (components-to-number rnum 0    inum iden)
                    (components-to-number 0    1    inum iden))))
  
  (defthm components-to-number-alt-def
    (equal (components-to-number rnum rden inum iden)
           (complex (* rnum (/ rden))
                    (* inum (/ iden))))
    :rule-classes :definition)

  (defthm components-to-number-correct
    (implies (acl2-numberp x)
             (equal (components-to-number (numerator (realpart x))
                                          (denominator (realpart x))
                                          (numerator (imagpart x))
                                          (denominator (imagpart x)))
                    x))
    :hints (("goal" :in-theory (enable components-to-number-alt-def)))))



(defthm bfr-eval-booleanp
  (implies (booleanp x)
           (equal (bfr-eval x env) x))
  :hints (("goal" :in-theory (enable bfr-eval)))
  :rule-classes ((:rewrite :backchain-limit-lst 0)))



(defthm generic-geval-non-gobjectp
  (implies (not (gobjectp x))
           (equal (generic-geval x env) x))
  :hints(("Goal" :in-theory (enable gobj-fix))))

(defthm generic-geval-gobj-fix
  (equal (generic-geval (gobj-fix x) env)
         (generic-geval x env))
  :hints(("Goal" :in-theory (enable gobj-fix))))
                         


(encapsulate nil
  (local (include-book "arithmetic/top-with-meta" :dir :system))
  (local (in-theory 
          (e/d*
           (boolean-list-bfr-eval-list)
           (generic-geval mk-g-number
; (components-to-number)
                          components-to-number
                          gobjectp-def
                          components-to-number-alt-def
                          bfr-eval bfr-eval-list natp v2n
                          n2v i2v default-car default-cdr
                          (:rules-of-class :type-prescription :here)
                          acl2::cancel_times-equal-correct
                          acl2::cancel_plus-equal-correct
                          equal-of-booleans-rewrite
                          (:ruleset gl-tag-rewrites)
                          default-+-2 default-+-1 acl2::natp-rw
                          generic-geval-non-gobjectp
                          gobj-fix-when-not-gobjectp
                          len))))
  (local (defthm len-open-cons
           (equal (len (cons x y))
                  (+ 1 (len y)))
           :hints(("Goal" :in-theory (enable len)))))
  (defthm mk-g-number-correct
    (flet ((to-nat (n env) (if (natp n) n (v2n (bfr-eval-list n (car env)))))
           (to-int (n env) (if (integerp n) n (v2i (bfr-eval-list n (car
                                                                     env))))))
      (implies (gobjectp (mk-g-number rnum rden inum iden))
               (equal (generic-geval (mk-g-number rnum rden inum iden) env)
                      (components-to-number (to-int rnum env)
                                            (to-nat rden env)
                                            (to-int inum env)
                                            (to-nat iden env)))))
    :hints (("Goal" :do-not preprocess)
            '(:cases ((and (integerp rnum) (natp rden)
                           (integerp inum) (natp iden))))
            '(:expand ((:free (a c d f)
                              (mk-g-number a c d f))))
            '(:expand ((:free (a b)
                              (generic-geval
                               (complex a b) env))
                       (:free (x)
                              (generic-geval
                               (g-number x) env))))
            (and stable-under-simplificationp
                 '(:in-theory (e/d (components-to-number-alt-def natp)))))))






;; -------------------------
;; Cons
;; -------------------------



(defthm gobjectp-cons
  (implies (and (gobjectp x) (gobjectp y))
           (gobjectp (cons x y)))
  :hints (("goal" :expand ((:with gobjectp-def
                                  (gobjectp (cons x y)))
                           (g-boolean-p (cons x y))
                           (g-number-p (cons x y))
                           (g-concrete-p (cons x y))
                           (g-ite-p (cons x y))
                           (g-var-p (cons x y))
                           (g-apply-p (cons x y))
                           (tag (cons x y)))
           :do-not-induct t
           :in-theory (disable (force)))))


(defthm generic-geval-cons
  (implies (and (gobjectp x)
                (gobjectp y))
           (equal (generic-geval (cons x y) env)
                  (cons (generic-geval x env)
                        (generic-geval y env))))
  :hints (("goal" :expand ((generic-geval (cons x y) env))
           :in-theory (e/d (tag)))))

(defthm generic-geval-non-cons
  (implies (not (consp x))
           (equal (generic-geval x env) x))
  :hints (("goal" :expand ((:with generic-geval (generic-geval x env))
                           (gobj-fix x))
           :do-not-induct t))
  :rule-classes ((:rewrite :backchain-limit-lst 0)))

(defthm gobjectp-gl-cons
  (gobjectp (gl-cons x y)))

(defthm generic-geval-gl-cons
  (equal (generic-geval (gl-cons x y) env)
         (cons (generic-geval x env)
               (generic-geval y env))))

(in-theory (disable gl-cons))



;; -------------------------
;; Apply
;; -------------------------


(defthm gobjectp-g-apply
  (implies (and (symbolp fn)
                (gobjectp args))
           (gobjectp (g-apply fn args)))
  :hints (("goal" :expand ((gobjectp (g-apply fn args))))))


(defthm gobjectp-g-apply->args
  (implies (and (gobjectp x)
                (g-apply-p x))
           (gobjectp (g-apply->args x)))
  :hints(("Goal" :in-theory (e/d (gobjectp) ((force))))))


(defthm generic-geval-g-apply
  (implies (gobjectp (g-apply fn args))
           (equal (generic-geval (g-apply fn args) env)
                  (apply-stub fn (generic-geval args env))))
  :hints (("goal" :expand ((generic-geval (g-apply fn args) env)))))

(defthmd generic-geval-g-apply-p
  (implies (and (g-apply-p x)
                (gobjectp x))
           (equal (generic-geval x env)
                  (apply-stub (g-apply->fn x)
                              (generic-geval (g-apply->args x) env))))
  :hints (("goal" :expand ((generic-geval x env))))
  :rule-classes ((:rewrite :backchain-limit-lst (0 nil))))

