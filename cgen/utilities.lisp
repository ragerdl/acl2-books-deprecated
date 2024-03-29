#|$ACL2s-Preamble$;
(ld ;; Newline to fool ACL2/cert.pl dependency scanner
 "portcullis.lsp")

;;Bunch of utility functions for use by datadef and test?
;;mostly copied from data.lisp and acl2-check.lisp

(acl2::begin-book t);$ACL2s-Preamble$|#


(in-package "DEFDATA")

(set-verify-guards-eagerness 2)
(include-book "tools/bstar" :dir :system)
;(include-book "basis")

;;-- create a new symbol with prefix or suffix appended
;;-- if its a common-lisp symbol then attach acl2 package name to it
;;-- example:
;;-- (modify-symbol "NTH-" 'bool "") ==> NTH-BOOL
;;-- (modify-symbol "NTH-" 'boolean "") ==> ACL2::NTH-BOOLEAN
(defun modify-symbol (prefix sym postfix)
  (declare (xargs :guard (and (symbolp sym)
                              (stringp postfix)
                              (stringp prefix))))
  (let* ((name (symbol-name sym))
         (name (string-append prefix name))
         (name (string-append name postfix)))
    (if (member-eq sym *common-lisp-symbols-from-main-lisp-package*)
      (intern-in-package-of-symbol name 'acl2::acl2-pkg-witness)
      (intern-in-package-of-symbol name sym))))

(defun modify-symbol-lst (prefix syms postfix)
  (declare (xargs :guard (and (symbol-listp syms)
                              (stringp prefix)
                             (stringp postfix))))
  (if (endp syms)
    nil
    (cons (modify-symbol prefix (car syms) postfix)
          (modify-symbol-lst prefix (cdr syms) postfix))))



; utility fn to print if verbose flag is true 
(defmacro cw? (verbose-flag &rest rst)
  `(if ,verbose-flag
     (cw ,@rst)
     nil))




(defmacro   debug-flag  (vl)
  `(> ,vl 3))

(defmacro   system-debug-flag ( vl)
  `(> ,vl 4))

(defmacro   verbose-stats-flag ( vl)
  `(> ,vl 2)) 

(defmacro   verbose-flag ( vl)
  `(> ,vl 1))
  

(defmacro   inhibit-output-flag ( vl)
  `(<= ,vl 0))
  

(defmacro   normal-output-flag ( vl)
  `(> ,vl 0))



(defmacro acl2-getprop (name prop w &key default)
 `(getprop ,name ,prop ,default 'acl2::current-acl2-world ,w))


;;-- Returns a symbol representing the predicate of the parameter sym which is normally a type
;;-- (get-predicate-symbol 'integer) ==> INTEGERP
(defun get-predicate-symbol (sym)
  (declare (xargs :guard (symbolp sym)))
  (modify-symbol "" sym "P"))

;;-- (get-predicate-symbol-lst '(integer boolean rational)) ==> (INTEGERP BOOLEANP RATIONALP)
(defun get-predicate-symbol-lst (syms)
  (declare (xargs :guard (symbol-listp syms)))
  (if (endp syms)
    nil
    (cons (get-predicate-symbol (car syms))
          (get-predicate-symbol-lst (cdr syms)))))

(local
 (defthm valid-subseq-of-string-is-string
   (implies (and (stringp pname)
                 (< x (length pname))
                 (< y (length pname))
                 (<= x y))
            (stringp (subseq pname x y)))
   :rule-classes :type-prescription))

;;inverse operation of the above --added by harshrc
(defun get-typesymbol-from-pred-P-naming-convention (sym)
  (declare (xargs :guard (and (symbolp sym))
                  :guard-hints (("Goal" :in-theory (disable acl2::length acl2::subseq)))))

  (let* ((pred-name (acl2::symbol-name sym))
        (len-predname (acl2::length pred-name)))
    (if (and
         (< 1 len-predname) ;atleast have "p" and one more char
         (equal #\P (acl2::char pred-name (1- len-predname)))) ;WTF, smallcase p wouldnt work
      (let ((typename (acl2::subseq pred-name 0 (1- len-predname))));strip last char which is 'p'
        (intern-in-package-of-symbol typename sym))
      NIL))) ;TODO.Beware
      ;(er hard 'get-typesymbol-from-pred "~x0 doesnt follow our convention of predicates ending with 'p'.~%" sym))))




(defun or-list (lst)
  (if (atom lst)
    lst
    (or (car lst)
        (or-list (cdr lst)))))

(defun to-symbol-in-package (sym pkg-name)
  (declare (xargs :guard (and (symbolp sym)
                              (not (equal pkg-name ""))
                              (stringp pkg-name))))
  (intern$ (symbol-name sym) pkg-name))

(defun to-symbol-in-package-lst (sym-lst pkg)
  (declare (xargs :guard (and (symbol-listp sym-lst)
                              (not (equal pkg ""))
                              (stringp pkg))))
  (if (endp sym-lst)
      nil
    (cons (to-symbol-in-package (car sym-lst) pkg)
          (to-symbol-in-package-lst (cdr sym-lst) pkg))))


(defun cons-up-lists (l1 l2)
  (declare (xargs :guard (and (true-listp l1)
                              (true-listp l2)
                              (= (len l1)
                                 (len l2)))))
  "same as pairlis$"
  (if (endp l1)
    nil
    (cons (cons (car l1) (car l2))
          (cons-up-lists (cdr l1) (cdr l2)))))


;general
(defun list-up-lists (l1 l2)
  (declare (xargs :guard (and (true-listp l1)
                              (true-listp l2)
                              (= (len l1) (len l2)))))
  "same as listlis"
  (if (endp l1)
    nil
    (cons (list (car l1) (car l2))
          (list-up-lists (cdr l1) (cdr l2)))))


(verify-termination LEGAL-VARIABLE-OR-CONSTANT-NAMEP)
(verify-termination legal-constantp)
;;-- convert function lambda-keywordp from :program mode to :logic mode 
(verify-termination acl2::lambda-keywordp)
(verify-guards  acl2::lambda-keywordp)
(verify-guards legal-constantp)



;;--check arity of macro optional arguments 
(defun optional-macro-args-allow-arity (margs n)
  (declare (xargs :guard (and (true-listp margs) (integerp n))))
  (cond ((<= n 0)
         t)
        ((endp margs)
         nil)
        ((member-eq (car margs) '(&rest &body))
         t)
        ((acl2::lambda-keywordp (car margs))
         nil)
        (t
         (optional-macro-args-allow-arity (cdr margs) (1- n)))))

;;-- check arity of a macro 
(defun macro-args-allow-arity (margs n)
  (declare (xargs :guard (and (true-listp margs) (integerp n))))
  (cond ((< n 0)
         nil)
        ((endp margs)
         (= n 0))
        ((acl2::lambda-keywordp (car margs))
         (cond ((eq (car margs) '&whole)
                (macro-args-allow-arity (cdr margs) (1+ n)))
               ((eq (car margs) '&optional)
                (optional-macro-args-allow-arity (cdr margs) n))
               ((member-eq (car margs) '(&rest &body))
                t)
               ((member-eq (car margs) '(&key &allow-other-keys))
                (= n 0))
               (t
                nil)))
        (t
         (macro-args-allow-arity (cdr margs) (1- n)))))

;;-- check arity of any function or macro
(defun allows-arity (name n world)
  (declare (xargs :guard (and (symbolp name)
                              (natp n)
                              (plist-worldp world))))
  (if (function-symbolp name world)
    (= n (len (acl2-getprop name 'formals world)))
    (let ((margs (acl2-getprop name 'macro-args world
                               :default :undefined)))
      (and (true-listp margs)
           (macro-args-allow-arity margs n)))))

;EXTREMELY SLOW CALL because of getprop
(defun defined-fun-or-macrop (name world)
  (declare (xargs :guard (plist-worldp world)))
  (and (symbolp name)
       (or (function-symbolp name world)
           (true-listp (acl2-getprop name 'macro-args world
                                     :default :undefined)))))
                                

(defun allow-arity-lst (name-lst n world)
  (declare (xargs :guard (and (symbol-listp name-lst)
                              (natp n)
                              (plist-worldp world))))
  (or (endp name-lst)
      (and (allows-arity    (car name-lst) n world)
           (allow-arity-lst (cdr name-lst) n world))))

;;--check if 'name' is a predicate function
(defun plausible-predicate-functionp (name world)
  (declare (xargs :guard (and (symbolp name)
                              (plist-worldp world))))
  (allows-arity name 1 world))

(defun plausible-predicate-function-listp (name-lst world)
  (declare (xargs :guard (and (symbol-listp name-lst)
                              (plist-worldp world))))
  (or (endp name-lst)
      (and (plausible-predicate-functionp      (car name-lst) world)
           (plausible-predicate-function-listp (cdr name-lst) world))))

;;--check if x if a keyword list
(defun keyword-listp (x)
  (if (consp x)
    (and (keywordp (car x))
         (keyword-listp (cdr x)))
    (null x)))

(defun possible-constant-valuep (def)
  (declare (xargs :guard t))
  (if (consp def)
    ;quoted constant
    (and (eq 'quote (car def))
         (consp (cdr def))
         (null (cddr def)))
    (or (not (symbolp def));either acl2-number character string
        (keywordp def);a keyword
        (booleanp def);t or nil
        (legal-constantp def))))



(mutual-recursion
(defun constant-value-expressionp-lst (expr-lst wrld)
  (declare (xargs :guard (plist-worldp wrld)))
  (if (atom expr-lst)
    t
    (and (constant-value-expressionp (car expr-lst) wrld)
         (constant-value-expressionp-lst (cdr expr-lst) wrld))))

;very slow
(defun constant-value-expressionp (expr wrld)
   (declare (xargs :guard (plist-worldp wrld)))
  (cond ((null expr) t)
        ((possible-constant-valuep expr) t)
        ((atom expr) (possible-constant-valuep expr))
        ((not (defined-fun-or-macrop (car expr) wrld)) nil)
        (t (constant-value-expressionp-lst (cdr expr) wrld)))
    )
)


(mutual-recursion
(defun possible-constant-value-expressionp-lst (expr-lst)
  (if (atom expr-lst)
    t
    (and (possible-constant-value-expressionp (car expr-lst))
         (possible-constant-value-expressionp-lst (cdr expr-lst)))))

(defun possible-constant-value-expressionp (expr)
   (cond ((null expr) t);if nil
         ((possible-constant-valuep expr) t); if a constant
         ((atom expr) (possible-constant-valuep expr));if an atom, it has to go through this
         ((not (symbolp (car expr))) nil)
         (t (possible-constant-value-expressionp-lst (cdr expr))))
   )
)

; begin some auxilliary stuff for defdata

;get the predicate function symbol for a type-name if it exists
(defun er-get-predicate (type-name ctx wrld state)
  (declare (xargs :mode :program
                  :stobjs (state)
            :guard (and (symbolp type-name)
                              (symbolp ctx)
                              (plist-worldp wrld))))
  (let ((psym (get-predicate-symbol type-name)))
    (if (plausible-predicate-functionp psym wrld)
      (value psym)
      (er soft ctx
          "Predicate ~x0 for type ~x1 is not defined."
          psym type-name))))

;get the constant value associated with constant expression 'def'
(defun er-get-constant-value (def ctx wrld state)
  (declare (xargs :mode :program
                  :stobjs (state)
                  :guard (plist-worldp wrld)))
  (cond ((and (consp def)
             (eq 'quote (car def))
             (consp (cdr def))
             (null (cddr def)))
         (value (cadr def)))
        ((and (atom def)
              (or (not (symbolp def))
                  (keywordp def)
                  (booleanp def)))
         (value def))
        (t 
         (let ((p (acl2-getprop def 'const wrld)))
                               
           (if (and (symbolp def)
                    (quotep p))
               (value (cadr p))
             (er soft ctx "Illegal/undefined constant value: ~x0" def))))))

;;-- evaluates expr and returns its value if expr does not return a multi-value answer
(defun trans-eval-single-value (expr ctx state)
  (declare (xargs :mode :program
                  :stobjs (state)))
  (acl2::state-global-let*
   ((acl2::guard-checking-on :none))
   (er-let* ((ans (trans-eval expr ctx state t)));for now aok is t
     (if (equal (car ans) '(nil))
       (value (cdr ans))
       (er soft ctx "Expected a single return value in evaluation of ~x0."
           expr)))))

(local (defthm union-true-lists
         
         (implies (and (true-listp l1)
                       (true-listp l2))
                  (true-listp (union-equal l1 l2)))))

(defun union-lsts (lsts)
  (declare (xargs :mode :logic
                  :guard (true-list-listp lsts)))
  (if (endp lsts)
    nil
    (union-equal (car lsts)
                 (union-lsts (cdr lsts)))))
 
(defun assoc-lst (keys alist)
  (declare (xargs :guard (and (true-listp keys)
                              (alistp alist))))
  (if (endp keys)
    nil
    (cons (assoc-equal (car keys) alist)
          (assoc-lst (cdr keys) alist))))

(defun flatten (b lst&)
  (declare (xargs :guard (true-listp lst&)))
  (if (atom b)
    (cons b lst&)
    (flatten (car b) (flatten (cdr b) lst&))))

(defun mem1 (atm lst)
  (declare (xargs :guard (true-listp lst)))
  (if (endp lst)
    nil
    (if (equal atm (car lst))
      t
      (mem1 atm (cdr lst)))))

(defun mem-eq (v lst)
  (declare (xargs :guard (or (and (symbolp v)
                                  (true-listp lst))
                             (symbol-listp lst))))
  (if (endp lst)
    nil
    (if (eq v (car lst))
      t
      (mem-eq v (cdr lst)))))

(mutual-recursion
 (defun defbodyp (x)
   (or (symbolp x)
       (possible-constant-valuep x)
       (defbody-listp (cdr x))))
 (defun defbody-listp (xs)
   (if (atom xs)
     (equal xs nil)
     (and (defbodyp (car xs))
          (defbody-listp (cdr xs))))))

(include-book "misc/total-order" :dir :system)

(defun order-two-terms (t1 t2)
  (declare (xargs :guard t))
  (if (acl2::<< t1 t2);total order
      (mv t1 t2)
      (mv t2 t1)))

(defthm flatten-is-true-list 
  (implies (true-listp lst)
           (true-listp (flatten b lst)))
  :rule-classes :type-prescription)
(in-theory (disable flatten)) 

(defun true-list-alistp (x)
  (declare (xargs :guard t))
  (cond ((atom x) (eq x nil))
        (t (and (alistp (car x))
                (true-list-listp (cdr x))))))

(defun true-list-symbol-alistp (x)
  (declare (xargs :guard t))
  (cond ((atom x) (eq x nil))
        (t (and (symbol-alistp (car x))
                (true-list-symbol-alistp (cdr x))))))

         
;;self-explanatory
(defun symbol-doublet-list-listp (xs)
  (declare (xargs :guard t))
  (if (null xs)
    t
    (if (atom xs)
      nil
      (and (acl2::symbol-doublet-listp (car xs))
           (symbol-doublet-list-listp (cdr xs))))))

(defun symbol-alist-listp (x)
  (declare (xargs :guard T))
  (if (atom x)
    (null x)
    (and (symbol-alistp (car x))
         (symbol-alist-listp (cdr x)))))



(verify-termination ACL2::>=-LEN)
(verify-termination ACL2::ALL->=-LEN)
(verify-termination ACL2::>=-LEN ACL2::ALL->=-LEN)
(defun strip-cadrs (x)
  (declare (xargs :guard (acl2::all->=-len x 2)))
  (cond ((atom x) nil)
        (t (cons (cadar x)
                 (strip-cadrs (cdr x))))))





;utility funs
;boolean-or: Expr * Expr * ... -> Bool
(defun boolean-or-macro (lst)
  (if (consp lst)
    (list 'if
          (car lst)
          't
          (boolean-or-macro (cdr lst)))
    'nil))
;boolean-or: Expr * Expr * ... -> Bool
(defmacro boolean-or (&rest args)
  (boolean-or-macro args))


;; (defun is-simple-type-hyp (term wrld)
;; ;is a simple type hypothesis, and if true returns
;; ; the type-name (not the predicate itself)
;;   (declare (xargs :verify-guards nil))
;;   (and (consp term)
;;        (eql (len term) 2)
;;        (atom (cadr term))
;;        (is-a-variablep (cadr term)) ;check wether its arg is sa variable 
;;        (plausible-predicate-functionp (car term) wrld)
;;        (is-type-predicate (car term) wrld))) ;check if its a type predicate


;NEEDED BY EVERYONE:
  
; 12/4/2012, Matt K.: Omitting the definitions of nat-listp and
; acl2-number-listp, which are being built into ACL2.

(defun naturals-listp (x)
   (declare (xargs :guard t))
  (if (atom x)
    (null x)
    (and (natp (car x))
         (naturals-listp (cdr x)))))

; already in program mode:
(DEFUN POS-LISTP (acl2::L)
   (declare (xargs :guard t))
  (COND ((ATOM acl2::L) (EQ acl2::L NIL))
        (T (AND (POSP (CAR acl2::L))
                (POS-LISTP (CDR acl2::L))))))

;; del: All tlp -> tlp
;; signature: (a X)
;; removes the first occurrence of a from X
(defun del (a X)
  (declare (xargs :guard (true-listp X)))
  (cond ((endp X) nil)
        ((equal a (car X)) (cdr X))
        (t (cons (car X) (del a (cdr X))))))

(defun rev-acc (X acc)
  (declare (xargs :guard (true-listp X)))
  (if (endp X)
    acc
    (rev-acc (cdr X) (cons (car X) acc))))

(defun rev (X)
  (declare (xargs :guard (true-listp X)))
  (rev-acc X nil))

;is x permutation of y 
(defun permutation (xs ys)
  (declare (xargs :verify-guards nil))
  (cond ((atom xs) (atom ys)) 
        (t (and (mem1 (car xs) ys) (permutation (cdr xs) (del (car xs) ys)))))) 

(defun get-value-from-keyword-value-list (key kv-lst)
  (declare (xargs :guard (keyword-value-listp kv-lst)))
  (second (assoc-keyword key kv-lst)))



;Sig: Any -> Bool
;check wether arg is a variable 
(defun is-a-variablep (x)
  (declare (xargs :guard t))
  (and (symbolp x)
       (not (or (keywordp x);a keyword
                (booleanp x);t or nil
                (legal-constantp x)))));ACL2::CONSTANT


;NOTE PACKAGES are very IMP while assuming that symbols are all ACL2. Like
;I just fixed a bug, where 'CONSTANT was assumed in ACL2 package, but due to
;this book being in DEFDATA PACKAGE, the equality check is against the symbol
;DEFDATA::CONSTANT which not same as ACL2::CONSTANT resulting in treating
;t and nil as variables.

;;list the free variables in a term
(mutual-recursion
;; code taken from structures.lisp in data-structures book.
 (defun get-free-vars1 (term ans)
    (declare (xargs :verify-guards nil
                    :guard (and (or (atom term)
                                    (true-listp term))
                                (true-listp ans)
                                )))
   "A free variable is a symbol that is not a constant, i.e., it excludes T,
    NIL, and *CONST*, and keywords"
   (cond
    ((atom term) (if (is-a-variablep term)
                   (add-to-set-eq term ans)
                   ans))
    ((eq (car term) 'QUOTE) ans)
    (t (get-free-vars1-lst (cdr term) ans))))
 
 (defun get-free-vars1-lst (terms ans)
    (declare (xargs :guard (and (true-listp terms)
                                (or (atom (car terms))
                                    (true-listp (car terms)))
                                (true-listp ans)
                                )))
   (cond
    ((endp terms) ans)
    (t (get-free-vars1-lst (cdr terms) 
                           (get-free-vars1 (car terms) ans))))))

;auxiliary function for get-free-vars
(defun get-free-vars0 (form state)
  (declare (xargs :mode :program 
                  :stobjs (state)))
  (if (acl2::termp form (w state))
; had a bug due to namespace change
     (value (get-free-vars1 form '())) 
; translate the form into a term
     (er-let* ((term (acl2::translate form t nil t 
                                'get-free-vars (w state) state))) 
       (value (get-free-vars1 term '())))))
    
;get list of free variables in acl2 expression 'form'
(defmacro get-free-vars (form)
  `(get-free-vars0 ,form state)) 



;filter typ-exps which are typenames
(defun filter-alist-keys (alst wanted-keys)
  (declare (xargs :guard (and (alistp alst)
                              (true-listp wanted-keys))))
  (if (endp alst)
    nil
    (let* ((key (caar alst))
           (we-want-to-add  (mem1 key wanted-keys)))
      (if we-want-to-add 
        (cons (car alst);cons the wanted entry
              (filter-alist-keys (cdr alst) wanted-keys))
        (filter-alist-keys (cdr alst) wanted-keys)))))


(defun remove-entry (key alist)
  (declare (xargs  :guard (and (alistp alist))))
  (if (endp alist)
    nil
    (if (equal key (caar alist))
      (cdr alist)
      (cons (car alist)
            (remove-entry key (cdr alist))))))

(defun remove-entry-lst (keys alist)
  (declare (xargs  :guard (and (true-listp keys)
                               (alistp alist))))
  (if (endp keys)
    alist
    (remove-entry-lst (cdr keys) 
                      (remove-entry (car keys) alist))))

;get value of key in alist
(defun get-val (key alist)
  (declare (xargs  :guard (and (alistp alist))))
  (if (endp alist)
    nil
    (if (equal key (caar alist))
      (cdar alist)
      (get-val key (cdr alist)))))

;recurse on above
(defun get-val-lst (keys alist)
  (declare (xargs  :guard (and (true-listp keys)
                               (alistp alist))))
  (if (endp keys)
      nil
    (let ((found-val (get-val (car keys) alist)))
      (if found-val
        (cons found-val
              (get-val-lst (cdr keys) alist))
        (get-val-lst (cdr keys) alist)))))

;if val is different, then add it at the very end,
;do not update in place. Assumes unique entries
(defun remove-and-add-at-end-entry (key val alist)
  (declare (xargs  :guard (alistp alist)))
  (if (endp alist)
    (list (cons key val))
    (let* ((curr-entry (car alist))
           (curr-key (car curr-entry))
           (curr-val (cdr curr-entry)))
      (if (not (equal key curr-key))
        (cons curr-entry
              (remove-and-add-at-end-entry key val (cdr alist)))
        (if (equal val curr-val)
          alist;return unchanged
          (remove-and-add-at-end-entry key val (cdr alist)))))))

(defun remove-and-add-at-front-entry (key val alist)
  (declare (xargs  :guard (alistp alist)))
  (cons (cons key val)
        (remove-entry key alist)))
  
;put the key val entry in alist(overwrite)
;assumes unique entries
(defun put-entry (key val alist)
  (declare (xargs  :guard (alistp alist)))
  (if (endp alist)
    (list (cons key val))
    (if (equal key (caar alist))
      (cons (cons key val)
            (cdr alist))
      (cons (car alist)
            (put-entry key val (cdr alist))))))


  
;get key having value val in alist
(defun get-key (val alist)
  (declare (xargs  :guard (alistp alist)))
  (if (endp alist)
      nil
    (if (equal val (cdar alist))
      (caar alist)
      (get-key val (cdr alist)))))

;recurse on above, in order of vals.
(defun get-key-lst (vals alist)
  (declare (xargs  :guard (and (true-listp vals)
                               (alistp alist))))
  (if (endp vals)
    nil
    (let ((found-key (get-key (car vals) alist)))
      (if found-key
        (cons found-key
              (get-key-lst (cdr vals) alist))
        (get-key-lst (cdr vals) alist)))))

(defun get-var-from-i-or-is-lst (is var-i-alst)
  (declare (xargs  :verify-guards nil))
  (if (endp is)
    nil
    (let ((i (car is)))
      (if (atom i)
        (let ((found-key (get-key i var-i-alst)))
          (if found-key
            (cons found-key (get-var-from-i-or-is-lst (cdr is) var-i-alst))
            (get-var-from-i-or-is-lst (cdr is) var-i-alst)))
        ;else its a nat-listp
        (let ((found-keys (get-key-lst i var-i-alst)))
          (if found-keys
            (cons found-keys (get-var-from-i-or-is-lst (cdr is) var-i-alst))
            (get-var-from-i-or-is-lst (cdr is) var-i-alst)))))))
              

;returns list of all keys matching val
(defun get-all-keys1 (val alist ans)
  (declare (xargs  :guard (alistp alist)))
  (if (endp alist)
      ans;return answer
    (let* ((entry (car alist))
           (key (car entry))
           (value (cdr entry)))
      (if (equal val value)
        (get-all-keys1 val (cdr alist) (cons key ans));accumulate keys and recurse
      (get-all-keys1 val (cdr alist) ans)))));recurse

(defun get-all-keys (val alist)
  (declare (xargs  :guard (alistp alist)))
  (get-all-keys1 val alist nil))

;recurse on above, in order of vals.
(defun get-all-keys-lst (vals alist)
  (declare (xargs  :guard (and (true-listp vals)
                               (alistp alist))))
  (if (endp vals)
    nil
    (let ((found-keys (get-all-keys (car vals) alist)))
      (if found-keys
        (cons found-keys
              (get-all-keys-lst (cdr vals) alist))
        (get-all-keys-lst (cdr vals) alist)))))


;from Matt ;TODO get rid of this
(defun trans-eval2 (form ctx state)
  (declare (xargs :mode :program :stobjs state))
  (acl2::state-global-let*
   ((acl2::guard-checking-on :none))
   (mv-let
    (erp trans bindings state)
    (acl2::translate1 form
                      t nil
                      t
                      'top-level (w state) state)
    (declare (ignore bindings))
    (cond
     (erp (mv t nil state))
     (t
      (let ((vars (all-vars trans)))
        (cond
         ((acl2::non-stobjps vars t (w state)) ;;; known-stobjs = t
          (er soft 'top-level
              "Global variables, such as ~&0, are not allowed. See ~
               :DOC ASSIGN and :DOC @."
              (acl2::non-stobjps vars t (w state)))) ;;; known-stobjs = t
         (t (acl2::ev-for-trans-eval trans vars nil ctx state t))))))))) 

;returns (cdr (cons translated-term value)) == value of term under bindings
(defun trans-eval-single-value-with-bindings (term bindings ctx state)
  (declare (xargs :mode :program :stobjs state))
  (acl2::state-global-let*
   ((acl2::guard-checking-on :none))
   (er-let* ((term-val (acl2::simple-translate-and-eval term bindings nil
                                                        "" ctx (w state) state t)))
     (value (cdr term-val)))))

; this function basically creates in one go cons bindings 
; for a list of variable names
(defun make-var-value-cons-bindings (var-lst ans)
  (declare (xargs :guard (and (symbol-listp var-lst)
                              (true-listp ans))))
  (if (endp var-lst)
    (cons 'list ans)
    (let ((var (car var-lst)))
      (make-var-value-cons-bindings (cdr var-lst)
                                    (append ans (list `(cons ',var ,var)))))))

; this function basically creates in one go list bindings for 
; a list of variable names
(defun make-var-value-list-bindings (var-lst ans)
  (declare (xargs :guard (and (symbol-listp var-lst)
                              (true-listp ans))))
  (if (endp var-lst)
    (cons 'list ans)
    (let ((var (car var-lst)))
      (make-var-value-list-bindings 
       (cdr var-lst)
       (append ans (list `(list ',var ,var)))))));changed to mimic let binding

; needed for simple-translate-and-eval only.
; Not needed now!!
(defun make-constant-value-cons-bindings (var-lst constant-val ans)
  (declare (xargs :guard (and (symbol-listp var-lst)
                              (true-listp ans))))
  (if (endp var-lst)
    (cons 'list ans)
    (let ((var (car var-lst)))
      (make-constant-value-cons-bindings 
       (cdr var-lst)
       constant-val
       (append ans (list (cons var constant-val)))))))

;needed for trans-eval
(defun make-constant-value-let-bindings (var-lst constant-val ans)
  (declare (xargs :guard (and (symbol-listp var-lst)
                              (true-listp ans))))
  (if (endp var-lst)
    ans
    (let ((var (car var-lst)))
      (make-constant-value-let-bindings 
       (cdr var-lst)
       constant-val
       (append ans (list (list var constant-val)))))))



;;self-explanatory
(defun convert-listpair-to-conspair-lst (listpairs)
  (declare (xargs :guard (acl2::symbol-doublet-listp listpairs)))
  (if (endp listpairs)
    nil
    (cons (let* ((lstpair (car listpairs))
                 (fst (car lstpair))
                 (snd (cadr lstpair)))
            (cons fst snd))
          (convert-listpair-to-conspair-lst (cdr listpairs)))))


; self-explanatory
; convert ((a . b) ...) to ((a b) ...)
(defun convert-conspairs-to-listpairs (conspairs)
  (declare (xargs :guard (symbol-alistp conspairs)))
  (if (endp conspairs)
    nil
    (cons (let* ((conspair (car conspairs))
                 (fst (car conspair))
                 (snd (cdr conspair)))
            (list fst snd))
          (convert-conspairs-to-listpairs (cdr conspairs)))))

(defthm convert-conspairs-to-listpairs-sig1
  (implies (symbol-alistp P)
           (symbol-doublet-listp (convert-conspairs-to-listpairs P)))
  :rule-classes (:rewrite :type-prescription :forward-chaining))

(defthm symbol-doublet-listp-implication1
  (implies (and (symbol-doublet-listp A)
                (consp A))
           (and (consp (car A))
                (symbolp (caar A))
                (consp (cdr (car A)))
                (null (cddr (car A)))))
  :rule-classes (:forward-chaining :type-prescription))

(defun count-occurrences (v lst)
  (declare (xargs :guard (true-listp lst)))
  (if (endp lst)
    0
    (if (equal v (car lst))
      (1+ (count-occurrences v (cdr lst)))
      (count-occurrences v (cdr lst)))))

(defun sym-eq-lst (syms1 syms2)
  (declare (xargs :guard (and (symbol-listp syms1)
                              (symbol-listp syms2))))
  "returns first symbol in syms2 which is in syms1 o.w nil"
  (if (endp syms2)
    nil
    (if (mem1 (car syms2) syms1)
      (car syms2)
      (sym-eq-lst syms1 (cdr syms2)))))

(defun insert-entry-after-key (entry k alst)
  (declare (xargs :guard (and (symbolp k)
                              (symbol-alistp alst))))
  "insert entry immediately after the pair in alst having key k"
  (if (endp alst)
   (list entry)
    (if (eq k (caar alst))
      (cons (car alst)
            (cons entry (cdr alst)))
      (cons (car alst)
           (insert-entry-after-key entry k (cdr alst)))))) 

(defun get-ordered-alst (keys alst ans)
  (declare (xargs :guard (and (true-listp keys) (alistp ans) (alistp alst))))
  "accumulate entries of alist in ans in the order of keys"
  (if (endp keys)
    ans
    (let ((at (assoc-equal (car keys) alst)))
      (if at
        (get-ordered-alst (cdr keys) alst (append ans (list at)))
        (get-ordered-alst (cdr keys) alst ans)))))


;filter all elements in lst that are IN in-lst
(defun filter-in (lst in-lst)
  (declare (xargs :guard (and (true-listp lst)
                              (true-listp in-lst))))
  (if (endp lst)
      nil
    (if (defdata::mem1 (car lst) in-lst)
        (cons (car lst) (filter-in (cdr lst) in-lst))
      (filter-in (cdr lst) in-lst))))
;filter all elements in lst that are NOT IN in-lst 
(defun filter-not-in (lst in-lst)
  (declare (xargs :guard (and (true-listp lst)
                              (true-listp in-lst))))
  (if (endp lst)
      nil
    (if (not (defdata::mem1 (car lst) in-lst))
        (cons (car lst) (filter-in (cdr lst) in-lst))
      (filter-in (cdr lst) in-lst))))

;self-explanatory code.
;compose 2 finite functions basically
(defun compose-two-alists (a-b-alst b-c-alst)
  (declare (xargs :guard (and (alistp a-b-alst)
                              (alistp b-c-alst))))
   (if (endp a-b-alst)
    nil
    (let* ((a-b (car a-b-alst))
           (a (car a-b))
           (b (cdr a-b))
           (c (defdata::get-val b b-c-alst))
           (a-c (cons a c)))
      (cons a-c
            (compose-two-alists (cdr a-b-alst) b-c-alst)))))

;just like subst, but uses equal for comparision.
(defun subst-equal (new old tree)
  (cond ((equal tree old) new)
        ((atom tree) tree)
        (t (cons (subst-equal new old (car tree))
                 (subst-equal new old (cdr tree))))))


(mutual-recursion
;(ev-fncall-w FN ARGS W SAFE-MODE GC-OFF HARD-ERROR-RETURNS-NILP AOK)
;I use sumners default values for
;               nil    ; safe-mode
;               t      ; gc-off
;               nil    ; hard-error-returns-nilp
;               nil    ; aok


(defun my-ev-w (term alist ctx w hard-error-returns-nilp)
"special eval function that does not need state and 
cannot handle if, return-last,mv-list, stobjs, wormhole etc
very restrictive
Mainly to be used for evaluating enum lists "
;Close to ev-rec in translate.lisp
(declare (xargs :mode :program
                :guard (and (acl2::termp term w)
                            (plist-worldp w)
                            (symbol-alistp alist)
                            (booleanp hard-error-returns-nilp))))
 
(b* (((when (acl2::variablep term))
;variable expression
      (let ((v (assoc-eq term alist))) ;bugfix (removed cdr).
;(earlier, if term had a value NIL, we were errorneusly
;crashing!!!
        (if v ;not null 
          (mv nil (cdr v))
          (prog2$
           (er hard ctx "Unbound variable ~x0.~%" term)
           (mv t term)))))
;quoted expression
     ((when (acl2::fquotep term))
      (mv nil (cadr term)))
;if expression
     ((when (eq (car term) 'if))
      (prog2$ 
       (er hard ctx "IF expressions not supported at the moment.~%")
       (mv t term)))
;function expression
     ((mv args-er args)
      (my-ev-w-lst (cdr term) alist ctx
                   w hard-error-returns-nilp))
     ((when args-er)
      (prog2$ 
       (er hard ctx "Eval args failed~%")
       (mv t term)))
     ((when (acl2::flambda-applicationp term))
      (my-ev-w (acl2::lambda-body (car term))
               (acl2::pairlis$ (acl2::lambda-formals (car term)) args)
               ctx w hard-error-returns-nilp)))
    (acl2::ev-fncall-w (car term) args w
                       nil nil t hard-error-returns-nilp nil)))

(defun my-ev-w-lst (term-lst alist 
                             ctx w hard-error-returns-nilp)
"special eval function that does not need state and 
cannot handle return-last,mv-list, stobjs, wormhole etc
very restrictive
Mainly to be used for evaluating enum lists "
;Close to ev-rec-lst in translate.lisp
(declare (xargs :mode :program
                :guard (and (acl2::term-listp term-lst w)
                            (plist-worldp w)
                            (symbol-alistp alist)
                            (booleanp hard-error-returns-nilp))))
(if (endp term-lst)
    (mv nil nil)
  (b* (((mv erp1 car-ans) 
        (my-ev-w (car term-lst) alist 
                 ctx w hard-error-returns-nilp))
       ((when erp1) 
        (prog2$ 
         (er hard ctx "eval ~x0 failed~%" (car term-lst))
         (mv t term-lst)))
       ((mv erp2 cdr-ans) 
        (my-ev-w-lst (cdr term-lst) alist 
                     ctx w hard-error-returns-nilp))
       ((when erp2) 
        (prog2$ 
         (er hard ctx "eval failed~%")
         (mv t term-lst))))
    (mv nil (cons car-ans cdr-ans)))))
)
  

(defun trans-my-ev-w (form ctx w hard-error-returns-nilp)
(declare (xargs :mode :program
                :guard (and (plist-worldp w)
                            (booleanp hard-error-returns-nilp))))

  (mv-let 
   (erp term x) 
   (acl2::translate11 form nil nil nil nil nil
                ctx w (acl2::default-state-vars nil))
   (declare (ignore x))
   (if erp
       (if hard-error-returns-nilp
           (mv erp form)
         (prog2$ 
          (er hard ctx "~x0 could not be translated.~%" form)
          (mv erp form)))
     (my-ev-w term nil ctx w hard-error-returns-nilp))))

(defun all-vars-in-var-term-alst (alst)
  (declare (xargs :guard (alistp alst)
                  :verify-guards nil
                              ))
  ;key might be a term in case of generalization TODO.CHECK
;value is always a term, so we gets free-vars from them 
  (union-eq (get-free-vars1-lst (strip-cars alst) nil)
            (get-free-vars1-lst (strip-cdrs alst) nil)))

;collect matching key-value pairs in an alist
;if var in 'vars' has a value in 'bindings', then collect it
(defun occurring-var-bindings (bindings vars)
  (declare (xargs :guard (and (true-listp vars)
                              (symbol-alistp bindings))))
  (if (endp vars)
    nil
    (let ((b (assoc-eq (car vars) bindings)))
      (if b
        (cons b (occurring-var-bindings bindings (cdr vars)))
        (occurring-var-bindings bindings (cdr vars))))))


; every cons(that is not quoted) and list in the value list 
; bindings is quoted to avoid errors in evaluation
(defun quote-conses-and-symbols-in-bindings (val-bs)
;val-bs is kind of let binding
  (declare (xargs :guard (symbol-doublet-listp val-bs)))
  (if (endp val-bs)
    nil
    (b* (((list var val) (car val-bs)))
      (if (or (symbolp val)
              (and (consp val) (not (equal (car val) 'quote))))
        (cons (list var (list 'quote val))
              (quote-conses-and-symbols-in-bindings (cdr val-bs)))
        (cons (list var val) 
              (quote-conses-and-symbols-in-bindings (cdr val-bs)))))))

(defun filter-symbol-keys-in-alist (alst)
  "Given an alist, it filters the entries that have
   symbols as the keys(first elem of cons)"
  (declare (xargs :guard (alistp alst)))
  (if (endp alst)
    nil
    (if (symbolp (caar alst))
      (cons (car alst) (filter-symbol-keys-in-alist (cdr alst)))
      (filter-symbol-keys-in-alist (cdr alst)))))#|ACL2s-ToDo-Line|#

(defun symbol-list-listp (v)
  (declare (xargs :guard T))
  (if (atom v)
      (null v)
    (and (symbol-listp (car v))
         (symbol-list-listp (cdr v)))))

(defun order-var-te-alist. (A connected-vs-lst ans.)
  "helper to order-var-te-alist"
  (declare (xargs :verify-guards nil
                  :guard (and (symbol-alistp A)
                              (symbol-list-listp connected-vs-lst)
                              (symbol-alistp ans.))))
  (if (endp connected-vs-lst)
      ans.
    (b* ((vs        (car connected-vs-lst))
         (tes       (get-val-lst vs A))
         (A-partial (cons-up-lists vs tes)))
     (order-var-te-alist.  A (cdr connected-vs-lst)
                            (append ans. A-partial)))))

(defun order-var-te-alist (A connected-vs-lst)
  "order var-type-expression-dlist using connected-vertices information"
  (declare (xargs :verify-guards nil
                  :guard (and (symbol-alistp A)
                              (symbol-list-listp connected-vs-lst))))
                            
  (if (null connected-vs-lst)
      A
    (order-var-te-alist. A connected-vs-lst '() )))

(defun to-string (x)
  (declare (xargs :mode :program))
  (coerce (cdr (coerce (fms-to-string "~x0" (list (cons #\0 x))) 'list)) 'string))

;check this TODO
(defun is-singleton-type-p (obj)
  (possible-constant-valuep obj))

(defun is-singleton-type-lst-p (obj-lst)
  (declare (xargs :guard (true-listp obj-lst)))
  (if (endp obj-lst)
    t
  (and (possible-constant-valuep (car obj-lst))
       (is-singleton-type-lst-p (cdr obj-lst)))))

(defun tau-predicate-p (pred world)
  (declare (xargs :mode :program))
  (b* ((td (acl2::tau-data-fn pred world))
       ((unless (consp td)) nil)
       (entry (assoc-eq 'acl2::recognizer-index (cdr td)))
       ((unless (and (consp entry) (consp (cdr entry)))) nil))
    (natp (cadr entry))))


; CHECK with J. TODO What if there is some information in pos-implicants of P1,
; that is missed below!?
(defun subtype-p (P1 P2 wrld)
  "Is P1 => P2 in tau-database?"
  (declare (xargs :verify-guards nil
                  :guard (and (symbolp P1)
                              (symbolp P2)
                              (plist-worldp wrld))))
  (b* (
       ;((unless (tau-predicate-p P1 wrld)) nil)
       ;((unless (tau-predicate-p P2 wrld)) nil) ;expensive calls 
       ((when (eq P2 'acl2::allp)) t)
       ((when (eq P1 P2)) t)
       (P2-neg-implicants-tau (getprop P2 'acl2::neg-implicants acl2::*tau-empty* 'acl2::current-acl2-world wrld))
       (P2-neg-pairs (acl2::access acl2::tau P2-neg-implicants-tau :neg-pairs)))
    ;guard verif fails since, we dont know if P2-neg-implicants is a alist.
    (rassoc-eq P1 P2-neg-pairs)))

(defun disjoint-p (P1 P2 wrld)
  "Is P1 x => (not (P2 x)) in tau-database?"
  (declare (xargs :verify-guards nil
                  :guard (and (symbolp P1)
                              (symbolp P2)
                              (plist-worldp wrld))))
  (b* (
       ;((unless (tau-predicate-p P1 wrld)) nil)
       ;((unless (tau-predicate-p P2 wrld)) nil) ;expensive calls 
       ((when (or (eq P1 'acl2::allp) (eq P2 'acl2::allp))) nil)
       ((when (eq P1 P2)) nil)
       (P1-pos-implicants-tau (getprop P1 'acl2::pos-implicants acl2::*tau-empty* 'acl2::current-acl2-world wrld))
       (P1-neg-pairs (acl2::access acl2::tau P1-pos-implicants-tau :neg-pairs)))
    ;guard verif fails since, we dont know if P2-pos-implicants is a alist.
    (rassoc-eq P2 P1-neg-pairs)))

;; (defstub is-disjoint (* * *) => *)
;; (defstub is-subtype (* * *) => *)
;; (defstub is-alias (* * *) => *)

(defstub is-type-predicate (* *) => *)
(defstub is-a-typeName (* *) => *)
(defstub is-a-custom-type (* *) => *)