; VL Verilog Toolkit
; Copyright (C) 2008-2011 Centaur Technology
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

(in-package "VL")
(include-book "writer")
(local (include-book "../util/arithmetic"))


(defsection vl-modelement-p
  :parents (vl-context-p)
  :short "Recognizer for an arbitrary module element."

  :long "<p>These are used in our @(see vl-context-p) to describe where an
expression occurs.</p>"

  (defund vl-modelement-p (x)
    (declare (xargs :guard t))
    (mbe :logic (or (vl-port-p x)
                    (vl-portdecl-p x)
                    (vl-assign-p x)
                    (vl-netdecl-p x)
                    (vl-vardecl-p x)
                    (vl-regdecl-p x)
                    (vl-eventdecl-p x)
                    (vl-paramdecl-p x)
                    (vl-modinst-p x)
                    (vl-gateinst-p x)
                    (vl-always-p x)
                    (vl-initial-p x))
         :exec (case (tag x)
                 (:vl-port      (vl-port-p x))
                 (:vl-portdecl  (vl-portdecl-p x))
                 (:vl-assign    (vl-assign-p x))
                 (:vl-netdecl   (vl-netdecl-p x))
                 (:vl-vardecl   (vl-vardecl-p x))
                 (:vl-regdecl   (vl-regdecl-p x))
                 (:vl-eventdecl (vl-eventdecl-p x))
                 (:vl-paramdecl (vl-paramdecl-p x))
                 (:vl-modinst   (vl-modinst-p x))
                 (:vl-gateinst  (vl-gateinst-p x))
                 (:vl-always    (vl-always-p x))
                 (:vl-initial   (vl-initial-p x)))))

  (local (in-theory (enable vl-modelement-p)))

  (defthm consp-when-vl-modelement-p
    (implies (vl-modelement-p x)
             (consp x))
    :rule-classes :compound-recognizer)

  (defthm vl-modelement-p-when-vl-port-p
    (implies (vl-port-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-portdecl-p
    (implies (vl-portdecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-assign-p
    (implies (vl-assign-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-netdecl-p
    (implies (vl-netdecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-vardecl-p
    (implies (vl-vardecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-regdecl-p
    (implies (vl-regdecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-eventdecl-p
    (implies (vl-eventdecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-paramdecl-p
    (implies (vl-paramdecl-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-modinst-p
    (implies (vl-modinst-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-gateinst-p
    (implies (vl-gateinst-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-always-p
    (implies (vl-always-p x)
             (vl-modelement-p x)))

  (defthm vl-modelement-p-when-vl-initial-p
    (implies (vl-initial-p x)
             (vl-modelement-p x)))

  (defthm vl-port-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-port)
                  (vl-modelement-p x))
             (vl-port-p x)))

  (defthm vl-portdecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-portdecl)
                  (vl-modelement-p x))
             (vl-portdecl-p x)))

  (defthm vl-assign-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-assign)
                  (vl-modelement-p x))
             (vl-assign-p x)))

  (defthm vl-netdecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-netdecl)
                  (vl-modelement-p x))
             (vl-netdecl-p x)))

  (defthm vl-vardecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-vardecl)
                  (vl-modelement-p x))
             (vl-vardecl-p x)))

  (defthm vl-regdecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-regdecl)
                  (vl-modelement-p x))
             (vl-regdecl-p x)))

  (defthm vl-eventdecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-eventdecl)
                  (vl-modelement-p x))
             (vl-eventdecl-p x)))

  (defthm vl-paramdecl-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-paramdecl)
                  (vl-modelement-p x))
             (vl-paramdecl-p x)))

  (defthm vl-modinst-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-modinst)
                  (vl-modelement-p x))
             (vl-modinst-p x)))

  (defthm vl-gateinst-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-gateinst)
                  (vl-modelement-p x))
             (vl-gateinst-p x)))

  (defthm vl-always-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-always)
                  (vl-modelement-p x))
             (vl-always-p x)))

  (defthm vl-initial-p-by-tag-when-vl-modelement-p
    (implies (and (equal (tag x) :vl-initial)
                  (vl-modelement-p x))
             (vl-initial-p x)))

  (defthm vl-modelement-p-when-invalid-tag
    (implies (and (not (equal (tag x) :vl-port))
                  (not (equal (tag x) :vl-portdecl))
                  (not (equal (tag x) :vl-assign))
                  (not (equal (tag x) :vl-netdecl))
                  (not (equal (tag x) :vl-vardecl))
                  (not (equal (tag x) :vl-regdecl))
                  (not (equal (tag x) :vl-eventdecl))
                  (not (equal (tag x) :vl-paramdecl))
                  (not (equal (tag x) :vl-modinst))
                  (not (equal (tag x) :vl-gateinst))
                  (not (equal (tag x) :vl-always))
                  (not (equal (tag x) :vl-initial)))
             (equal (vl-modelement-p x)
                    nil))
    :rule-classes ((:rewrite :backchain-limit-lst 0))))


(defsection vl-modelement-loc
  :parents (vl-modelement-p)
  :short "Get the location of any @(see vl-modelement-p)."

  (defund vl-modelement-loc (x)
    (declare (xargs :guard (vl-modelement-p x)))
    (case (tag x)
      (:vl-port      (vl-port->loc x))
      (:vl-portdecl  (vl-portdecl->loc x))
      (:vl-assign    (vl-assign->loc x))
      (:vl-netdecl   (vl-netdecl->loc x))
      (:vl-vardecl   (vl-vardecl->loc x))
      (:vl-regdecl   (vl-regdecl->loc x))
      (:vl-eventdecl (vl-eventdecl->loc x))
      (:vl-paramdecl (vl-paramdecl->loc x))
      (:vl-modinst   (vl-modinst->loc x))
      (:vl-gateinst  (vl-gateinst->loc x))
      (:vl-always    (vl-always->loc x))
      (:vl-initial   (vl-initial->loc x))
      (otherwise
       (prog2$ (er hard 'vl-modinst->loc "Impossible")
               *vl-fakeloc*))))

  (local (in-theory (enable vl-modelement-loc)))

  (defthm vl-location-p-of-vl-modelement-loc
    (implies (force (vl-modelement-p x))
             (vl-location-p (vl-modelement-loc x)))))


(defpp vl-pp-modelement-summary (x)
  :guard (vl-modelement-p x)
  :body
  (case (tag x)
    (:vl-port
     (let* ((name (vl-port->name x)))
       (if name
           (vl-ps-seq (vl-basic-cw "Port ")
                      (vl-print-wirename name))
         (vl-ps-seq (vl-basic-cw "Unnamed port at ")
                    (vl-print-loc (vl-port->loc x))))))

    (:vl-portdecl
     (vl-ps-seq (vl-basic-cw "Port declaration of ")
                (vl-print-wirename (vl-portdecl->name x))))

    (:vl-assign
     ;; As a dumb hack, we say if the lvalue is less than 40 characters long
     ;; when printed in text mode, we'll just print the whole thing using our
     ;; real pretty-printer.  But to avoid really long output, we elide lvalues
     ;; that are longer than this (and just print their text version).
     (let* ((orig (vl-pps-origexpr (vl-assign->lvalue x))))
       (vl-ps-seq (vl-basic-cw "Assignment to ")
                  (if (< (length orig) 40)
                      (vl-pp-origexpr (vl-assign->lvalue x))
                    (vl-print (str::cat (subseq orig 0 40) "...")))
                  (vl-basic-cw " at ")
                  (vl-print-loc (vl-assign->loc x)))))

    (:vl-netdecl
     (vl-ps-seq (vl-basic-cw "Net declaration of ")
                (vl-print-wirename (vl-netdecl->name x))))

    (:vl-vardecl
     (vl-ps-seq (vl-basic-cw "Var declaration of ")
                (vl-print-wirename (vl-vardecl->name x))))

    (:vl-regdecl
     (vl-ps-seq (vl-basic-cw "Reg declaration of ")
                (vl-print-wirename (vl-regdecl->name x))))
    (:vl-eventdecl
     (vl-ps-seq (vl-basic-cw "Event declaration of ")
                (vl-print-wirename (vl-eventdecl->name x))))

    (:vl-paramdecl
     (vl-ps-seq (vl-basic-cw "Param declaration of ")
                (vl-print-wirename (vl-paramdecl->name x))))

    (:vl-modinst
     (let* ((instname (vl-modinst->instname x))
            (modname  (vl-modinst->modname x)))
       (if instname
           (vl-ps-seq (vl-basic-cw "Instance ")
                      (vl-print-wirename instname)
                      (vl-basic-cw " of ")
                      (vl-print-modname modname))
         (vl-ps-seq (vl-basic-cw "Unnamed instance of ")
                    (vl-print-modname modname)
                    (vl-basic-cw " at ")
                    (vl-print-loc (vl-modinst->loc x))))))

    (:vl-gateinst
     (b* ((name  (vl-gateinst->name x))
          (type  (vl-gatetype-string (vl-gateinst->type x))))
       (if name
           (vl-ps-seq (vl-basic-cw "Gate ")
                      (vl-print-wirename name)
                      (vl-basic-cw (str::cat " of type " type)))
         (vl-ps-seq (vl-basic-cw (str::cat "Unnamed gate of type " type " at "))
                    (vl-print-loc (vl-gateinst->loc x))))))

    (:vl-always
     (vl-ps-seq (vl-basic-cw "Always statement at ")
                (vl-print-loc (vl-always->loc x))))

    (:vl-initial
     (vl-ps-seq (vl-basic-cw "Initial statement at ")
                (vl-print-loc (vl-initial->loc x))))

    (otherwise
     (prog2$ (er hard 'vl-pp-modelement-summary "Impossible")
             ps))))


(defsection vl-modelement-summary
  :parents (vl-modelement-p)
  :short "Produce a short, human-friendly description of a @(see vl-modelement-p)."
  :long "@(thm stringp-of-vl-modelement-summary)
@(def vl-modelement-summary)"

  (defund vl-modelement-summary (x)
    (declare (xargs :guard (vl-modelement-p x)))
    (with-local-ps (vl-pp-modelement-summary x)))

  (local (in-theory (enable vl-modelement-summary)))

  (defthm stringp-of-vl-modelement-summary
    (stringp (vl-modelement-summary x))
    :rule-classes :type-prescription))



(defaggregate vl-context
  (mod elem)
  :tag :vl-context
  :require ((stringp-of-vl-context->mod
             (stringp mod)
             :rule-classes :type-prescription)
            (vl-modelement-p-of-vl-context->elem
             (vl-modelement-p elem)))
  :parents (ctxexprs)
  :short "Description of where an expression occurs."
  :long "<p>The <tt>mod</tt> field names the module where this expression
was taken from.</p>

<p>The <tt>elem</tt> is a @(see vl-modelement-p) that describes more precisely
where the expression occurred in <tt>mod</tt>.</p>")



(defpp vl-pp-context-summary (x)
  :guard (vl-context-p x)
  :body
  (b* (((vl-context x) x))
    (vl-ps-seq (vl-print "In ")
               (vl-print-modname x.mod)
               (vl-println? ", ")
               (vl-pp-modelement-summary x.elem))))

(defsection vl-context-summary
  :parents (vl-context-p)
  :short "Produce a short, human-friendly description of a @(see vl-context-p)."
  :long "<p>See also @(see vl-modelement-summary) and @(see
vl-pp-context-full).</p>"

  (defund vl-context-summary (x)
    (declare (xargs :guard (vl-context-p x)))
    (with-local-ps (vl-pp-context-summary x)))

  (local (in-theory (enable vl-context-summary)))

  (defthm stringp-of-vl-context-summary
    (stringp (vl-context-summary x))
    :rule-classes :type-prescription))




(defpp vl-pp-modelement-full (x)
  ;; BOZO rename to vl-pp-
  :parents (vl-modelement-p)
  :short "Pretty-print a full @(see vl-modelement-p)"
  :guard (vl-modelement-p x)
  :body
  (case (tag x)
    (:vl-port      (vl-pp-port x))
    (:vl-portdecl  (vl-pp-portdecl x))
    (:vl-assign    (vl-pp-assign x))
    (:vl-netdecl   (vl-pp-netdecl x))
    (:vl-vardecl   (vl-pp-vardecl x))
    (:vl-regdecl   (vl-pp-regdecl x))
    (:vl-eventdecl (vl-print "// BOZO implement vl-pp-eventdecl in vl-pp-modelement-full"))
    (:vl-paramdecl (vl-print "// BOZO implement vl-pp-paramdecl in vl-pp-modelement-full"))
    (:vl-modinst   (vl-pp-modinst x nil nil))
    (:vl-gateinst  (vl-pp-gateinst x))
    (:vl-always    (vl-pp-always x))
    (:vl-initial   (vl-pp-initial x))
    (otherwise
     (prog2$ (er hard 'vl-pp-modelement "Impossible")
             ps))))

(defpp vl-pp-context-full (x)
  :parents (vl-context-p)
  :short "Pretty-print a longer description of where a @(see vl-context-p) occurs."
  :guard (vl-context-p x)
  :body
  (b* (((vl-context x) x))
      (vl-ps-seq
       (vl-print "In module ")
       (vl-print-modname x.mod)
       (vl-println ",")
       (vl-pp-modelement-full x.elem)
       (vl-println ""))))
