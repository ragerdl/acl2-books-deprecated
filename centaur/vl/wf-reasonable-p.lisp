; VL Verilog Toolkit
; Copyright (C) 2008-2014 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Jared Davis <jared@centtech.com>

(in-package "VL")
(include-book "mlib/modnamespace")
(include-book "mlib/find-item")
(include-book "mlib/expr-tools")
(include-book "mlib/range-tools")
(include-book "util/defwellformed")
(include-book "util/warnings")
(include-book "defsort/duplicated-members" :dir :system)
(local (include-book "util/arithmetic"))
(local (include-book "util/osets"))

(defxdoc reasonable
  :parents (well-formedness)
  :short "Identify modules in our supported subset of Verilog."
  :long "<p>We say a module is <i>reasonable</i> if it</p>

<ol>
  <li>is semantically well-formed, and</li>
  <li>does not contain unsupported constructs.</li>
</ol>

<p>Even though our parser essentially establishes that the files we have just
read are syntactically well-formed, this does not necessarily mean the files
are semantically well-formed.  For instance, a module might illegally declare
the same wire twice, or perhaps we have tried to declare two modules with the
same name.  So, our reasonableness check is important for ensuring the basic
semantic correctness of the modules we are examining.</p>

<p>We also regard many perfectly valid Verilog constructs as unreasonable, for
the simple pragmatic reason that we are only really interested in dealing with
the small subset of Verilog that we actually encounter at Centaur.  There is
little motivation for us to support things like complicated port lists merely
because they are in the Verilog-2005 standard.</p>")

(defwellformed vl-portlist-reasonable-p (x)
  :parents (reasonable)
  :short "@(call vl-portlist-reasonable-p) determines if a @(see vl-portlist-p)
is @(see reasonable)."
  :long "<p>We just require that any externally visible names are unique.  A
number of additional well-formedness checks are done in @(see argresolve) and
@(see e-conversion).</p>"

  :guard (vl-portlist-p x)
  :body (let* ((names (remove nil (vl-portlist->names x)))
               (dupes (duplicated-members names)))
          (@wf-assert (not dupes)
                      :vl-bad-ports
                      "Duplicate port names: ~&0."
                      (list dupes))))

(defwellformed vl-portdecl-reasonable-p (x)
  :parents (reasonable)
  :short "@(call vl-portdecl-reasonable-p) determines if a @(see vl-portdecl-p)
is @(see reasonable)."
  :long "<p>We greatly restrict the permitted port declarations:</p>

<ul>

<li>We only permit port declarations of type @('supply0'), @('supply1'), and
@('wire'), excluding other types such as @('tri0'), @('wor'), etc.</li>

<li>We do not permit @('inout') ports.</li>

</ul>"

  :guard (vl-portdecl-p x)
  :body (let ((x x))
          (declare (ignore x))
          (@wf-progn)))

  ;; :body (let ((name    (vl-portdecl->name x))
  ;;             (dir     (vl-portdecl->dir x))
  ;;             (loc     (vl-portdecl->loc x)))
  ;;         (declare (ignorable name dir loc))
  ;;         (@wf-progn
  ;;          (@wf-assert (or (eq dir :vl-input)
  ;;                          (eq dir :vl-output))
  ;;                      :vl-bad-portdecl
  ;;                      "~l0: port ~s1 has unsupported direction ~s2."
  ;;                      (list loc name dir)))))

(defwellformed-list vl-portdecllist-reasonable-p (x)
  :parents (reasonable)
  :short "@(call vl-portdecllist-reasonable-p) determines if every member of a
@(see vl-portdecllist-p) satisfies @(see vl-portdecl-reasonable-p)."
  :element vl-portdecl-reasonable-p
  :guard (vl-portdecllist-p x))


;; (defwellformed vl-ports-and-portdecls-compatible-p (ports portdecls)
;;   :parents (reasonable)
;;   :short "@(call vl-ports-and-portdecls-compatible-p) is given the lists of
;; ports and port declarations for a module, and ensures that (1) there are no
;; duplicate port declarations, and (2) every port in the ports list is
;; declared."
;;   :long "@(def vl-ports-and-portdecls-compatible-p)"
;;   :guard (and (vl-portlist-p ports)
;;               (vl-portdecllist-p portdecls))
;;   :body
;;   (let* ((portnames       (vl-portlist->names ports))
;;          (portdeclnames   (vl-portdecllist->names portdecls))
;;          (portnames-s     (mergesort portnames))
;;          (portdeclnames-s (mergesort portdeclnames)))
;;     (@wf-progn
;;      (@wf-assert (mbe :logic (no-duplicatesp-equal portdeclnames)
;;                       :exec (same-lengthp portdeclnames portdeclnames-s))
;;                  :vl-bad-portdecls
;;                  "Ports are declared multiple times: ~&0."
;;                  (list (duplicated-members portdeclnames)))
;;      (@wf-assert (equal portnames-s portdeclnames-s)
;;                  :vl-bad-portdecls
;;                  "Ports and port declarations do not agree.  Undeclared ~
;;                   ports are ~&0.  Extra port declarations are ~&1."
;;                  (list (difference portdeclnames-s portnames-s)
;;                        (difference portnames-s portdeclnames-s))))))


(defwellformed vl-netdecl-reasonable-p (x)
  :parents (reasonable)
  :short "@(call vl-netdecl-reasonable-p) determines if a @(see vl-netdecl-p)
is @(see reasonable)."
  :long "<p>We restrict wire declarations in the following ways:</p>
<ul>

<li>The only allowed types are @('supply0'), @('supply1'), and plain
@('wire')s.  Not permitted are types such as @('wor') and @('tri0').</li>

<li>Arrays of wires are not supported.  (Note that we do support wires with
ranges, e.g., @('wire [7:0] w').  What we do not support are, e.g., @('wire w
[7:0]'), or multi-dimensional arrays such as @('wire [7:0] w [3:0]').</li>

</ul>"

  :guard (vl-netdecl-p x)
  :body
  (let ((name      (vl-netdecl->name x))
        (type      (vl-netdecl->type x))
        (arrdims   (vl-netdecl->arrdims x))
        (loc       (vl-netdecl->loc x)))
    (declare (ignorable name loc))
    (@wf-progn
     (@wf-assert (member-equal type (list :vl-supply0 :vl-supply1 :vl-wire))
                 :vl-bad-wire
                 "~l0: wire ~s1 has unsupported type ~s2."
                 (list loc name type))
     (@wf-assert (not arrdims)
                 :vl-bad-wire
                 "~l0: wire ~s1 is an array, which is not supported."
                 (list loc name)))))

(defwellformed-list vl-netdecllist-reasonable-p (x)
  :element vl-netdecl-reasonable-p
  :guard (vl-netdecllist-p x)
  :parents (reasonable))

(defwellformed vl-vardecl-reasonable-p (x)
  :parents (reasonable)
  :guard (vl-vardecl-p x)
  :extra-decls ((ignorable x))
  :body (b* (((vl-vardecl x) x))
          (@wf-progn
           (@wf-assert (vl-simplereg-p x)
                       :vl-variable-toohard
                       "~a0: variable declarations other than simple 'reg' or 'logic' wires ~
                        are not yet supported."
                       (list x)))))

(defwellformed-list vl-vardecllist-reasonable-p (x)
  :element vl-vardecl-reasonable-p
  :guard (vl-vardecllist-p x)
  :parents (reasonable))

(defwellformed vl-modinst-reasonable-p (x)
  :parents (reasonable)
  :guard (vl-modinst-p x)
  :extra-decls ((ignorable x))

; There doesn't seem to be anything to restrict for modinsts.  I leave this
; function here only to denote that I've

  :body (@wf-assert t))

(defwellformed-list vl-modinstlist-reasonable-p (x)
  :element vl-modinst-reasonable-p
  :guard (vl-modinstlist-p x)
  :parents (reasonable))

(defwellformed vl-gateinst-reasonable-p (x)
  :parents (reasonable)
  :guard (vl-gateinst-p x)
  :body (let ((name (or (vl-gateinst->name x) "<unnamed gate>"))
              (type (vl-gateinst->type x))
              (loc  (vl-gateinst->loc x)))
          (declare (ignorable name loc))
          (@wf-progn
           ;; BOZO is this doing anything?
           (@wf-assert (member-eq type '(:vl-and :vl-or :vl-xor :vl-nand :vl-nor
                                                 :vl-xnor :vl-not :vl-buf
                                                 :vl-bufif0 :vl-bufif1 :vl-notif0 :vl-notif1
                                                 :vl-nmos :vl-rnmos :vl-pmos :vl-rpmos
                                                 :vl-cmos :vl-rcmos))
                       :vl-gate-type
                       "~l0:~% -- gate ~s1 has unsupported type ~s2."
                       (list loc name type)))))

(defwellformed-list vl-gateinstlist-reasonable-p (x)
  :parents (reasonable)
  :element vl-gateinst-reasonable-p
  :guard (vl-gateinstlist-p x))


(defwellformed vl-portdecl-and-moduleitem-compatible-p (portdecl item)
  :parents (reasonable)
  :short "Main function for checking whether a port declaration, which overlaps
with some module item declaration, is a reasonable overlap."
  :guard (and (vl-portdecl-p portdecl)
              (or (vl-netdecl-p item)
                  (vl-vardecl-p item)
                  (vl-paramdecl-p item)
                  (vl-fundecl-p item)
                  (vl-taskdecl-p item)
                  (vl-modinst-p item)
                  (vl-gateinst-p item)))
  :long "<p>For instance, we might have:</p>

@({
    input x;
    wire x;
})

<p>Which is fine, or we might have:</p>

@({
    input [3:0] x;
    wire [4:0] x;
})

<p>Which is definitely not okay.</p>

<p>We assume, although it is not in our guard, that the inputs we are comparing
are reasonable.  That is, we aren't going to worry about the type or signedness
on the portdecl, or any kind of arrdims or initvals and so forth on the
item.</p>"

  :body

  (case (tag item)
    (:vl-netdecl

     (@wf-progn

; The following is arguably too severe.  It will disallow things like "input
; [1+2:0] x;" followed by "wire [3:0] x;"  Hopefully we don't hit this.
;
; Follow-up.  According to Section 12.3.3, page 174 (near the bottom), "The
; range specification between the two declarations of a port shall be
; identical."  So, whether or not our behavior is too severe depends on
; your notion of "identical".

      (@wf-assert (equal (vl-portdecl->range portdecl)
                         (vl-netdecl->range item))
                  :vl-incompatible-range
                  "~l0: port ~s1 is declared to have range ~a2, but is ~
                        also declared as a wire with range ~a3."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-portdecl->range portdecl)
                        (vl-netdecl->range item)))

; I don't really want there to be an input or output that is declared to be a
; supply or something crazy.

      (@wf-assert (or (equal (vl-netdecl->type item) :vl-wire)
                      (and (or (equal (vl-netdecl->type item) :vl-supply0)
                               (equal (vl-netdecl->type item) :vl-supply1))))
                  :vl-scary-port
                  "~l0: port ~s1 is also declared as a wire with type ~s2."
                  (list (vl-portdecl->loc portdecl)
                        (vl-netdecl->name item)
                        (vl-netdecl->type item)))

; Make sure the signedness agrees; see the documentation in portdecl-sign for
; more information.

      (@wf-assert (equal (vl-netdecl->signedp item)
                         (vl-portdecl->signedp portdecl))
                  :vl-incompatible-sign
                  "~l0: port declaration for ~s1 has signedp ~x2, while net ~
                   declaration has signedp ~x3.  This case should have been ~
                   corrected by the portdecl-sign transformation."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-portdecl->signedp portdecl)
                        (vl-netdecl->signedp item)))

; Probably unnecessary, but maybe sensible.

      (@wf-assert (not (vl-netdecl->delay item))
                  :vl-delayed-port
                  "~l0: port ~s1 is also declared as a wire with a delay."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)))

; Probably unnecessary, but maybe sensible.

      (@wf-assert (not (vl-netdecl->cstrength item))
                  :vl-cstrength-port
                  "~l0: port ~s1 is also declared as a wire with a charge strength."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)))))

    (:vl-vardecl

     (@wf-progn

      (@wf-assert (vl-simplereg-p item)
                  :vl-weird-port
                  "~l0: port ~s1 is also declared to be a ~a2."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-vardecl->vartype item)))

; Like for netdecls, this may be too severe, and will not permit us to "input
; [1+2:0] x;" followed by "reg [3:0] x;".  See also the "follow-up" in the
; netdecl case, above.


      (@wf-assert (or (not (vl-simplereg-p item))
                      (equal (vl-portdecl->range portdecl)
                             (vl-simplereg->range item)))
                  :vl-incompatible-range
                  "~l0: port ~s1 is declared to have range ~a2, but is ~
                        also declared as a reg with range ~a3."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-portdecl->range portdecl)
                        (vl-simplereg->range item)))

; Make sure the signedness agrees; see the documentation in portdecl-sign for
; more information.

      (@wf-assert (or (not (vl-simplereg-p item))
                      (equal (vl-simplereg->signedp item)
                             (vl-portdecl->signedp portdecl)))
                  :vl-incompatible-sign
                  "~l0: port declaration for ~s1 has signedp ~x2, while reg ~
                   declaration has signedp ~x3.  This case should have been ~
                   corrected by the portdecl-sign transformation."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-portdecl->signedp portdecl)
                        (vl-simplereg->signedp item)))

; It makes sense that a reg could be an output.  But I don't want to think
; about what it would mean for a reg to be an input or an inout wire.

      (@wf-assert (equal (vl-portdecl->dir portdecl) :vl-output)
                  :vl-scary-reg
                  "~l0: port ~s1 has direction ~s2, but is also declared ~
                   to be a register."
                  (list (vl-portdecl->loc portdecl)
                        (vl-portdecl->name portdecl)
                        (vl-portdecl->dir portdecl)))
      ))

; It doesn't make sense to me that any of these would be a port.
    ((:vl-paramdecl :vl-fundecl :vl-taskdecl :vl-modinst :vl-gateinst)

     (@wf-assert nil
                 :vl-weird-port
                 "~l0: port ~s1 is also declared to be a ~s2."
                 (list (vl-portdecl->loc portdecl)
                       (vl-portdecl->name portdecl)
                       (tag item))))

    (t
     (prog2$
      (er hard 'vl-portdecl-and-moduleitem-compatible-p "Impossible case")
      (@wf-assert nil)))))

(defwellformed vl-overlap-compatible-p (names x palist ialist)
  ;; For some very large modules (post synthesis), we found the overlap checking to be very
  ;; expensive due to slow lookups.  So, we now optimize this to use fast-alist lookups.
  :parents (reasonable)
  :guard (and (string-listp names)
              (vl-module-p x)
              (equal palist (vl-portdecl-alist (vl-module->portdecls x)))
              (equal ialist (vl-moditem-alist x))
              (subsetp-equal names (vl-portdecllist->names (vl-module->portdecls x)))
              (subsetp-equal names (vl-module->modnamespace x)))
  :body (if (atom names)
            (progn$
             ;; BOZO I hate this style where the aux function frees the fast alists,
             ;; but for now it's easier to do it this way.
             (fast-alist-free ialist)
             (fast-alist-free palist)
             (@wf-assert t))
          (@wf-progn
           (@wf-call vl-portdecl-and-moduleitem-compatible-p
                     (vl-fast-find-portdecl (car names) (vl-module->portdecls x) palist)
                     (vl-fast-find-moduleitem (car names) x ialist))
           (@wf-call vl-overlap-compatible-p (cdr names) x palist ialist))))




; Always blocks are quite hard to handle because of how complex they are.  But
; we try to support a very limited subset of them.
;
; In particular, below we sketch out an extremely restrictive set of
; "reasonable statements" which include only nonblocking assignments guarded by
; if statements, and statement blocks.  This is not quite sufficient.  We also
; need to be able to look at sensitivity lists.  It turns out that in Verilog
; code such as:
;
;   always @ (posedge clk) foo ;
;
; This sensitivity list is actually part of a statement and is not part of the
; "always" itself.  These are called Procedural Timing Control Statements, and
; in our parse tree occur as vl-ptctrlstmt-p's.
;
; We do not try to support these in any general way, and prohibit them from
; occurring in "reasonable statements".  However, our always-block recognizer
; permits a single one of these to occur at the top level, as long as it meets
; a list of requirements.

;; (defwellformed vl-assignstmt-reasonable-p (x)
;;   :guard (vl-assignstmt-p x)
;;   :body (let ((type   (vl-assignstmt->type x))
;;               (lvalue (vl-assignstmt->lvalue x)))
;;           (declare (ignorable type))

;;           (@wf-progn

;;            (@wf-note

;; ; Sol and I have had a discussion and now think that delay statements on
;; ; non-blocking assignments are okay. This should definitely become a
;; ; @wf-assert, but for now I'm just using @wf-note because blocking (foo = bar)
;; ; style assignments are often used instead of nonblocking (foo <= bar) ones.

;;             (eq type :vl-nonblocking)
;;             :vl-bad-assignment
;;             "~s0: unsoundly treating ~s1 assignment as non-blocking."
;;             (list (vl-location-string (vl-assignstmt->loc x)) type))

;; ; It would be nice to drop this requirement eventually and support assignments
;; ; to concatenations and selects.  But this makes our programming much easier;
;; ; see xf-elim-always.lisp.

;;            (@wf-assert (and (vl-atom-p lvalue)
;;                             (vl-id-p (vl-atom->guts lvalue)))
;;                        :wf-lvalue-too-hard
;;                        "~s0: assignment to ~s1 is too complicated."
;;                        (list (vl-location-string (vl-assignstmt->loc x))
;;                              (vl-pps-origexpr lvalue))))))

;; (defwellformed vl-atomicstmt-reasonable-p (x)
;;   :guard (vl-atomicstmt-p x)
;;   :body (case (tag x)
;;           (:vl-nullstmt
;;            (@wf-assert t))
;;           (:vl-assignstmt
;;            (@wf-call vl-assignstmt-reasonable-p x))
;;           (t
;;            (@wf-assert nil
;;                        :vl-unsupported-stmt
;;                        "Unsupported statement: ~x0."
;;                        (list (tag x))))))

;; (mutual-defwellformed

;;  (defwellformed vl-stmt-reasonable-p (x)
;;    :guard (vl-stmt-p x)
;;    :extra-decls ((xargs :measure (two-nats-measure (acl2-count x) 0)
;;                         :verify-guards nil))
;;    :body (cond
;;           ((vl-atomicstmt-p x)
;;            (@wf-call vl-atomicstmt-reasonable-p x))

;;           ((mbe :logic (not (consp x))
;;                 :exec nil)
;;            (prog2$
;;             (er hard 'vl-stmt-reasonable-p "Impossible case for termination.")
;;             (@wf-assert t)))

;;           (t
;;            (let ((type  (vl-compoundstmt->type x))
;;                  (stmts (vl-compoundstmt->stmts x))
;;                  (name  (vl-compoundstmt->name x))
;;                  (decls (vl-compoundstmt->decls x)))
;;              (case type
;;                (:vl-ifstmt
;;                 (@wf-call vl-stmtlist-reasonable-p stmts))
;;                (:vl-seqblockstmt
;;                 (@wf-progn
;;                  (@wf-assert (and (not name)
;;                                   (atom decls))
;;                              :vl-unsupported-block
;;                              "Block contains a name or declarations, which we don't support yet."
;;                              nil)
;;                  (@wf-call vl-stmtlist-reasonable-p stmts)))
;;                (otherwise
;;                 (@wf-assert t)))))))

;;  (defwellformed vl-stmtlist-reasonable-p (x)
;;    :guard (vl-stmtlist-p x)
;;    :extra-decls ((xargs :measure (two-nats-measure (acl2-count x) 0)))
;;    :body (if (atom x)
;;              (@wf-assert t)
;;            (@wf-progn
;;             (@wf-call vl-stmt-reasonable-p (car x))
;;             (@wf-call vl-stmtlist-reasonable-p (cdr x))))))

;; (verify-guards vl-stmt-reasonable-p)
;; (verify-guards vl-stmt-reasonable-p-warn)



;; (defund vl-edge-eventcontrol-p (x)
;;   (declare (xargs :guard (vl-eventcontrol-p x)))

;; ; Recognizes event controls like @ (posedge clk) or @ (negedge clk)

;;   (let ((starp (vl-eventcontrol->starp x))
;;         (atoms (vl-eventcontrol->atoms x)))
;;     (and (not starp)
;;          (= (len atoms) 1)
;;          (let* ((atom (car atoms))
;;                 (type (vl-evatom->type atom))
;;                 (expr (vl-evatom->expr atom)))
;;            (declare (ignorable type))
;;            (and (or (eq type :vl-posedge)
;;                     (eq type :vl-negedge))
;;                 (vl-atom-p expr)
;;                 (vl-id-p (vl-atom->guts expr)))))))

;; (defund vl-edge-eventcontrol->type (x)
;;   (declare (xargs :guard (and (vl-eventcontrol-p x)
;;                               (vl-edge-eventcontrol-p x))
;;                   :guard-hints (("Goal" :in-theory (enable vl-edge-eventcontrol-p)))))
;;   (vl-evatom->type (car (vl-eventcontrol->atoms x))))

;; (defund vl-edge-eventcontrol->name (x)
;;   (declare (xargs :guard (and (vl-eventcontrol-p x)
;;                               (vl-edge-eventcontrol-p x))
;;                   :guard-hints (("Goal" :in-theory (enable vl-edge-eventcontrol-p)))))
;;   (vl-id->name
;;    (vl-atom->guts
;;     (vl-evatom->expr
;;      (car (vl-eventcontrol->atoms x))))))



;; (defund vl-nonedge-evatom-p (x)
;;   (declare (xargs :guard (vl-evatom-p x)))
;;   (let ((type (vl-evatom->type x))
;;         (expr (vl-evatom->expr x)))
;;     (and (eq type :vl-noedge)
;;          (vl-atom-p expr)
;;          (vl-id-p (vl-atom->guts expr)))))

;; (defund vl-nonedge-evatom->name (x)
;;   (declare (xargs :guard (and (vl-evatom-p x)
;;                               (vl-nonedge-evatom-p x))
;;                   :guard-hints (("Goal" :in-theory (enable vl-nonedge-evatom-p)))))
;;   (vl-id->name
;;    (vl-atom->guts
;;     (vl-evatom->expr x))))

;; (deflist vl-nonedge-evatomlist-p (x)
;;   (vl-nonedge-evatom-p x)
;;   :guard (vl-evatomlist-p x))

;; (defprojection vl-nonedge-evatomlist->names (x)
;;   (vl-nonedge-evatom->name x)
;;   :guard (and (vl-evatomlist-p x)
;;               (vl-nonedge-evatomlist-p x)))

;; (defund vl-nonedge-eventcontrol-p (x)
;;   (declare (xargs :guard (vl-eventcontrol-p x)))

;; ; Recognizes event controls such as @ (foo or bar or baz)

;;   (let ((starp (vl-eventcontrol->starp x))
;;         (atoms (vl-eventcontrol->atoms x)))
;;     (and (not starp)
;;          (consp atoms)
;;          (vl-nonedge-evatomlist-p atoms))))

;; (defund vl-nonedge-eventcontrol->names (x)
;;   (declare (xargs :guard (and (vl-eventcontrol-p x)
;;                               (vl-nonedge-eventcontrol-p x))
;;                   :guard-hints (("Goal" :in-theory (enable vl-nonedge-eventcontrol-p)))))
;;   (vl-nonedge-evatomlist->names (vl-eventcontrol->atoms x)))

;; (defund vl-eventcontrol-reasonable-p (x)
;;   (declare (xargs :guard (vl-eventcontrol-p x)))
;;   (or (vl-nonedge-eventcontrol-p x)
;;       (vl-edge-eventcontrol-p x)))



;; (defwellformed vl-always-reasonable-p (x)
;;   :guard (vl-always-p x)
;;   :body (let ((stmt (vl-always->stmt x)))
;;           (@wf-and

;; ; We expect it to be always @ ..., and do not try to support any other kind of
;; ; always statement.

;;            (@wf-assert (and (vl-compoundstmt-p stmt)
;;                             (eq (vl-compoundstmt->type stmt) :vl-ptctrlstmt)
;;                             (eq (tag (vl-compoundstmt->ctrl stmt)) :vl-eventcontrol)
;;                             (vl-eventcontrol-reasonable-p (vl-compoundstmt->ctrl stmt)))
;;                        :vl-always-badctrl
;;                        "~s0: not a good event-control, i.e., \"@(...)\"."
;;                        (list (vl-location-string (vl-always->loc x))))

;;            (@wf-call vl-stmt-reasonable-p (car (vl-compoundstmt->stmts stmt))))))

;; (defwellformed-list vl-alwayslist-reasonable-p (x)
;;   :element vl-always-reasonable-p
;;   :guard (vl-alwayslist-p x))


(defwellformed vl-module-reasonable-p (x)
  :parents (reasonable)
  :guard (vl-module-p x)
  :extra-decls ((xargs :guard-debug t))
  :body
  (b* (((vl-module x) x)
       (pdnames       (vl-portdecllist->names x.portdecls))
       (pdnames-s     (mergesort pdnames))
       (namespace     (vl-module->modnamespace x))
       (namespace-s   (mergesort namespace))
       (overlap       (intersect pdnames-s namespace-s))
       (palist        (vl-portdecl-alist x.portdecls))
       (ialist        (vl-moditem-alist x)))
    (@wf-progn
     (@wf-call vl-portlist-reasonable-p x.ports)
     (@wf-call vl-portdecllist-reasonable-p x.portdecls)
     ;; (@wf-call vl-ports-and-portdecls-compatible-p ports portdecls)
     (@wf-call vl-netdecllist-reasonable-p x.netdecls)
     (@wf-call vl-vardecllist-reasonable-p x.vardecls)
     (@wf-call vl-modinstlist-reasonable-p x.modinsts)
     (@wf-call vl-gateinstlist-reasonable-p x.gateinsts)
     (@wf-note (not x.initials)
               :vl-initial-stmts
               "~l0: module ~s1 contains initial statements."
               (list x.minloc x.name))

; Not really a problem anymore
;     (@wf-note (not alwayses)
;               :vl-always-stmts
;               "~l0: module ~s1 contains always statements."
;               (list minloc name))

;     (@wf-call vl-alwayslist-reasonable-p alwayses)
     (@wf-assert (mbe :logic (no-duplicatesp-equal namespace)
                      :exec (same-lengthp namespace namespace-s))
                 :vl-namespace-error
                 "~l0: ~s1 illegally redefines ~&2."
                 (list x.minloc x.name (duplicated-members namespace)))
     (@wf-call vl-overlap-compatible-p overlap x palist ialist))))

(defwellformed-list vl-modulelist-reasonable-p (x)
  :parents (reasonable)
  :guard (vl-modulelist-p x)
  :element vl-module-reasonable-p)


(define vl-module-check-reasonable
  :parents (reasonable)
  :short "Annotate a module with any warnings concerning whether it is @(see
reasonable).  Furthermore, if @('x') is unreasonable, a fatal warning to it."
  ((x vl-module-p))
  :returns (new-x vl-module-p :hyp :fguard)
  (b* (((when (vl-module->hands-offp x))
        x)
       (warnings          (vl-module->warnings x))
       ((mv okp warnings) (vl-module-reasonable-p-warn x warnings))
       (warnings          (if okp
                              (ok)
                            (fatal :type :vl-mod-unreasonable
                                   :msg "Module ~m0 is unreasonable."
                                   :args (list (vl-module->name x)))))
       (x-prime (change-vl-module x :warnings warnings)))
    x-prime))

(defprojection vl-modulelist-check-reasonable (x)
  (vl-module-check-reasonable x)
  :guard (vl-modulelist-p x)
  :result-type vl-modulelist-p
  :parents (reasonable))

(define vl-design-check-reasonable ((design vl-design-p))
  :returns (new-design vl-design-p)
  (b* ((design (vl-design-fix design))
       ((vl-design design) design)
       (new-mods (vl-modulelist-check-reasonable design.mods)))
    (change-vl-design design :mods new-mods)))

