; Copyright (C) 2013, Regents of the University of Texas
; Written by Matt Kaufmann (original date October, 2006)
; License: A 3-clause BSD license.  See the LICENSE file distributed with ACL2.

; NOTE: This book includes community book xdoc/top, and was created on top of
; separate book bash-bsd.lisp because xdoc/top had a GPL license.  That is no
; longer the case, but for simplicity we keep both books as is.  (Perhaps
; someone will want to eliminate bash-bsd.lisp.)

(in-package "ACL2")

(include-book "xdoc/top" :dir :system)

(include-book "bash-bsd")

(defxdoc bash
  :parents
  (proof-automation)
  :short "

<tt>Bash</tt> is a tool that simplifies a term, producing a list of
simplified terms such that if all output terms are theorems, then so is the
input term."

  :long "

<p>This utility is defined in community book <tt>\"misc/bash.lisp\"</tt>.  If
you submit <tt>(bash term)</tt> then roughly speaking, the result is a list of
goals produced by ACL2's simplification process.  That is, ACL2 might
reasonably be expected to produce these goals when simplifying <tt>term</tt>
during a proof attempt.  In particular, if the result is <tt>nil</tt>, then
<tt>term</tt> is a theorem.  More accurately: <tt>(bash term)</tt> returns an
<see topic=\"@(url ERROR-TRIPLES)\">error triple</see>, <tt>(mv nil val
state)</tt>, where <tt>val</tt> is a list of terms, in
untranslated (user-level) form, whose provability implies the provability of
the input term.  If ACL2 cannot simplify the input term (e.g., if there is a
translation error), then it prints a warning and returns <tt>(mv nil input-term
state)</tt>.</p>

<p>For a related utility, see @(see bash-term-to-dnf).</p>

<h3>Examples</h3>

<p>First we execute:
@({(include-book \"misc/bash\" :dir :system)})
Then:
@({
ACL2 !>(bash (equal (append x y) (append (car (cons x a)) z)))
Goal'
 ((EQUAL (APPEND X Y) (APPEND X Z)))
ACL2 !>(set-gag-mode nil) ; optional; turns off printing of goal names
<state>
ACL2 !>(bash (equal (append x y) (append (car (cons x a)) z)))
 ((EQUAL (APPEND X Y) (APPEND X Z)))
ACL2 !>(bash (equal (car (cons x y)) x))
 NIL
ACL2 !>(bash (implies (true-listp x) (equal (append x y) zzz))
             :hints ((\"Goal\" :expand ((true-listp x)
                                      (true-listp (cdr x))
                                      (append x y)))))
 ((EQUAL Y ZZZ)
  (IMPLIES (AND (CONSP X)
                (CONSP (CDR X))
                (TRUE-LISTP (CDDR X)))
           (EQUAL (LIST* (CAR X)
                         (CADR X)
                         (APPEND (CDDR X) Y))
                  ZZZ))
  (IMPLIES (AND (CONSP X) (NOT (CDR X)))
           (EQUAL (CONS (CAR X) Y) ZZZ)))
ACL2 !>(bash (equal x y))

ACL2 Warning [bash] in BASH:  Unable to simplify the input term.

 ((EQUAL X Y))
ACL2 !>(bash (equal x))

ACL2 Warning [bash] in BASH:  Unable to simplify the input term because
an error occurred.  Try setting the verbose flag to t in order to see
what is going on.

 ((EQUAL X))
ACL2 !>(bash (equal x) :verbose t)


ACL2 Error in BASH:  EQUAL takes 2 arguments but in the call (EQUAL X)
it is given 1 argument.   The formal parameters list for EQUAL is (X Y).


ACL2 Warning [bash] in BASH:  Unable to simplify the input term because
an error occurred.

 ((EQUAL X))
ACL2 !>
})</p>

<p>Here is how we might use this tool to simplify hypotheses.  First execute:

@({
 (defstub p1 (x) t)
 (defstub p2 (x) t)
 (defun p3 (x) (if (atom x) (p2 x) (p1 (car x))))
 (include-book
  \"misc/bash\" :dir :system)
})

Then:

@({
  ACL2 !>(bash (implies (and (p1 x) (p3 x))
                        (hide aaa)))
   ((IMPLIES (AND (P1 X) (CONSP X) (P1 (CAR X)))
             (HIDE AAA))
    (IMPLIES (AND (P1 X) (NOT (CONSP X)) (P2 X))
             (HIDE AAA)))
  ACL2 !>
})</p>

<h3>More details</h3>

<p>This utility is similar to the @(see proof-checker)'s <tt>bash</tt> command,
but for use in the top-level loop.  The input term can have user-level syntax;
it need not be translated.  The output is an error triple <tt>(mv nil termlist
state)</tt> such that either <tt>termlist</tt> is a one-element list containing
the input term, or else <tt>termlist</tt> is a list of term such that if each
term in this list is a theorem, then the input term is a theorem.  In practice,
these terms are produced by calling the prover with non-simplification
processes --- <tt>generalize</tt>, <tt>eliminate-destructors</tt>,
<tt>fertilize</tt> (heuristic use of equalities), and
<tt>eliminate-irrelevance</tt>, as well as induction --- turned off, and with
forcing rounds skipped (at least the first 15 of them).  A keyword argument,
<tt>:hints</tt>, can specify @(see hints) using their usual syntax, as with
@(see defthm).  The other keyword argument, <tt>:verbose</tt>, is <tt>nil</tt>
by default, to suppress output; use a non-<tt>nil</tt> value if you want
output, including the proof attempt.  The keyword values are not evaluated, so
for example <tt>:hints</tt> could be of the form <tt>((\"Goal\" ...))</tt> but
not <tt>'((\"Goal\" ...))</tt>.</p>

<p>We conclude with an note on the use of @(see hints) that may be important if
you use computed hints (see @(see computed-hints)).  Consider the following
example, supplied courtesy of Harsh Raju Chamarthi.

@({
 (defun drop (n l)
   (if (zp n)
     l
     (drop (1- n) (cdr l))))

 (include-book \"misc/bash\" :dir :system)

 ; Occur-fn returns the term that has fn has its function symbol.
 (mutual-recursion
  (defun occur-fn (fn term2)
    (cond ((variablep term2) nil)
          ((fquotep term2) nil)
          (t (or (and (eq fn (ffn-symb term2)) term2)
                 (occur-fn-lst fn (fargs term2))))))
  (defun occur-fn-lst (fn args2)
    (cond ((endp args2) nil)
          (t (or (occur-fn fn (car args2))
                 (occur-fn-lst fn (cdr args2)))))))

 ; Doesn't work as you might expect (see below):
 (bash (drop 3 x)
       :verbose t
       :hints ((if (occur-fn-lst 'drop clause)
                   `(:computed-hint-replacement
                     t
                     :expand
                     (,(occur-fn-lst 'drop clause)))
                 nil)))
})

The preceding call of <tt>bash</tt>, at the end of the displayed list of forms
above, causes the theorem prover to use destructor elimination, even though
that proof process is presumably turned off by <tt>bash</tt>.  What happened?
The problem is that the user-supplied hints are put in front of the hints
generated by <tt>bash</tt> to form the full list of hints given to the prover,
which cases the <tt>:do-not</tt> hint on \"Goal\" to be ignored.  Here is a
solution.

@({
 (bash (drop 3 x)
       :verbose t
       :hints ((if (occur-fn-lst 'drop clause)
                   `(:computed-hint-replacement
                     t
                     :do-not-induct :bash
                     :do-not (set-difference-eq *do-not-processes*
                                                '(preprocess simplify))
                     :expand (,(occur-fn-lst 'drop clause)))
                 '(:do-not-induct
                   :bash
                   :do-not
                   (set-difference-eq *do-not-processes*
                                      '(preprocess simplify))))))
})</p>")

(defxdoc bash-term-to-dnf
  :parents
  (proof-automation)
  :short "

<tt>Bash-term-to-dnf</tt> is a tool that simplifies a term, producing a list of
clauses such that if all output clauses are theorems, then so is the input
term."

  :long "

<p>This utility is defined in community book <tt>\"misc/bash.lisp\"</tt>.  We
assume here familiarity with the @('bash') tool defined in that book, focusing
below on how the present tool differs from that one.</p>

<p>If you submit <tt>(bash-term-to-dnf term)</tt> then the result is a list of
goals produced by ACL2's simplification process, much as for the result of
<tt>(bash term)</tt>; see @('bash').  However, unlike <tt>bash</tt>,
<tt>bash-term-to-dnf</tt> returns a list of <i>clauses</i>, where each clause
is a list of terms that represents the disjunction of those terms, and the list
of clauses is implicitly conjoined.</p>

<p>Again: For a related utility, see @('bash').</p>

<h3>Example</h3>

<p>First we execute:
@({(include-book \"misc/bash\" :dir :system)})
Then:
@({
ACL2 !>(bash-term-to-dnf
        '(implies (true-listp x) (equal (append x y) zzz))
        '((\"Goal\" :expand ((true-listp x)
                           (true-listp (cdr x))
                           (append x y))))
        nil t state)
 (((EQUAL Y ZZZ))
  ((NOT (CONSP X))
   (NOT (CONSP (CDR X)))
   (NOT (TRUE-LISTP (CDDR X)))
   (EQUAL (LIST* (CAR X)
                 (CADR X)
                 (APPEND (CDDR X) Y))
          ZZZ))
  ((NOT (CONSP X))
   (CDR X)
   (EQUAL (CONS (CAR X) Y) ZZZ)))
ACL2 !>
})</p>

<h3>General Form:</h3>

<p>@({(bash-term-to-dnf form hints verbose untranslate-flg state)})
returns a list of clauses, each of which is a list of terms, where:

<ul>

<li><tt>form</tt> is a user-level (untranslated) term;</li>

<li><tt>hints</tt>, if supplied, is a @(see hints) structure (as for
@('defthm'));</li>

<li><tt>verbose</tt> is <tt>nil</tt> by default, in which case output is
inhibited; on the other extreme, if <tt>verbose</tt> is <tt>:all</tt> then a
warning is printed when no simplification takes place; and</li>

<li><tt>untranslate-flg</tt> is <tt>nil</tt> by default, in which case each
term in each returned clause is a term in internal (translated) form and
otherwise, each such term is in user-level (untranslated) form;</li>

</ul>

If each returned clause (viewed as a disjunction) is a theorem, then the input
<tt>form</tt> is a theorem.</p>"
  )