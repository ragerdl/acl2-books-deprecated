; This book is designed to break waterfall parallelism.  We created it from a
; proof attempt that we know fails.  Furthermore, this proof fails in such a
; way that it triggers waterfall parallelism bugs.  This is probably due to a
; use of wormhole printing and an ACL2(p) bug involving wormholes.

; Note the below number of iterations for dotimes$.  We can do up to 100
; iterations pretty easily, but we have yet to perform 1000 iterations
; successfully, in any version of ACL2(p).  This gives us something to work
; towards.

; Observers should not conclude from this book that ACL2(p) is horribly broken.
; In practice, users will only very rarely experience these problems.

(in-package "ACL2")

(set-waterfall-parallelism t) 

(set-debugger-enable t)

(include-book "demos/modeling/network-state-basic" :dir :system)

(include-book "make-event/dotimes" :dir :system)

(dotimes$
 (i 1000) ; works up to 100 fairly reliably

; Technically being unable to prove this theorem in ACL2 doesn't mean that the
; theorem isn't valid.  However, if we believed the theorem to be valid, we
; would relentlessly examine the feedback from ACL2 until we figured out how to
; make ACL2 agree with our belief.  But, we happen to know that the theorem
; isn't true, so we leave it as is.
 
 (thm
  (implies
   (and (valid-client-state client-st) ; is symbolic
        (valid-server-state server-st)
        (valid-network network-st))
   (mv-let (client-st network-st)
     (client-step1 client-st (attack1 network-st))
     (mv-let (server-st network-st)
       (server-step1 server-st (attack2 network-st))
       (declare (ignore server-st))
       (mv-let (client-st network-st)
         (client-step2 client-st network-st)
         (declare (ignore network-st))
         (equal (expt (get-number-to-square-from-client-state client-st) 2)
                (get-answer-from-client-state client-st))))))))
