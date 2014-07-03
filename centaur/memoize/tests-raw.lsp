; Memoize Library
; Copyright (C) 2013 Centaur Technology
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
;
; This library is a descendant of the memoization scheme developed by Bob Boyer
; and Warren A. Hunt, Jr. which was incorporated into the HONS version of ACL2,
; sometimes called ACL2(h).

(in-package "MEMOIZE")

;; basic tests of return-value/argument stuff

(assert (equal (numargs 'length) 1))
(assert (equal (numargs 'binary-append) 2))
(assert (equal (numvals 'length) 1))
(assert (equal (numargs 'open-input-channel) 3))
(assert (equal (numvals 'open-input-channel) 2))

#+Clozure
(assert (equal (numargs 'numargs) 1))
#+Clozure
(assert (equal (numargs 'numvals) 1))

(assert (not (numargs 'frob)))
(assert (not (numvals 'frob)))
(declare-numargs 'frob 3 7)
(assert (equal (numargs 'frob) 3))
(assert (equal (numvals 'frob) 7))

;; some special forms that should not have fixed arities
(assert (not (numargs 'let)))
(assert (not (numargs 'let*)))
(assert (not (numargs 'append)))
(assert (not (numargs 'if)))
(assert (not (numargs 'return-last)))
(assert (not (numargs 'mv)))
(assert (not (numargs 'mv-let)))
(assert (not (numargs 'lambda)))

(assert (not (numvals 'let)))
(assert (not (numvals 'let*)))
(assert (not (numvals 'append)))
(assert (not (numvals 'if)))
(assert (not (numvals 'return-last)))
(assert (not (numvals 'mv)))
(assert (not (numvals 'mv-let)))
(assert (not (numargs 'lambda)))

;; basic time measurement accuracy

#||

commenting out this check for now, since it sometimes fails on certain machines.

(assert
 (let* ((start (ticks))
        (wait  (sleep 3))
        (end   (ticks))
        (secs  (/ (- end start) (ticks-per-second))))
   (format t "Measured time for sleeping 3 seconds: ~a~%" secs)
   (and (<= 2.8 secs)
        (<= secs 3.2))))

(assert
 (let* ((start (ticks))
        (wait  (sleep 2))
        (end   (ticks))
        (secs  (/ (- end start) (ticks-per-second))))
   (format t "Measured time for sleeping 2 seconds: ~a~%" secs)
   (and (<= 1.85 secs)
        (<= secs 2.15))))

(assert
 (let* ((start (ticks))
        (wait  (sleep 1))
        (end   (ticks))
        (secs  (/ (- end start) (ticks-per-second))))
   (format t "Measured time for sleeping 1 seconds: ~a~%" secs)
   (and (<= 0.9 secs)
        (<= secs 1.1))))

||#
