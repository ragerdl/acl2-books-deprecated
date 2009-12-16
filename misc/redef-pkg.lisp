; Redef-pkg: UNSOUND Support for package redefinition.
; Matt Kaufmann and Jun Sawada, November, 2009

; While unsound in principle, redef-pkg can be useful during interactive
; sessions.  Usage:

; (redef-pkg name imports &optional doc book-path)
; where doc and book-path are ignored.

; Certify with:

; (certify-book "redef-pkg" 0 t :ttags (:redef-pkg))

; KNOWN FLAWS:

; - When importing only symbols already belong to the package, the new event
;   has no effect.

; - During the redefinition of the package, each imported symbol whose name was
;   already interned into the package must first be uninterned, so that the
;   imported symbol and the symbol with that name in the package can become one
;   and the same.  This can cause an ugly error message when printing the
;   function definitions using the uninterned symbols.  A warning will alert
;   the user to most cases of this, but it's still unfortunate.  Example log:

;      ACL2 !>(defpkg "TEST" '(cons car defun))
;  
;      Summary
;      Form:  ( DEFPKG "TEST" ...)
;      Rules: NIL
;      Warnings:  None
;      Time:  0.00 seconds (prove: 0.00, print: 0.00, other: 0.00)
;       "TEST"
;      ACL2 !>(in-package "TEST")
;       "TEST"
;      TEST !>(defun foo (x) (cons x x))
;  
;      Since FOO is non-recursive, its admission is trivial.  We observe that
;      the type of FOO is described by the theorem (COMMON-LISP::CONSP (FOO X)).
;      We used primitive type reasoning.
;  
;      Summary
;      Form:  ( DEFUN FOO ...)
;      Rules: ((:FAKE-RUNE-FOR-TYPE-SET COMMON-LISP::NIL))
;      Warnings:  None
;      Time:  0.01 seconds (prove: 0.00, print: 0.01, other: 0.00)
;       FOO
;      TEST !>(acl2::in-package "ACL2")
;       "ACL2"
;      ACL2 !>(include-book "misc/redef-pkg" :dir :system)
;  
;      TTAG NOTE (for included book): Adding ttag :REDEF-PKG from file /v/filer4b/v11q001/acl2/devel/books/misc/redef-pkg.lisp.
;  
;      ACL2 Warning [Ttags] in ( INCLUDE-BOOK "misc/redef-pkg" ...):  The
;      ttag note just printed to the terminal indicates a modification to
;      ACL2.  To avoid this warning, supply an explicit :TTAGS argument when
;      including the book "/v/filer4b/v11q001/acl2/devel/books/misc/redef-pkg.lisp".
;  
;      ; Fast loading /v/filer4b/v11q001/acl2/devel/books/misc/redef-pkg.fasl
;  
;      Summary
;      Form:  ( INCLUDE-BOOK "misc/redef-pkg" ...)
;      Rules: NIL
;      Warnings:  Ttags
;      Time:  0.01 seconds (prove: 0.00, print: 0.00, other: 0.01)
;       "/v/filer4b/v11q001/acl2/devel/books/misc/redef-pkg.lisp"
;      ACL2 !>(defpkg "TEST" '(cons car defun foo))
;  
;      Executing the redefined chk-acceptable-defpkg
;  
;      Debug: imports and package-entry-imports are different.
;      imports: (CAR CONS DEFUN FOO)
;      %package-entry-imports: (CAR CONS DEFUN)
;  
;      NOTE: Added the following list of symbols to package "TEST":
;       (FOO)
;  
;  
;      ACL2 Warning [Package] in ADD-SYMBOLS-TO-PKG:  The symbol with name
;      "FOO" imported into the "TEST" package may cause problems, since it
;      already has properties in the ACL2 world.
;  
;  
;      The event ( DEFPKG "TEST" ...) is redundant.  See :DOC redundant-events.
;  
;      Summary
;      Form:  ( DEFPKG "TEST" ...)
;      Rules: NIL
;      Warnings:  Package
;      Time:  0.00 seconds (prove: 0.00, print: 0.00, other: 0.00)
;       :REDUNDANT
;      ACL2 !>:pbt 0
;                0  (EXIT-BOOT-STRAP-MODE)
;                1  (DEFPKG "TEST" '#)
;       L        2  
;      ***********************************************
;      ************ ABORTING from raw Lisp ***********
;      Error:  The symbol FOO, which has no package, was encountered
;      by ACL2.  This is an inconsistent state of affairs, one that
;      may have arisen by undoing a defpkg but holding onto a symbol
;      in the package being flushed, contrary to warnings printed.
;  
;      ***********************************************
;  
;      If you didn't cause an explicit interrupt (Control-C),
;      then the root cause may be call of a :program mode
;      function that has the wrong guard specified, or even no
;      guard specified (i.e., an implicit guard of t).
;      See :DOC guards.
;  
;      To enable breaks into the debugger (also see :DOC acl2-customization):
;      (SET-DEBUGGER-ENABLE T)
;      ACL2 !>
;  
(in-package "ACL2")

(defttag :redef-pkg)

; Don't use this in a theorem!
(defun add-symbols-to-pkg (imports name)
  (declare (ignore imports name)
           (xargs :guard t :mode :program))
  nil)

(defmacro redef-pkg (name imports &optional doc book-path)
  (declare (ignore doc book-path))
  `(add-symbols-to-pkg ,imports ,name))

(progn!

(set-raw-mode-on state)

; Redefine add-symbols-to-pkg.
(defun add-symbols-to-pkg (syms pkg &aux (state *the-live-state*))
  (let ((pkg-entry0 (assoc-equal pkg *ever-known-package-alist*))
        (pkg-entry1 (assoc-equal pkg (known-package-alist *the-live-state*)))
        (syms (if (symbolp syms) (list syms) syms)))
    (when (or (null pkg-entry0)
              (null pkg-entry1))
      (error "Uknown pkg, ~s" pkg))
    (when (not (symbol-listp syms))
      (error "Not a symbol-listp: ~s" syms))
    (let ((imports0 (package-entry-imports pkg-entry0))
          (imports1 (package-entry-imports pkg-entry1))
          ans)
      (when (not (or (equal imports0 imports1)
                     (and (subsetp-eq imports0 imports1)
                          (subsetp-eq imports1 imports0))))
        (error "SURPRISE!  Different import lists.  Hmmmm......"))
      (let* ((new (set-difference-eq syms imports0))
             (sorted-symbols (sort-symbol-listp (append new imports0))))
        (setf (package-entry-imports
               (assoc-equal pkg *ever-known-package-alist*))
              sorted-symbols)
        (setf (package-entry-imports
               (assoc-equal pkg (known-package-alist *the-live-state*)))
              sorted-symbols)
        (dolist (sym new)
          (let ((temp (find-symbol (symbol-name sym) pkg)))
            (when temp
              (when (get temp *current-acl2-world-key*)
                (push (symbol-name temp) ans))
              (unintern temp pkg))))
        (fms "NOTE: Added the following list of symbols to package ~x0:~| ~
              ~x1~|~%"
             (list (cons #\0 pkg)
                   (cons #\1 new))
             (standard-co state) state nil)
        (when ans
            (warning$ 'add-symbols-to-pkg "Package"
                      "The symbol~#0~[ with name~/s with names~] ~&0 imported ~
                       into the ~x1 package may cause problems, since ~#0~[it ~
                       already has~/they already have~] properties in the ~
                       ACL2 world."
                      ans pkg))
        (import syms pkg)))))

; WARNING!  Update this if ACL2's def. of the following changes.
; (books/hacking/ has some sort of pattern-matching way to redefine functions
; that might be more robust.)
(defun chk-acceptable-defpkg (name form defpkg-book-path ctx w state)

; We return an error triple.  The non-error value is either 'redundant or a
; triple (tform value . package-entry), where tform and value are a translated
; form and its value, and either package-entry is nil in the case that no
; package with name name has been seen, or else is an existing entry for name
; in known-package-alist with field hidden-p=t (see the Essay on Hidden
; Packages).

  (fms "Executing the redefined chk-acceptable-defpkg~%" nil
       (standard-co state) state nil)

  (let ((package-entry
         (and (not (global-val 'boot-strap-flg w))
              (find-package-entry
               name
               (global-val 'known-package-alist w)))))
; I removed the case with the same `form' from the previous defpkg call,
; because the evaluation of `form' may results in a list with different
; symbols.  The case in which form is evaluated to the same imported 
; symbol list is processed as redundant at the end of the function.
;    (cond
;     ((and package-entry
;           (not (package-entry-hidden-p package-entry))
;           (equal (caddr (package-entry-defpkg-event-form package-entry))
;                  form))
;      (value 'redundant))
;     (t
      (mv-let
       (all-names state)
       (list-all-package-names state)
       (er-progn
        (cond
         ((or package-entry
              (eq (ld-skip-proofsp state) 'include-book))
          (value nil))
         ((not (stringp name))
          (er soft ctx
              "Package names must be string constants and ~x0 is not.  See ~
               :DOC defpkg."
              name))
         ((equal name "")

; In Allegro CL, "" is prohibited because it is already a nickname for the
; KEYWORD package.  But in GCL we could prove nil up through v2-7 by certifying
; the following book with the indicated portcullis:

; (in-package "ACL2")
;
; Portcullis:
; (defpkg "" nil)
;
; (defthm bug
;   nil
;   :hints (("Goal" :use ((:instance intern-in-package-of-symbol-symbol-name
;                                    (x '::abc) (y 17)))))
;   :rule-classes nil)

          (er soft ctx
              "The empty string is not a legal package name for defpkg."
              name))
         ((not (standard-char-listp (coerce name 'list)))
          (er soft ctx
              "~x0 is not a legal package name for defpkg, which requires the ~
               name to contain only standard characters."
              name))
         ((not (equal (string-upcase name) name))
          (er soft ctx
              "~x0 is not a legal package name for defpkg, which disallows ~
               lower case characters in the name."
              name))
         ((equal name "LISP")
          (er soft ctx
              "~x0 is disallowed as a a package name for defpkg, because this ~
               package name is used under the hood in some Common Lisp ~
               implementations."
              name))
         ((let ((len (length *1*-pkg-prefix*)))
            (and (<= len (length name))
                 (string-equal (subseq name 0 len) *1*-pkg-prefix*)))

; The use of string-equal could be considered overkill; probably equal provides
; enough of a check.  But we prefer not to consider the possibility that some
; Lisp has case-insensitive package names.  Probably we should similarly use
; member-string-equal instead of member-equal below.

          (er soft ctx
              "It is illegal for a package name to start (even ignoring case) ~
               with the string \"~@0\".  ACL2 makes internal use of package ~
               names starting with that string."
              *1*-pkg-prefix*))
         ((not (true-listp defpkg-book-path))
          (er soft ctx
              "The book-path argument to defpkg, if supplied, must be a ~
               true-listp.  It is not recommended to supply this argument, ~
               since the system makes use of it for producing useful error ~
               messages.  The defpkg of ~x0 is thus illegal."
              name))
         (t (value nil)))
        (cond
         ((and (member-equal name all-names)
               (not (global-val 'boot-strap-flg w))
               (not (member-equal name

; It seems very likely that the following value contains the same names as
; (strip-cars (known-package-alist state)), except for built-in packages, now
; that we keep hidden packages around.  But it seems harmless enough to keep
; this state global around.

                                  (f-get-global 'packages-created-by-defpkg
                                                state))))
          (er soft ctx
              "The package named ~x0 already exists and was not created by ~
               ACL2's defpkg.  We cannot (re)define an existing package.  See ~
               :DOC defpkg."
              name))
         (t
          (state-global-let*
           ((safe-mode

; In order to build a profiling image for GCL, we have observed a need to avoid
; going into safe-mode when building the system.

             (not (global-val 'boot-strap-flg w))))
           (er-let*
            ((pair (simple-translate-and-eval form nil nil
                                              "The second argument to defpkg"
                                              ctx w state)))
            (let ((tform (car pair))
                  (imports (cdr pair)))
              (cond
               ((not (symbol-listp imports))
                (er soft ctx
                    "The second argument of defpkg must eval to a list of ~
                     symbols.  See :DOC defpkg."))
               (t (let* ((imports (sort-symbol-listp imports))
                         (conflict (conflicting-imports imports))
                         (base-symbol (packn (cons name '("-PACKAGE")))))

; Base-symbol is the the base symbol of the rune for the rule added by
; defpkg describing the properties of symbol-package-name on interns
; with the new package.

                    (cond
                     ((member-symbol-name *pkg-witness-name* imports)
                      (er soft ctx
                          "It is illegal to import symbol ~x0 because its ~
                           name has been reserved for a symbol in the package ~
                           being defined."
                          (car (member-symbol-name *pkg-witness-name*
                                                   imports))))
                     (conflict
                      (er soft ctx
                          "The value of the second (imports) argument of ~
                           defpkg may not contain two symbols with the same ~
                           symbol name, e.g. ~&0.  See :DOC defpkg."
                          conflict))
                     (t (cond
                         ((and package-entry
                               (not (equal imports
                                           (package-entry-imports
                                            package-entry))))

;                         (er soft ctx
;                             "~@0"
;                             (tilde-@-defpkg-error-phrase
;                              name package-entry
;                              (set-difference-eq
;                               imports
;                               (package-entry-imports package-entry))
;                              (set-difference-eq
;                               (package-entry-imports package-entry)
;                               imports)
;                              (package-entry-book-path package-entry)
;                              defpkg-book-path w))

                          (progn (fms "Debug: imports and ~
                                       package-entry-imports are ~
                                       different.~|imports: ~
                                       ~x0~|%package-entry-imports: ~x1~|"
                                      (list (cons #\0 imports)
                                            (cons #\1 (package-entry-imports
                                                       package-entry)))
                                      (standard-co state) state nil)
                                 (add-symbols-to-pkg imports name)
                                 (value 'redundant)))
                         ((and package-entry
                               (not (package-entry-hidden-p package-entry)))
                          (prog2$
                           (chk-package-reincarnation-import-restrictions
                            name imports)
                           (value 'redundant)))
                         (t (er-progn
                             (chk-new-stringp-name 'defpkg name ctx w state)
                             (chk-all-but-new-name base-symbol ctx nil w state)

; Note:  Chk-just-new-name below returns a world which we ignore because
; we know redefinition of 'package base-symbols is disallowed, so the
; world returned is w when an error isn't caused.

; Warning: In maybe-push-undo-stack and maybe-pop-undo-stack we rely
; on the fact that the symbol name-PACKAGE is new!

                             (chk-just-new-name base-symbol
                                                'package nil ctx w state)
                             (prog2$
                              (chk-package-reincarnation-import-restrictions
                               name imports)
                              (value (list* tform
                                            imports
                                            package-entry ; hidden-p is true
                                            )))))))))))))))))))))

