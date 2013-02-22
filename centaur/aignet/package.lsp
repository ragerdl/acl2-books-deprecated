; AIGNET - And-Inverter Graph Networks
; Copyright (C) 2013 Centaur Technology
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
; Original author: Sol Swords <sswords@centtech.com>

(in-package "ACL2")

(ld "cutil/package.lsp" :dir :system)
(ld "tools/flag-package.lsp" :dir :system)
(ld "centaur/satlink/package.lsp" :dir :system)

(defconst *aignet-exports*
  '(aignet-well-formedp
    aignet-extension-p
    aignet
    aignet2
    def-aignet-preservation-thms
    add-aignet-preservation-thm
    aignet-add-in
    def-aignet-frame
    aignet-add-in
    aignet-add-reg
    aignet-add-gate
    aignet-add-out
    aignet-add-regin
    aignet-init
    aignet-clear
    aignet-eval
    aignet-eval-frame
    aignet-copy-comb
    aignet-copy-frame
    aignet-vals
    aignet-copy
    aignet-copy-ins
    aignet-copy-regs
    aignet-copy-outs
    aignet-copy-regins
    aignet-print
    aignet-hash-and
    aignet-hash-or
    aignet-hash-xor
    aignet-hash-mux
    swap-aignets
    aig-sat))


(defpkg "AIGNET"
  (union-eq *acl2-exports*
            *common-lisp-symbols-from-main-lisp-package*
            *aignet-exports*
            '(nat-listp
              defconsts
              definline
              definlined
              defxdoc
              define
              defsection
              defmvtypes
              cutil::defprojection
              cutil::deflist
              b*
              aig-eval
              aig-not
              aig-and
              aig-xor
              aig-xor-lists
              aig-cases
              aig-vars
              aig-vars-1pass
              aig-restrict
              aig-restrict-list
              aig-restrict-alist
              lnfix lifix
              zz-sat
              zz-batch-sat
              aiger-read
              unsigned-byte-p
              signed-byte-p
              make-fast-alist
              alist-keys
              alist-vals
              with-fast
              with-fast-alist
              with-fast-alists
              nat-equiv
              nth-equiv
              value
              def-ruleset
              def-ruleset!
              add-to-ruleset
              enable*
              disable*
              e/d*
              e/d**
              cwtime
              local-stobjs
              def-array-set
              def-slot-set
              defiteration
              defstobj-clone
              x
              bitp bfix b-and b-xor b-ior b-not bit-equiv
              bitarr get-bit set-bit bits-length resize-bits bits-equiv)))