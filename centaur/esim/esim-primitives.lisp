; ESIM Symbolic Hardware Simulator
; Copyright (C) 2010-2012 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; This program is free software; you can redistribute it and/or modify it under
; the terms of the GNU General Public License as published by the Free Software
; Foundation; either version 2 of the License, or (at your option) any later
; version.  This program is distributed in the hope that it will be useful but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
; more details.  You should have received a copy of the GNU General Public
; License along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Suite 500, Boston, MA 02110-1335, USA.


; esim-primitives.lisp - Definitions of primitive E modules for Verilog modeling
;
; Original authors: Jared Davis <jared@centtech.com>
;                   Sol Swords <sswords@centtech.com>

(in-package "ACL2")
(include-book "tools/bstar" :dir :system)
(include-book "xdoc/top" :dir :system)
(include-book "plist")

(defsection esim-primitives
  :parents (esim)
  :short "The @(see esim) modules that implement @(see vl::vl)'s @(see
vl::primitives)."

  :long "<p>The patterns used for the :i and :o ports here might look strange.
For instance, why do we use <tt>((a) (b))</tt> as the input pattern for an AND
gate instead of <tt>(a b)</tt>?  This allows our primitives to be directly
compatible with VL's primitives, as far as @(see vl-portdecls-to-i/o) is
concerned.</p>

<p><b>BOZO</b> Things to consider:</p>

<ul>

<li>Do we want to add NAND and NOR primitives to @(see 4v-sexprs)?  We
currently implement them as <tt>(not (and a b))</tt> and <tt>(not (or a
b))</tt>.</li>

<li>Do we want to change LATCH and FLOP to use @(see 4v-ite*) instead of @(see
4v-ite)?  It probably won't help with combinational loops at all, but it may
make our modeling more conservative.  If it doesn't cause problems, it might
be worth doing.</li>

<li>Is there any good reason to keep PULLUP and ID in @(see 4v-sexprs)?  We
aren't using them for anything.</li>

<li>Eventaully implement WOR and WAND resolution</li>

</ul>")


(defmacro def-esim-primitive (name &key x i o
                                   (parents '(esim-primitives))
                                   (short '"")
                                   (long '""))
  (declare (xargs :guard (and (symbolp name)
                              (stringp short)
                              (stringp long))))
  (b* (((unless x)
        (er hard? 'def-esim-primitive
            "Only use this for modules with :x definitions."))
       (s (strip-cars (gpl :nst x)))
       (body (append `(:n ,name
                          :x ,x
                          :i ,i
                          :o ,o)
                     ;; BOZO can we get rid of all the full stuff yet??
                     (if s `(:s ,s :full-s ,s) nil)
                     `(:full-i ,i :full-o ,o))))
    `(defsection ,name
       :parents ,parents
       :short ,short
       :long ,(concatenate 'string long
                           "<h3>Definition:</h3> @(def " (symbol-name name) ")")
       (defconst ,name ',body))))

(def-esim-primitive *esim-t*
  :short "Primitive E module for producing T."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-t*).</p>"
  :i ()
  :o ((o))
  :x (:out ((o . (t)))))

(def-esim-primitive *esim-f*
  :short "Primitive E module for producing F."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-f*).</p>"
  :i ()
  :o ((o))
  :x (:out ((o . (f)))))

(def-esim-primitive *esim-x*
  :short "Primitive E module for producing X."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-x*).</p>"
  :i ()
  :o ((o))
  :x (:out ((o . (x)))))

(def-esim-primitive *esim-z*
  :short "Primitive E module for producing Z."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-z*).</p>"
  :i ()
  :o ((o))
  :x (:out ((o . (z)))))

(def-esim-primitive *esim-id*
  :short "Primitive E module for identity assignment."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-assign*).  This
differs from a BUF in that it does not coerce Z into X.  There is probably not
any way to actually implement this in hardware.</p>"
  :i ((a))
  :o ((o))
  :x (:out ((o . a))))

(def-esim-primitive *esim-del*
  :short "Primitive E module for a delayed assignment."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-delay-1*).  However,
really esim has no concept of delays and this is no different @(see
*esim-id*).</p>"
  :i ((a))
  :o ((o))
  :x (:out ((o . a))))

(def-esim-primitive *esim-buf*
  :short "Primitive E module for a BUF gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-buf*).  This is used
for real BUF gates, not for ordinary assignments; see also @(see
*esim-id*).</p>"
  :i ((a))
  :o ((o))
  :x (:out ((o . (buf a)))))

(def-esim-primitive *esim-not*
  :short "Primitive E module for a NOT gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-not*).</p>"
  :i ((a))
  :o ((o))
  :x (:out ((o . (not a)))))

(def-esim-primitive *esim-and*
  :short "Primitive E module for an AND gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-and*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (and a b)))))

(def-esim-primitive *esim-or*
  :short "Primitive E module for an OR gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-or*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (or a b)))))

(def-esim-primitive *esim-xor*
  :short "Primitive E module for an XOR gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-xor*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (xor a b)))))

(def-esim-primitive *esim-nand*
  :short "Primitive E module for a NAND gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-nand*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (not (and a b))))))

(def-esim-primitive *esim-nor*
  :short "Primitive E module for a NOR gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-nor*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (not (or a b))))))

(def-esim-primitive *esim-xnor*
  :short "Primitive E module for an XNOR gate."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-xnor*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (iff a b)))))

(def-esim-primitive *esim-ceq*
  :short "Primitive E module for a Verilog <tt>===</tt> operator."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-ceq*).</p>

<p>However, the <tt>===</tt> operator is inherently unsound and cannot be
modeled in esim because it is violates @(see 4v-monotonicity).  We just
conservatively approximate <tt>===</tt> with an xnor gate.  That is, this
module is nothing more than a @(see *esim-xnor*).</p>"

  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (iff a b)))))

(def-esim-primitive *esim-res*
  :short "Primitive E module for resolving multiple drivers on a wire."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-resolve-wire*).</p>"
  :i ((a) (b))
  :o ((o))
  :x (:out ((o . (res a b)))))

;; BOZO add WOR, WAND...

(def-esim-primitive *esim-tri*
  :short "Primitive E module for a tri-state buffer."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-zmux*).</p>"
  :i ((sel) (a))
  :o ((o))
  :x (:out ((o . (tristate sel a)))))

(def-esim-primitive *esim-flop*
  :short "Primitive E module for a register."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-flop*).</p>"
  :i ((clk) (d))
  :o ((q))
  :x (:out ((q  . (ite clk s- s+)))
      :nst ((s- . (ite clk s- d))
            (s+ . (ite clk s- s+)))))

(def-esim-primitive *esim-latch*
  :short "Primitive E module for a latch."
  :long "<p>We use this to implement @(see vl::*vl-1-bit-latch*).</p>"
  :i ((clk) (d))
  :o ((q))
  :x (:out ((q . (ite clk d s)))
      :nst ((s . (ite clk d s)))))

(defsection *esim-primitives*
  :parents (esim-primitives)
  :short "A list of all esim primitives."
  :long "@(def *esim-primitives*)"

  (defconst *esim-primitives*
    (list *esim-t*
          *esim-f*
          *esim-x*
          *esim-z*
          *esim-id*
          *esim-del*
          *esim-buf*
          *esim-not*
          *esim-and*
          *esim-or*
          *esim-xor*
          *esim-nand*
          *esim-nor*
          *esim-xnor*
          *esim-ceq*
          *esim-res*
          *esim-tri*
          *esim-flop*
          *esim-latch*)))

