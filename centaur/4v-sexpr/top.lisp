; S-Expressions for 4-Valued Logic
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
;
; Original authors: Sol Swords <sswords@centtech.com>
;                   Jared Davis <jared@centtech.com>

; top.lisp
;   - includes all the other books
;   - gives some general overview documentation

(in-package "ACL2")
(include-book "4v-logic")
(include-book "bitspecs")
(include-book "compose-sexpr")
(include-book "g-sexpr-eval")
(include-book "nsexprs")
(include-book "onehot-rewrite")
(include-book "sexpr-advanced")
(include-book "sexpr-building")
(include-book "sexpr-equivs")
(include-book "sexpr-eval")
(include-book "sexpr-fixpoint-correct")
(include-book "sexpr-fixpoint")
(include-book "sexpr-fixpoint-rewriting")
(include-book "sexpr-fixpoint-spec")
(include-book "sexpr-fixpoint-top")
(include-book "sexpr-loop-debug")
(include-book "sexpr-rewrites")
(include-book "sexpr-to-faig")
(include-book "sexpr-vars")
(include-book "svarmap")


(defxdoc 4v
  :short "The four-valued logic of the @(see esim) hardware simulator."

  :long "<p>We model circuits using a four-valued logic, which loosely means
that any wire can take on one of four values:</p>

<ul>
 <li>X represents \"unknown\" values</li>
 <li>Z represents an \"undriven\" or \"floating\" value</li>
 <li>T represents logical truth</li>
 <li>F represents logical falsity</li>
</ul>

<p>These values are recognized with @(see 4vp).</p>")


(defxdoc why-4v-logic
  :parents (4v)
  :short "Motivation for using a four-valued logic."

  :long "<p>Why use a four-valued logic instead of a simple, two-valued,
Boolean logic with just T and F?</p>

<p>Having an X value is fundamental to the semantics of @(see esim), our
circuit evaluator.  Loosely speaking, when we begin simulating a circuit, all
of the internal wires are given X as their value.  We then evaluate all of the
submodule occurrences.  Because of <see topic='@(url
4v-monotonicity)'>monotonicity</see>, these evaluations can only change wires
from X to a different value.  This puts a bound on the maximum number of
evaluation steps required for the circuit's wires to reach a fixed point.</p>

<p>In the context of symbolic simulation, X values are sometimes also useful as
a way to ignore certain signals.  For instance, if we think some inputs to a
particular circuit are not even involved in the property we wish to prove, we
may leave them as X.</p>

<p>X values also allow us to model some circuits which cannot be expressed with
just Boolean logic.  For instance, imagine a scenario like:</p>

<code>
         Diagram                      Verilog
          ____
         |    \\                    assign C = ~A;
   A  ---|     o------+            assign C = ~B;
         |____/       |
          ____        |-- C
         |    \\       |
   B  ---|     o------+
         |____/
</code>

<p>Here the wire C is being driven by two separate sources.  When these sources
have different values, e.g., suppose A is T and B is F, then C is
simultaneously driven to both F and T.  We do not know which value will
\"win,\" or, really, whether there will even be a winner.  So in this case we
just say the value of C is X.  Without an X value, we would not be able to
model this circuit.</p>

<p>The Z value allows us to model additional circuits, even beyond those
circuits that are possible to model using Xes.  In the circuit above, we did
not need a Z value because not-gates always drive at least some value onto C.
But other kinds of circuits do not necessarily drive their output.  For
instance, in Verilog one might describe a mux whose selects must be one-hot as
follows:</p>

<code>
 assign C = S1 ? A : 1'bz;
 assign C = S2 ? B : 1'bz;
 ...
</code>

<p>By adopting Z into our logic, we can model these kinds of assignments
directly, e.g., see @(see 4v-tristate) and @(see 4v-res).</p>")


(defsection 4v-sexprs
  :parents (4v)
  :short "S-Expression representation of four-valued expressions."

  :long "<p>We represent expressions in our four-valued logic using a simple
S-Expression (sexpr) format.</p>

<p>The semantics of these expressions is given by @(see 4v-sexpr-eval).
Loosely speaking,</p>

<ul>

<li><tt>NIL</tt> is special and always evaluates to X.</li>

<li>All atoms other than <tt>NIL</tt> represent variables and get their values
from an environment.</li>

<li><tt>(f a1 a2 ... an)</tt> is a function application of <tt>f</tt> to
arguments <tt>a1</tt> ... <tt>an</tt>, where each <tt>ai</tt> is itself a
sexpr.</li>

</ul>

<p>Since we only have four constants, we don't permit quoted constants; instead
we just have constant functions.  That is, in any environment,</p>

<ul>
<li><tt>(T)</tt> produces T,</li>
<li><tt>(F)</tt> produces F,</li>
<li><tt>(Z)</tt> produces Z, and</li>
<li><tt>(X)</tt> produces X.</li>
</ul>

<p>We also have around a dozen functions like <tt>AND</tt>, <tt>OR</tt>,
<tt>NOT</tt>, <tt>ITE</tt>, etc., that correspond to the @(see 4v-operations).
The particular set of understood functions are determined by @(see
4v-sexpr-eval).</p>

<p>A wonderful feature of our 4v sexpr language is that, since all of these
operations are <see topic='@(url 4v-monotonicity)'>monotonic</see>,
monotonicity is an intrinsic property of every sexpr.</p>

<p>As with our @(see aig) and @(see ubdd) representations, we generally expect
to create all sexprs with @(see hons), and we often @(see memoize) operations
that deal with sexprs.  We provide some @(see 4vs-constructors) for building
s-expressions.</p>")
