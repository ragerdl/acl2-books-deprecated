#|-*-Lisp-*-=================================================================|#
#|                                                                           |#
#| coi: Computational Object Inference                                       |#
#|                                                                           |#
#|===========================================================================|#
(in-package "GACC")

;; bzo Is "mem" an okay name for this book?

;; This file, mem.lisp, includes the defrecord event which introduces the
;; functions RD, and WR for atomic reads and writes to a memory.  All the
;; other functions for reading and writing to a memory are just fancy ways to
;; call RD and WR.

;; Try "pick a point" proofs to show that two rams are equal
;; by showing that they agree on a lookup of an arbitrary address.

(include-book "defrecord" :dir :records)

;basically just includes a bunch of super-ihs stuff:
;(include-book "bits")
(include-book "loghead" :dir :super-ihs) 
(include-book "unsigned-byte-p" :dir :super-ihs) 

(local (in-theory (disable ACL2::LOGCAR-0-REWRITE)))

;; Recognizer for the "atomic" elements stored in the memory.
;was called wint8
(defmacro usbp8 (v)
  `(acl2::unsigned-byte-p 8 ,v))

;; "Fix" function to chop things down to match the type of the elements of the
;; memory.
;was called wfix8
;the ifix is to satisfy the guard of loghead.
;;
(defmacro loghead8 (v)
  `(acl2::loghead 8 (ifix ,v)))

;;This is a nonsense function that we can associate with the name loghead8, so
;;that the defrecord doesn't give an error when it tries to mention loghead8 in
;;theory expressions.
;;
(defun loghead8-rune (v)
  (declare (type t v))
  v)

(add-macro-alias loghead8 loghead8-rune)

;; This causes RD and WR to be defined and proves lots of lemmas about them.
;; perhaps we should use names other than RD and WR (rd8 and wr8? rd-byte and
;; wr-byte?)?
;;
(acl2::defrecord memory
                 :rd    rd
                 :wr    wr
                 :typep usbp8
                 :fix   loghead8
                 )

;; usbp8-rd is generated by the defrecord, but we'll use unsigned-byte-p-of-rd
;; instead.
;;
(in-theory (disable usbp8-rd))

(defthm usbp8-of-rd-forward-chaining
  (acl2::unsigned-byte-p 8 (rd a ram))
  :rule-classes ((:forward-chaining :trigger-terms ((rd a ram))))
  :hints (("Goal" :in-theory (enable usbp8-rd))))

(defthm unsigned-byte-p-of-rd
  (implies (<= 8 n)
           (equal (acl2::unsigned-byte-p n (rd a ram))
                  (integerp n))))

;; See also RD-SAME-WR-HYPS and RD-DIFF-WR-HYPS.  We could leave
;; RD-OF-WR-REDUX disabled if it turns out to be expensive.
;;
(in-theory (enable rd-of-wr-redux))

;; Adding this in case we want to disable RD-SAME-WR-HYPS (in which case, we
;; should enable this rule).
;;
(defthmd rd-same-wr-hyps-cheap
  (equal (rd acl2::a (wr acl2::a acl2::v acl2::r))
         (loghead8 acl2::v)))

;bzo Should the defrecord automatically give us any of the theorems in this book?


;; See also WR-SAME-WR-HYPS and WR-DIFF-WR-HYPS.  We could disable
;; wr-of-wr-both if it turns out to be expensive (but knowing whether nested
;; writes affect the same key or different keys seems like a fundamental piece
;; of knowledge, so maybe this rules is okay or even good).
;;
(defthm wr-of-wr-both
  (equal (wr b y (wr a x r))
         (if (equal a b)
             (wr b y r)
           (wr a x (wr b y r))))
  :rule-classes ((:rewrite :loop-stopper ((b a wr)))))

;; Adding this in case we want to disable WR-SAME-WR-HYPS (in which case, we
;; should enable this rule).
;;
(defthmd wr-same-wr-hyps-cheap
  (equal (wr acl2::a acl2::y (wr acl2::a acl2::x acl2::r))
         (wr acl2::a acl2::y acl2::r)))

(encapsulate
 ()
 (local (defthmd wr-of-loghead8
          (equal (wr a (loghead8 v) ram)
                 (wr a v ram))))
 
 (defthm wr-of-loghead
   (implies (and (<= 8 size)
                 (integerp size))
            (equal (wr a (acl2::loghead size v) ram)
                   (wr a v ram)))
   :hints (("Goal" ;:in-theory (enable wr-of-loghead8)
            :in-theory (disable WR==WR)
            :use ((:instance wr-of-loghead8)
                  (:instance wr-of-loghead8 (v (acl2::loghead size v))))))))

(defthm rd-integerp-rewrite
  (integerp (rd addr ram))
  :hints (("Goal" :in-theory (enable rd))))

(defthm rd-integerp-type-prescription
  (integerp (rd addr ram))
  :rule-classes :type-prescription
  :hints (("Goal" :in-theory (enable rd))))

(defthm rd-non-negative
  (<= 0 (rd addr ram))
  :hints (("Goal" :expand (WF-usbp8 (G ADDR RAM))
           :in-theory (enable rd wf-usbp8))))

(defthm rd-non-negative-type-prescription
  (<= 0 (rd addr ram))
  :rule-classes :type-prescription
  :hints (("Goal" :expand (WF-usbp8 (G ADDR RAM))
           :in-theory (enable rd wf-usbp8))))

(defthm rd-non-negative-linear
  (<= 0 (rd addr ram))
  :rule-classes :linear
  :hints (("Goal" :expand (WF-usbp8 (G ADDR RAM))
           :in-theory (enable rd wf-usbp8))))


;; This rule will never fire.
;; (equal (wr ) (wr )) is reduced.
;; v2 and v2 are free variables.
(defthmd wr-equal-differential-one
  (implies (and (equal (wr a v1 ram1)
                       (wr a v2 ram2))
                (not (equal ram1 ram2)))
           (equal (equal (rd a ram1) (rd a ram2))
                  nil)))

(defthm clr-equal-differential-one
  (implies (and (equal (memory-clr a ram1)
                       (memory-clr a ram2))
                (not (equal ram1 ram2)))
           (equal (equal (rd a ram1) (rd a ram2))
                  nil))
  :hints (("goal" :in-theory '(memory-clr wr-equal-differential-one))))

;; This rule will never fire.
;; (equal (wr ) (wr )) is reduced.
; a is a free variable
(defthmd wr-equal-differential-two
  (implies (and (equal (wr a v1 ram1)
                       (wr a v2 ram2))
                (not (equal ram1 ram2)))
           (equal (equal (acl2::loghead 8 v1) (acl2::loghead 8 v2))
                  t)))

;bzo improve?
(defthm loghead-of-rd
  (equal (acl2::loghead 8 ;wfixn 8 1 
                        (rd a ram))
         (rd a ram))
  :hints (("goal" :in-theory (enable ;open-wfixw ;wfixn
                                     ))))

;loop stopper?
(defthm wr-of-wr-same-value
  (equal (wr x val (wr y val ram))
         (wr y val (wr x val ram)))
  :hints (("Goal" :cases ((equal x y)))))

(defthm wr-equality 
  (implies (equal (wr off val1 ram1) ;val1 is a free variable
                  (wr off val1 ram2)) 
           (equal (equal (wr off val2 ram1) (wr off val2 ram2))
                t))
  :hints (("Goal" :in-theory (enable wr==r!))))

(include-book "syntaxp" :dir :util)

(defthm rd-subst-when-wr-equal
  (implies (and (equal (wr b val ram1) (wr b val ram2))
                (syntaxp (acl2::smaller-term ram2 ram1))
                (not (equal a b)))
           (equal (rd a ram1) 
                  (rd a ram2)))
  :hints (("Goal" :in-theory (disable RD-OF-WR-REDUX WR==R!)
           :use ((:instance RD-OF-WR-REDUX (acl2::a a) (acl2::b b) (acl2::v val) (acl2::r ram1))
                 (:instance RD-OF-WR-REDUX (acl2::a a) (acl2::b b) (acl2::v val) (acl2::r ram2))
                 ))))

(defthm rd-subst-when-clr-equal
  (implies (and (equal (memory-clr b ram1) (memory-clr b ram2))
                (syntaxp (acl2::smaller-term ram2 ram1))
                (not (equal a b)))
           (equal (rd a ram1) 
                  (rd a ram2)))
  :hints (("Goal" :in-theory '(memory-clr rd-subst-when-wr-equal))))


;bzo gen to non-consp?
(defthm rd-of-nil
  (equal (gacc::rd a nil)
         0)
  :hints (("Goal" :in-theory (enable gacc::rd))))

;bzo add
(defthm memory-clr-of-nil
  (equal (gacc::memory-clr a nil)
         nil)
  :hints (("Goal" :in-theory (enable gacc::memory-clr))))
