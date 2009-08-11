
(in-package "ACL2")


;; This provides a new macro, defevaluator-fast, which behaves much like
;; defevaluator: from the user perspective, it should be identical; it produces
;; a constrained function with the same set of constraints as the one produced
;; by defevaluator.  However, it is much faster when the list of recognized
;; functions is long.  It can also recognize multi-valued functions and
;; functions with stobjs, because the evaluator is declared non-executable.
;; (From the user perspective, it's a constrained function anyway, so it
;; shouldn't matter.)

;; Some data:

;; The constant *defeval-entries-for-all-reasonable-functions*, defined in a
;; comment at the bottom of this file, contains a list of ~570 function "calls"
;; (such as (cons a b), (foo arg1 arg2), etc.)

;; On one modern (ca. 2009) machine, DEFEVALUATOR-FAST proves the constraints
;; for the evaluator recognizing all the listed functions in 2.2 seconds (when
;; output is turned off.)

;; In comparison, if we redefine DEFEVALUATOR so that it can handle MVs and
;; functions that take stobjs and so that it gives a :DO-NOT '(PREPROCESS) hint
;; to the measure theorem for better performance, it takes 6.0 sec to define an
;; evaluator recognizing the first 40 of these functions, 11.1 sec for the
;; first 50, 28 sec for the first 80, and so on.  (If the :DO-NOT '(PREPROCESS)
;; hint is omitted, then somewhere in the 40s the measure conjecture begins to
;; spend an impractically long time in IF-TAUTOLOGYP, part of preprocessing.)


;; Acknowledgements:  Code ripped liberally from the original defevaluator
;; macro in defthm.lisp (in the ACL2 sources.)

(program)

(defun defevaluator-fast-form/defthms (evfn evfn-lst prefix i clauses)
  (declare (xargs :mode :program))
  (cond ((null clauses) nil)
        (t (let ((thmname (genvar evfn prefix i nil)))
             (list*
              (list*
               (if (eql i 0) 'defthmd 'defthm)
               thmname
               (prettyify-clause (car clauses) nil nil)
               (case i
                 (0
;                   (implies (and (consp x)
;                                 (syntaxp (not (equal a ''nil)))
;                                 (not (equal (car x) 'quote)))
;                            (equal (evfn x a)
;                                   (evfn (cons (car x)
;                                               (kwote-lst (evfn-lst
;                                                           (cdr x) a)))
;                                         nil)))
                  `(:hints
                    (("Goal" :expand
                      ((:free (x) (hide x))
                       (,evfn x a)
                       (:free (args)
                              (,evfn (cons (car x)
                                           args) nil)))))))
                 (1
;                   (implies (symbolp x)
;                            (equal (evfn x a)
;                                   (and x (cdr (assoc-eq x a)))))
                  `(:hints (("goal" :expand ((,evfn x a))))))
                 (2
;                   (implies (and (consp x) (eq (car x) 'quote))
;                            (equal (evfn x a) (cadr x)))
                  `(:hints (("goal" :expand ((,evfn x a))))))
                 (3
;                   (implies (and (consp x) (consp (car x)))
;                            (equal (evfn x a)
;                                   (a-ev (caddar x)
;                                         (pairlis$ (cadar x)
;                                                   (evfn-lst (cdr x) a)))))
                  `(:hints (("goal" :expand ((,evfn x a))))))
                 (4
;                   (implies (not (consp x-lst))
;                            (equal (evfn-lst x-lst a) nil))
                  `(:hints (("goal" :expand ((,evfn-lst x-lst a))))))
                 (5
;                   (implies (consp x-lst)
;                            (equal (evfn-lst x-lst a)
;                                   (cons (evfn (car x-lst) a)
;                                         (evfn-lst (cdr x-lst) a))))
                  `(:hints (("goal" :expand ((,evfn-lst x-lst a))))))
                 (t
;                   (implies (and (consp x)
;                                 (eq (car x) 'foo))
;                            (equal (evfn x a)
;                                   (foo (evfn (cadr x) a)
;                                        ...)))
                  `(:hints (("goal" :expand ((,evfn x a)
                                             (:free (x) (hide x)))))))))
              `(local (in-theory (disable ,thmname)))
              (defevaluator-fast-form/defthms evfn evfn-lst prefix (1+ i)
                (cdr clauses)))))))

(defun evaluator-fast-clause/arglist (formals x)
  (if (atom formals)
      nil
    (cons `(car ,x)
          (evaluator-fast-clause/arglist (cdr formals) `(cdr ,x)))))

(defun defevaluator-fast-form/fns-clauses (fn-args-lst)

; We return a list of cond clauses,
; (
;  ((equal (car x) 'fn1)
;   (fn1 (evfn (cadr x) a) ... (evfn (cad...dr x) a)))
;  ((equal (car x) 'fn2)
;   (fn2 (evfn (cadr x) a) ... (evfn (cad...dr x) a)))
;  ...
;   (t nil))

; containing a clause for each fni in fns plus a final t clause.

  (cond ((null fn-args-lst) '((t nil)))
        (t (cons
            (list (list 'equal '(car x) (kwote (caar fn-args-lst)))
                  (cons (caar fn-args-lst)
                        (evaluator-fast-clause/arglist (cdar fn-args-lst)
                                                       'args)))
            (defevaluator-fast-form/fns-clauses (cdr fn-args-lst))))))

(defconst *defevaluator-fast-form-base-theory*
  (append *definition-minimal-theory*
          '(car-cdr-elim
            car-cons cdr-cons ;; fix-true-list-cdr
            o< o-finp o-first-expt o-first-coeff o-rst natp posp
            acl2-count
            alistp
            fix-true-list kwote kwote-lst pairlis$-fix-true-list
            (:type-prescription acl2-count))))

(defun defevaluator-fast-form (evfn evfn-lst fn-args-lst)
  (declare (xargs :mode :program))
  (let* ((clauses (evaluator-clauses evfn evfn-lst fn-args-lst))
         (fns-clauses (defevaluator-fast-form/fns-clauses fn-args-lst))
         (defthms (defevaluator-fast-form/defthms
                    evfn evfn-lst
                    (symbol-name (pack2 evfn '-constraint-))
                    0
                    clauses)))
    `(encapsulate
      (((,evfn * *) => *)
       ((,evfn-lst * *) => *))
      (set-inhibit-warnings "theory")
      (local (in-theory *defevaluator-fast-form-base-theory*))
      ,@(sublis
         (list (cons 'evfn evfn)
               (cons 'evfn-lst evfn-lst)
               (cons 'fns-clauses fns-clauses)
               (cons 'defthms defthms))
         '((local
            (mutual-recursion
             (defun evfn (x a)
               (declare (xargs :verify-guards nil
                               :measure (acl2-count x)
                               :well-founded-relation o<
                               :non-executable t
                               :mode :logic))
               (cond
                ((symbolp x) (and x (cdr (assoc-eq x a))))
                ((atom x) nil)
                ((eq (car x) 'quote) (car (cdr x)))
                (t (let ((args (evfn-lst (cdr x) a)))
                     (cond
                      ((consp (car x))
                       (evfn (car (cdr (cdr (car x))))
                             (pairlis$ (car (cdr (car x)))
                                       args)))
                      .
                      fns-clauses)))))
             (defun evfn-lst (x-lst a)
               (declare (xargs :measure (acl2-count x-lst)
                               :well-founded-relation o<))
               (cond ((endp x-lst) nil)
                     (t (cons (evfn (car x-lst) a)
                              (evfn-lst (cdr x-lst) a)))))))
           (local (in-theory (disable evfn evfn-lst)))
           (local
            (defthm eval-list-kwote-lst
              (equal (evfn-lst (kwote-lst args) a)
                     (fix-true-list args))
              :hints (("goal"
                       :expand ((:free (x y) (evfn-lst (cons x y) a))
                                (evfn-lst nil a)
                                (:free (x)
                                       (evfn (list 'quote x) a)))
                       :induct (fix-true-list args)))))
           (local
            (defthm fix-true-list-ev-lst
              (equal (fix-true-list (evfn-lst x a))
                     (evfn-lst x a))
              :hints (("goal" :induct (len x)
                       :in-theory (e/d ((:induction len)))
                       :expand ((evfn-lst x a)
                                (evfn-lst nil a))))))
           (local
            (defthm ev-commutes-car
              (equal (car (evfn-lst x a))
                     (evfn (car x) a))
              :hints (("goal" :expand ((evfn-lst x a)
                                       (evfn nil a))
                       :in-theory (enable default-car)))))
           (local
            (defthm ev-lst-commutes-cdr
              (equal (cdr (evfn-lst x a))
                     (evfn-lst (cdr x) a))
              :hints (("Goal" :expand ((evfn-lst x a)
                                       (evfn-lst nil a))
                       :in-theory (enable default-cdr)))))
           . defthms)))))

(defmacro defevaluator-fast (&whole x evfn evfn-lst fn-args-lst)

; Note: It might be nice to allow defevaluator to take a :DOC string, but that
; would require allowing encapsulate to take such a string!

  ":Doc-Section Events

  introduce an evaluator function (but faster.)~/
  ~bv[]
  Example:
  (defevaluator-fast evl evl-list
    ((length x) (member x y)))
  ~ev[]
  ~l[meta].~/
  ~bv[]
  General Form:
  (defevaluator-fast ev ev-list
     ((g1 x1 ... xn_1)
      ...
      (gk x1 ... xn_k))
  ~ev[]
  where ~c[ev] and ~c[ev]-list are new function symbols and ~c[g1], ..., ~c[gk] are
  old function symbols with the indicated number of formals, i.e.,
  each ~c[gi] has ~c[n_i] formals.

  ~l[defevaluator] for more.  Defevaluator-fast is a reimplementation of
  defevaluator, designed to handle larger numbers of recognized functions."

  (cond
   ((not (and (symbolp evfn)
              (symbolp evfn-lst)
              (symbol-list-listp fn-args-lst)))
    `(er soft '(defevaluator . ,evfn)
         "The form of a defevaluator event is (defevaluator evfn ~
          evfn-lst fn-args-lst), where evfn and evfn-lst are symbols ~
          and fn-args-lst is a true list of lists of symbols.  ~
          However, ~x0 does not have this form."
         ',x))
   (t
    (defevaluator-fast-form evfn evfn-lst fn-args-lst))))



(logic)

(local
 ;; A test to show that ACL2 recognizes evaluators defined with
 ;; DEFEVALUATOR-FAST as valid evaluators for meta-reasoning:
 (progn
   (with-output
    :off :all
    (defevaluator-fast foo-ev foo-ev-lst
      ((XXXJOIN FN ARGS)
       (INTEGER-ABS X)
       (OR-MACRO LST)
       (AND-MACRO LST)
       (LIST-MACRO LST)
       (TRUE-LISTP X)
       (EQ X Y)
       (REWRITE-EQUIV X)
       (HIDE X)
       (NOT P)
       (IMPLIES P Q)
       (BOOLEANP X)
       (XOR P Q)
       (IFF P Q)
       (O< X Y)
       (O-P X)
       (SYMBOLP X)
       (SYMBOL-PACKAGE-NAME X)
       (SYMBOL-NAME X)
       (STRINGP X)
       (REALPART X)
       (RATIONALP X)
       (PKG-WITNESS PKG)
       (NUMERATOR X)
       (INTERN-IN-PACKAGE-OF-SYMBOL STR SYM)
       (INTEGERP X)
       (IMAGPART X)
       (IF X Y Z)
       (EQUAL X Y)
       (DENOMINATOR X)
       (CONSP X)
       (CONS X Y)
       (COERCE X Y)
       (COMPLEX-RATIONALP X)
       (COMPLEX X Y)
       (CODE-CHAR X)
       (CHARACTERP X)
       (CHAR-CODE X)
       (CDR X)
       (CAR X)
       (< X Y)
       (UNARY-/ X)
       (UNARY-- X)
       (BINARY-+ X Y)
       (BINARY-* X Y)
       (BAD-ATOM<= X Y)
       (ACL2-NUMBERP X))))

   (defun stupid-cp (x)
     (list x))

   ;; ACL2 recognizes FOO-EV as a valid evaluator:
   (defthm stupid-cp-correct
     (implies (and (pseudo-term-listp cl)
                   (alistp a)
                   (foo-ev
                    (conjoin-clauses (stupid-cp cl))
                    a))
              (foo-ev
               (disjoin cl) a))
     :rule-classes :clause-processor)))









#||

;; Infrastructure for testing this
(defun all-syms-in-world (w)
  (remove-duplicates (strip-cars w)))

(defun logic-function-syms (syms world)
  (if (atom syms)
      nil
    (if (and (not (eq (getprop (car syms) 'formals :none 'current-acl2-world
                               world)
                      :none))
             (member (getprop (car syms) 'symbol-class nil 'current-acl2-world world)
                     '(:ideal :common-lisp-compliant))
             (not (member (car syms)
                          (global-val 'untouchable-fns world)))
             (not (member (car syms) '(synp must-be-equal open-output-channel!))))
        (cons (car syms) (logic-function-syms (cdr syms) world))
      (logic-function-syms (cdr syms) world))))

(defun mk-defeval-entries (fns world)
  (if (atom fns)
      nil
    (let ((formals (getprop (car fns) 'formals nil 'current-acl2-world world)))
      (cons (cons (car fns) formals)
            (mk-defeval-entries (cdr fns) world)))))



(logic)

(make-event
 `(defconst *defeval-entries-for-all-reasonable-functions*
    ',(let ((world (w state)))
        (mk-defeval-entries (logic-function-syms (all-syms-in-world world)
                                                world)
                            world))))



(time$
 (make-event
  `(defevaluator-fast test-defevaluator-fast-ev test-defevaluator-fast-ev-lst
     ,*defeval-entries-for-all-reasonable-functions*)))
;; 2.2 sec with output off, 6.0 sec with output on







;; For comparison, testing with the original defevaluator (plus a couple of
;; trivial mods:)

(defttag blah)

;; Redefining the usual defevaluator so that it uses :non-executable t.
(redef!)

(defun defevaluator-form (evfn evfn-lst fn-args-lst)
  (declare (xargs :mode :program))
  (let* ((clauses (evaluator-clauses evfn evfn-lst fn-args-lst))
         (fns-clauses (defevaluator-form/fns-clauses evfn fn-args-lst))
         (defthms (defevaluator-form/defthms
                    evfn
                    (symbol-name (pack2 evfn '-constraint-))
                    0
                    clauses)))
    `(encapsulate
      (((,evfn * *) => *)
       ((,evfn-lst * *) => *))
      (set-inhibit-warnings "theory")
      (local (in-theory *defevaluator-form-base-theory*))
      ,@(sublis
         (list (cons 'evfn evfn)
               (cons 'evfn-lst evfn-lst)
               (cons 'fns-clauses fns-clauses)
               (cons 'defthms defthms))
         '((local
            (mutual-recursion
             (defun evfn (x a)
               (declare (xargs :verify-guards nil
                               :measure (acl2-count x)
                               :well-founded-relation o<
; MODIFIED: Make the evaluator non-executable so it can handle stobjs and mvs
                               :non-executable t
                               :mode :logic
; MODIFIED: Prevent preprocessing in the measure theorem to eliminate a drastic
; slowdown.
                               :hints (("Goal" :do-not '(preprocess)))))
               (cond
                ((symbolp x) (and x (cdr (assoc-eq x a))))
                ((atom x) nil)
                ((eq (car x) 'quote) (car (cdr x)))
                ((consp (car x))
                 (evfn (car (cdr (cdr (car x))))
                       (pairlis$ (car (cdr (car x)))
                                 (evfn-lst (cdr x) a))))
                .
                fns-clauses))
             (defun evfn-lst (x-lst a)
               (declare (xargs :measure (acl2-count x-lst)
                               :well-founded-relation o<))
               (cond ((endp x-lst) nil)
                     (t (cons (evfn (car x-lst) a)
                              (evfn-lst (cdr x-lst) a)))))))
           (local
            (defthm eval-list-kwote-lst
              (equal (evfn-lst (kwote-lst args) a)
                     (fix-true-list args))))
           . defthms)))))

(set-inhibit-output-lst '(proof-tree prove event expansion))

(time$ 
 (make-event
  `(defevaluator test-defevaluator-ev test-defevaluator-ev-lst
     ,(take 80 *defeval-entries-for-all-reasonable-functions*))))


(defthm fix-true-list-test-defevaluator-fast-ev-lst
  (equal (fix-true-list (test-defevaluator-fast-ev-lst x a))
         (test-defevaluator-fast-ev-lst x a))
  :hints (("goal" :induct (len x)
           :in-theory (e/d ((:induction len))
                           (test-defevaluator-fast-ev-commutes-car)))))

(defthm test-defevaluator-fast-ev-commutes-car
  (equal (test-defevaluator-fast-ev (car x) a)
         (car (test-defevaluator-fast-ev-lst x a))))

(defthm test-defevaluator-fast-ev-lst-commutes-cdr
  (equal (cdr (test-defevaluator-fast-ev-lst x a))
         (test-defevaluator-fast-ev-lst (cdr x) a))
  :hints(("Goal" :in-theory (disable test-defevaluator-fast-ev-commutes-car))))

||#
