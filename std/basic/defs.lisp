; Std/basic - Basic definitions
; Copyright (C) 2008-2013 Centaur Technology
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
; Original author: Jared Davis <jared@centtech.com>

(in-package "ACL2")
(include-book "xdoc/top" :dir :system)

(defxdoc std/basic
  :parents (std)
  :short "A collection of very basic functions that are occasionally
convenient."

  :long "<p>The @('std/basic') library adds a number of very basic definitions
that are not built into ACL2.  There's very little to this, it's generally just
a meant to be a home for simple definitions that don't fit into bigger
libraries.</p>")

(local (xdoc::set-default-parents std/basic))


(defsection lnfix
  :short "@(call lnfix) is logically identical to @('(nfix x)'), but its guard
requires that @('x') is a natural number and, in the execution, it is just a
no-op that returns @('x')."

  :long "<p>@(call lnfix) is a macro that just expands into</p>

@({
     (mbe :logic (nfix x) :exec x)
})

<p>Why would you want this?  When you defining a function whose @(see guard)
assumes @('(natp n)'), it is often a good idea to write the function so that it
logically treats non-naturals as 0.  You might generally accomplish this by
rewriting, e.g.,:</p>

@({
    (defun my-function (n ...)
      (declare (xargs :guard (natp n)))
      <body>)

    --->

    (defun my-function (n ...)
      (declare (xargs :guard (natp n)))
      (let ((n (nfix n)))
        <body>))
})

<p>This leads to a nice @(see nat-equiv) @(see congruence) rule.  But since
@(see nfix) has to check whether its argument is a natural number, and that
has some performance cost.</p>

<p>By using @(see lnfix) in place of @('nfix') here, you can get the same
logical definition without this overhead.</p>"

  (defmacro lnfix (x)
    `(mbe :logic (nfix ,x)
          :exec ,x)))


(defsection lifix
  :short "@(call lifix) is logically identical to @('(ifix x)'), but its guard
requires that @('x') is an integer and, in the execution, it is just a no-op
that returns @('x')."

  :long "<p>@(call lifix) is a macro that just expands into</p>

@({
     (mbe :logic (ifix x) :exec x)
})

<p>To understand why you might want this, see the analogous discussion about
@(see lnfix).</p>"

  (defmacro lifix (x)
    `(mbe :logic (ifix ,x)
          :exec ,x)))


(defsection true
  :short "A function that always just returns the constant @('t')."
  :long "<p>This is occasionally useful for @(see defattach), etc.</p>"

  (defun true ()
    (declare (xargs :guard t))
    t))


(defsection false
  :short "A function that just returns the constant @('nil')."
  :long "<p>This is occasionally useful for @(see defattach), etc.</p>"

  (defun false ()
    (declare (xargs :guard t))
    nil))


(defsection maybe-natp
  :short "Recognizer for naturals and @('nil')."
  :long "<p>This is like an <a
href='https://en.wikipedia.org/wiki/Option_type'>option type</a>; when @('x')
satisfies @('maybe-natp'), then either it is a natural number or nothing.</p>"

  (defund-inline maybe-natp (x)
    (declare (xargs :guard t))
    (or (not x)
        (natp x)))

  (local (in-theory (enable maybe-natp)))

  (defthm maybe-natp-compound-recognizer
    (equal (maybe-natp x)
           (or (not x)
               (and (integerp x)
                    (<= 0 x))))
    :rule-classes :compound-recognizer))


(defsection maybe-integerp
  :short "Recognizer for integers and @('nil')."
  :long "<p>This is like an <a
href='https://en.wikipedia.org/wiki/Option_type'>option type</a>; when @('x')
satisfies @('maybe-integerp'), then either it is a integer or nothing.</p>"

  (defund-inline maybe-integerp (x)
    (declare (xargs :guard t))
    (or (not x)
        (integerp x)))

  (local (in-theory (enable maybe-integerp)))

  (defthm maybe-integerp-compound-recognizer
    (equal (maybe-integerp x)
           (or (integerp x)
               (not x)))
    :rule-classes :compound-recognizer))


(defsection maybe-posp
  :short "Recognizer for positive naturals and @('nil')."
  :long "<p>This is like an <a
href='https://en.wikipedia.org/wiki/Option_type'>option type</a>; when @('x')
satisfies @('maybe-posp'), then either it is a positive, natural number or
nothing.</p>"

  (defund-inline maybe-posp (x)
    (declare (xargs :guard t))
    (or (not x)
        (posp x)))

  (local (in-theory (enable maybe-posp)))

  (defthm maybe-posp-compound-recognizer
    (equal (maybe-posp x)
           (or (and (integerp x)
                    (< 0 x))
               (not x)))
    :rule-classes :compound-recognizer))


(defsection maybe-stringp
  :short "Recognizer for strings and @('nil')."
  :long "<p>This is like an <a
href='https://en.wikipedia.org/wiki/Option_type'>option type</a>; when @('x')
satisfies @('maybe-stringp'), then either it is a string or nothing.</p>"

  (defund-inline maybe-stringp (x)
    (declare (xargs :guard t))
    (or (not x)
        (stringp x)))

  (local (in-theory (enable maybe-stringp)))

  (defthm maybe-stringp-compound-recognizer
    (equal (maybe-stringp x)
           (or (not x)
               (stringp x)))
    :rule-classes :compound-recognizer))
