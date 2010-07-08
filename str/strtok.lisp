; ACL2 String Library
; Copyright (C) 2009-2010 Centaur Technology
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

(in-package "STR")
(include-book "doc")
(local (include-book "make-event/assert" :dir :system))
(local (include-book "arithmetic"))
(local (include-book "unicode/revappend" :dir :system))

(defund strtok-aux (x n xl delimiters curr acc)
  ;; x is the string we're tokenizing, xl is its length
  ;; n is our current position in x
  ;; delimiters are the list of chars to split on
  ;; curr is the current word we're accumulating in reverse order
  ;; acc is the string list of previously found words
  (declare (type string x)
           (type integer n)
           (type integer xl)
           (xargs :guard (and (stringp x)
                              (natp xl)
                              (natp n)
                              (= xl (length x))
                              (<= n xl)
                              (character-listp delimiters)
                              (character-listp curr)
                              (string-listp acc))
                  :measure (nfix (- (nfix xl) (nfix n)))))
  (if (mbe :logic (zp (- (nfix xl) (nfix n)))
           :exec (= (the integer n)
                    (the integer xl)))
      (if curr
          (cons (reverse (coerce curr 'string)) acc)
        acc)
    (let* ((char1  (char x n))
           (matchp (member char1 delimiters)))
      (strtok-aux (the string x)
                  (mbe :logic (+ (nfix n) 1)
                       :exec (the integer (+ (the integer n) 1)))
                  (the integer xl)
                  delimiters
                  (if matchp nil (cons char1 curr))
                  (if (and matchp curr)
                      (cons (reverse (coerce curr 'string)) acc)
                    acc)))))

(defthm true-listp-of-strtok-aux
  (implies (true-listp acc)
           (true-listp (strtok-aux x n xl delimiters curr acc)))
  :hints(("Goal"
          :in-theory (enable strtok-aux)
          :induct (strtok-aux x n xl delimiters curr acc))))

(defthm string-listp-of-strtok-aux
  (implies (and (stringp x)
                (natp xl)
                (natp n)
                (= xl (length x))
                (<= n xl)
                (string-listp acc))
           (string-listp (strtok-aux x n xl delimiters curr acc)))
  :hints(("Goal"
          :in-theory (enable strtok-aux)
          :induct (strtok-aux x n xl delimiters curr acc))))

(defund strtok (x delimiters)
  ":Doc-Section Str
  Tokenize a string with character delimiters~/

  ~c[(strtok x delimiters)] splits the string ~c[x] into a list of substrings,
  based on ~c[delimiters], a list of characters.  This is somewhat similar to
  repeatedly calling the ~c[strtok] function in C.

  Example:
  ~bv[]
    (strtok \"foo bar, baz!\" (list #\\Space #\\, #\\!))
      -->
    (\"foo\" \"bar\" \"baz\")
  ~ev[]

  Note that no all of the characters in ~c[delimiters] are removed, and no
  empty strings are ever found in ~c[strtok]'s output.~/~/"

  (declare (xargs :guard (and (stringp x)
                              (character-listp delimiters))))
  (reverse (strtok-aux x 0 (length x) delimiters nil nil)))

(defthm true-listp-of-strtok
  (true-listp (strtok x delimiters))
  :rule-classes :type-prescription
  :hints(("Goal" :in-theory (enable strtok))))

(local (defthm lemma
         (implies (and (string-listp x)
                       (string-listp y))
                  (string-listp (revappend x y)))))

(defthm string-listp-of-strtok
  (implies (force (stringp x))
           (string-listp (strtok x delimiters)))
  :hints(("Goal" :in-theory (enable strtok))))


(local
 (acl2::assert!
  (equal (strtok "foo bar
baz,
 heyo,
    beyo"
                (list #\Space #\, #\Newline))
        (list "foo" "bar" "baz" "heyo" "beyo"))))

