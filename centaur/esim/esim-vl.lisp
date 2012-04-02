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


; esim-vl.lisp -- integration of VL and ESIM
; Original author: Jared Davis <jared@centtech.com>

(in-package "VL")
(include-book "esim-sexpr-support")
(include-book "centaur/vl/mlib/wirealist" :dir :system)


(defsection esim-vl
  :parents (acl2::esim vl)
  :short "Functions for working with E modules produced by VL.")


(local (defthm consp-of-assoc-equal
         (implies (alistp al)
                  (equal (consp (assoc-equal key al))
                         (if (assoc-equal key al)
                             t
                           nil)))
         :hints(("Goal" :in-theory (enable assoc-equal)))))


(defsection esim-vl-annotations
  :parents (esim-vl)
  :short "Helper for @(see esim-vl-designwires) and @(see esim-vl-wirealist)."

  (defund esim-vl-annotations (mod)
    (declare (xargs :guard t))
    (b* ((name (acl2::gpl :n mod))
         ((unless name)
          (er hard? 'esim-vl-annotations
              "Expected an E module, but this object doesn't even have a :n ~
               field: ~x0.~%" mod))
         (annotations (acl2::gpl :a mod))
         ((unless (alistp annotations))
          (er hard? 'esim-vl-annotations
              "In E module ~s0, the annotations field :a is not an alist."
              name)))
      annotations))

  (local (in-theory (enable esim-vl-annotations)))

  (defthm alistp-of-esim-vl-annotations
    (alistp (esim-vl-annotations mod))))



(defsection esim-vl-designwires
  :parents (esim-vl)
  :short "Produce a flat @(see vl-emodwirelist-p) that contains the E names
of every bit that is visible in the original Verilog module."

  :long "<p>@(call esim-vl-designwires) is given an E module and returns an
@(see vl-emodwirelist-p).</p>

<p>This list should include the E names for every bit that is declared in the
original Verilog module; see VL's @(see designwires) transform.  It should
<b>not</b> include the new, intermediate wire names that VL generates during
transformations like @(see split) and @(see occform).  Note that some
of the names in this list might be unused, and hence might not occur in the
<tt>occs</tt> of the module.</p>

<p>Run-time checks ensure that the <tt>:design-wires</tt> attribute of the
module contains a valid @(see vl-emodwirelist-p).  This should work for any E
module produced by VL, but may cause an error if used on other modules.  We
@(see memoize) the function to minimize the expense of these checks.</p>"

  (defund esim-vl-designwires (mod)
    (declare (xargs :guard t))
    (b* ((name        (acl2::gpl :n mod))
         (annotations (esim-vl-annotations mod))
         (lookup      (assoc :design-wires annotations))
         ((unless lookup)
          ;; Print a warning unless it's expected that there aren't any design
          ;; wires here.  We've rigged things up so that all of the VL
          ;; primitives have :x fields, whereas everything else (even generated
          ;; modules like VL_4_BIT_PLUS) has the regular annotations.  So, it
          ;; should be sufficient to just check for :x to decide if this is
          ;; worth warning about.  If you change this, also change
          ;; esim-vl-wirealist below.
          (if (acl2::gpl :x mod)
              nil
            (cw "Note: E module ~s0 has no :design-wires annotation!~%" name)))
         (dwires (cdr lookup))
         ((unless (vl-emodwirelist-p dwires))
          (er hard? 'esim-vl-designwires
              "In E module ~s0, :design-wires fails vl-emodwirelist-p check"
              name)))
      dwires))

  (local (in-theory (enable esim-vl-designwires)))

  (defthm vl-emodwirelist-p-of-esim-vl-designwires
    (vl-emodwirelist-p (esim-vl-designwires mod)))

  (memoize 'esim-vl-designwires))


(defsection esim-vl-wirealist
  :parents (esim-vl)
  :short "Obtain the @(see vl-wirealist-p) for an E module produced by VL."

  :long "<p>@(call esim-vl-wirealist) returns a <tt>vl-wirealist-p</tt>.</p>

<p>This is the \"final\" wirealist for the module, and typically will include
temporary wires introduced by VL.  The wirealist will be <tt>nil</tt> for
certain primitive modules.</p>

<p>Run-time checks ensure the <tt>:wire-alist</tt> annotation of the module is
a valid wirealist.  This should work for any E module produced by VL, but it
may cause an error if used on other modules.  We @(see memoize) the function
to minimize the expense of these checks.</p>"

  (defund esim-vl-wirealist (mod)
    (declare (xargs :guard t))
    (b* ((name        (acl2::gpl :n mod))
         (annotations (esim-vl-annotations mod))
         (lookup      (assoc :wire-alist annotations))
         ((unless lookup)
          ;; Print a warning unless it's expected that there isn't a wirealist
          ;; here.  See esim-vl-designwires above which includes an analagous
          ;; case.
          (if (acl2::gpl :x mod)
              nil
            (cw "Note: E module ~s0 has no :wire-alist annotation!~%" name)))
         (walist (cdr lookup))
         ((unless (vl-wirealist-p walist))
          (er hard? 'esim-vl-wirealist
              "In E module ~s0, :wire-alist fails vl-wirealist-p check"
              name)))
      walist))

  (local (in-theory (enable esim-vl-wirealist)))

  (defthm vl-wirealist-p-of-esim-vl-wirealist
    (vl-wirealist-p (esim-vl-wirealist mod)))

  ;; Same rationale as for esim-vl-designwires
  (memoize 'esim-vl-wirealist))




(defsection all-equalp-of-vl-emodwirelist->basenames
  :parents (esim-vl-iopattern-p)
  :short "@(call all-equalp-of-vl-emodwirelist->basenames) ensures that all of
the @(see vl-emodwire-p)s in <tt>x</tt> have this <tt>basename</tt>."

  (defun all-equalp-of-vl-emodwirelist->basenames (basename x)
    (declare (xargs :guard (and (stringp basename)
                                (vl-emodwirelist-p x))
                    :verify-guards nil))
    (mbe :logic
         (all-equalp basename (vl-emodwirelist->basenames x))
         :exec
         (if (atom x)
             t
           (and (equal basename (vl-emodwire->basename (car x)))
                (all-equalp-of-vl-emodwirelist->basenames basename (cdr x))))))

  (verify-guards all-equalp-of-vl-emodwirelist->basenames
    :hints(("Goal" :in-theory (disable all-equalp)))))


(defsection esim-vl-iopattern-entry-p
  :parents (esim-vl-iopattern-p)
  :short "@(call esim-vl-iopattern-entry-p) recognize lists of @(see
vl-emodwire-p)s like (A[0] A[1] ... A[N]), i.e., non-empty lists of emodwires
with the same basenames and unique indices."

  (defund esim-vl-iopattern-entry-p (x)
    (declare (xargs :guard t))
    (and (consp x)
         (vl-emodwirelist-p x)
         (true-listp x)
         (let ((basename (vl-emodwire->basename (car x))))
           (all-equalp-of-vl-emodwirelist->basenames basename (cdr x)))
         (uniquep (vl-emodwirelist->indices x))))

  (local (in-theory (enable esim-vl-iopattern-entry-p)))

  (defthm vl-emodwirelist-p-when-esim-vl-iopattern-entry-p
    (implies (esim-vl-iopattern-entry-p x)
             (vl-emodwirelist-p x)))

  (defthm consp-when-esim-vl-iopattern-entry-p
    (implies (esim-vl-iopattern-entry-p x)
             (and (true-listp x)
                  (consp x)))
    :rule-classes :compound-recognizer))


(defsection esim-vl-iopattern-entry->basename
  :parents (esim-vl-iopattern-p)
  :short "@(call esim-vl-iopattern-entry->basename) returns the basename that
is shared by all the members of a @(see esim-vl-iopattern-entry-p)."

  :long "<p>For instance, it returns \"A\" for (A[0] A[1] ... A[N]).</p>"

  (defund esim-vl-iopattern-entry->basename (x)
    (declare (xargs :guard (esim-vl-iopattern-entry-p x)))
    (mbe :logic (string-fix (vl-emodwire->basename (car x)))
         :exec (vl-emodwire->basename (car x))))

  (defthm stringp-of-esim-vl-iopattern-entry->basename
    (stringp (esim-vl-iopattern-entry->basename x))
    :rule-classes :type-prescription))


(deflist esim-vl-iopattern-entrylist-p (x)
  (esim-vl-iopattern-entry-p x)
  :guard t
  :elementp-of-nil nil
  :parents (esim-vl-iopattern-p))

(defprojection esim-vl-iopattern-entrylist->basenames (x)
  (esim-vl-iopattern-entry->basename x)
  :guard (esim-vl-iopattern-entrylist-p x)
  :nil-preservingp nil
  :parents (esim-vl-iopattern-p))

(defsection esim-vl-iopattern-p
  :parents (esim-vl)
  :short "Recognize a good <tt>:i</tt> or <tt>:o</tt> pattern for a
VL-translated module."

  :long "<p>@(call esim-vl-iopattern-p) is a basic syntax check to make ensure
that <tt>x</tt> has the proper shape for a <tt>:i</tt> or <tt>:o</tt> field of
an E module that VL produces.</p>

<p>Basically, VL writes out <tt>:i</tt> and <tt>:o</tt> fields for an E module
as two-level lists of @(see vl-emodwire-p)s.  For instance the <tt>:i</tt>
pattern for a module whose input declarations are:</p>

<code>
 input [3:0] A;
 input B;
 input [0:3] C;
</code>

<p>Should look like this:</p>

<code>
 :i ((A[0] A[1] A[2] A[3])    ;; lsb first
     (B)
     (C[3] C[2] C[1] C[0]))   ;; lsb first
</code>

<p>See @(see make-defm-command) for details.</p>

<p>We @(see memoize) this function to minimize the expense of these checks.
Note that esim-vl-iopattern-p is nonrecursive, so we should only need two memo
table entries per module, one for the <tt>:i</tt> and one for the <tt>:o</tt>
entry.</p>"

  (defund esim-vl-iopattern-p (x)
    (declare (xargs :guard t))
    (and (esim-vl-iopattern-entrylist-p x)
         (uniquep (esim-vl-iopattern-entrylist->basenames x))))

  (memoize 'esim-vl-iopattern-p))



(defsection esim-vl-find-io-main
  :parents (esim-vl-find-io)
  :short "@(call esim-vl-find-io-main) finds the first iopattern entry in
<tt>x</tt> with this <tt>basename</tt>."

  (defund esim-vl-find-io-main (basename x)
    (declare (xargs :guard (and (stringp basename)
                                (esim-vl-iopattern-entrylist-p x))))
    (cond ((atom x)
           nil)
          ((equal (esim-vl-iopattern-entry->basename (car x)) basename)
           (mbe :logic (list-fix (car x))
                :exec (car x)))
          (t
           (esim-vl-find-io-main basename (cdr x)))))

  (local (in-theory (enable esim-vl-find-io-main)))

  (defthm vl-emodwirelist-p-of-esim-vl-find-io-main
    (implies (esim-vl-iopattern-entrylist-p x)
             (vl-emodwirelist-p (esim-vl-find-io-main basename x))))

  (defthm true-listp-of-esim-vl-find-io-main
    (true-listp (esim-vl-find-io-main basename x))
    :rule-classes :type-prescription))


(defsection esim-vl-find-io
  :parents (esim-vl)
  :short "Produce an LSB-first list of E wire names corresponding to a
particular input or output of the original Verilog module."

  :long "<p>@(call esim-vl-find-io) returns a @(see vl-emodwirelist-p).</p>

<p>The <tt>basename</tt> is a string that names a wire in the original Verilog
module.  The <tt>pat</tt> should be either the <tt>:i</tt> or <tt>:o</tt> of an
E module that VL has produced.</p>

<p>Example.  If your Verilog module is something like:</p>

<code>
 module mymodule (o, a, b);
   input [3:0] a;
   input b;
   ...
 endmodule
</code>

<p>Then the resulting <tt>:i</tt> pattern for the E module <tt>|*mymodule*|</tt>
should be something like:</p>

<code>
 :i ((a[0] a[1] a[2] a[3])
     (b))
</code>

<p>And here are some examples of using <tt>esim-vl-find-io</tt>:</p>

<code>
 (esim-vl-find-io \"a\" (gpl :i |*mymodule*|)) --&gt; (a[0] a[1] a[2] a[3])
 (esim-vl-find-io \"b\" (gpl :i |*mymodule*|)) --&gt; (b)
 (esim-vl-find-io \"c\" (gpl :i |*mymodule*|)) --&gt; NIL
</code>

<p>On success the list of returned bits is non-empty.  The least significant
bit comes first.  <tt>NIL</tt> indicates that the wire was not found.</p>

<p>If <tt>pat</tt> is not a valid i/o pattern for an E module produced by VL,
i.e., it does not satisfy @(see esim-vl-iopattern-p), a hard error will be
caused.</p>"

  (local (in-theory (enable esim-vl-iopattern-p)))

  (defund esim-vl-find-io (basename pat)
    (declare (xargs :guard (stringp basename)))
    (if (esim-vl-iopattern-p pat) ;; <-- memoized
        (esim-vl-find-io-main basename pat)
      (er hard? 'esim-vl-find-io
          "This doesn't look like a valid I/O pattern for a VL-translated ~
           module: ~x0" pat)))

  (local (in-theory (enable esim-vl-find-io)))

  (defthm vl-emodwirelist-p-of-esim-vl-find-io
    (vl-emodwirelist-p (esim-vl-find-io basename pat)))

  (defthm true-listp-of-esim-vl-find-io
    (true-listp (esim-vl-find-io basename pat))
    :rule-classes :type-prescription))

