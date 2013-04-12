#; Support for Community Books to Go with ACL2 Version 6.1
#; Copyright (C) 2013, Regents of the University of Texas

#; This program is free software; you can redistribute it and/or
#; modify it under the terms of Version 2 of the GNU General Public
#; License as published by the Free Software Foundation.

#; This program is distributed in the hope that it will be useful,
#; but WITHOUT ANY WARRANTY; without even the implied warranty of
#; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#; GNU General Public License for more details.

#; You should have received a copy of the GNU General Public License
#; along with this program; if not, write to the Free Software
#; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#; Written by:  Matt Kaufmann               and J Strother Moore
#; email:       Kaufmann@cs.utexas.edu      and Moore@cs.utexas.edu
#; Department of Computer Sciences
#; University of Texas at Austin
#; Austin, TX 78712-1188 U.S.A.

# This file certifies books by directing appropriate subdirectories to
# certify their books.  The subsidiary Makefiles take advantage of a
# makefile, Makefile-generic, in this directory, which is derived from
# one written by Bishop Brock.

# For example, to clean and time book certification (including workshops):
# make clean all-plus

# To see how one can certify the books in the regression suite using
# waterfall parallelism (requires the experimental extension ACL2(p)
# of ACL2), see file acl2-sources/acl2-customization-files/README.

# We do not set variable ACL2 here, because the value here would be
# overriden anyhow by the values in the subsidiary Makefiles, which get their
# value from file Makefile-generic.  However, ACL2 can be set on the command
# line, e.g.:
# make ACL2=acl2
# make ACL2=/usr/local/bin/acl2 TIME=/usr/bin/time
# make ACL2=/u/acl2/v2-9/acl2-sources/saved_acl2

TIME = time

# Avoid loading customization file unless environment variable is already set.
# (This is also done in Makefile-generic, but we do it here in support of the
# hons target.)
export ACL2_CUSTOMIZATION ?= NONE

# Directories go here; first those before certifying arithmetic/top-with-meta,
# then those afterwards.

# NOTE!  This does *not* touch directory nonstd.

# Note: arithmetic-4 could be added in analogy to arithmetic-5.

DIRS1 = cowles arithmetic meta xdoc
DIRS2_EXCEPT_WK_COI = ordinals data-structures bdd ihs arithmetic-2 arithmetic-3 arithmetic-5 \
	misc models/jvm/m1-original models/jvm/m1 models/jvm/m5 \
	proofstyles rtl arithmetic-3/extra sorting make-event parallel hints \
	fix-cert finite-set-theory finite-set-theory/osets powerlists textbook \
	defexec symbolic \
	data-structures/memories unicode str concurrent-programs/bakery \
	concurrent-programs/german-protocol deduction/passmore clause-processors \
	quadratic-reciprocity tools paco hacking security regex \
	defsort serialize wp-gen xdoc-impl system tutorial-problems \
	cutil countereg-gen demos leftist-trees taspi std std/ks std/lists std/io \
       std/alists std/typed-lists \
	oslib tau add-ons
# Add directories other than centaur that depend on hons, say, for performance:
HONS_ONLY_DIRS = models/y86 security/des
ifdef ACL2_HONS_REGRESSION
DIRS2_EXCEPT_WK_COI += $(HONS_ONLY_DIRS)
endif
DIRS2_EXCEPT_WK = $(DIRS2_EXCEPT_WK_COI) coi misc/misc2
DIRS2 = $(DIRS2_EXCEPT_WK) workshops
SHORTDIRS2 = ordinals data-structures bdd

# If ACL2_CENTAUR is already set then we leave it alone.  Otherwise
# we set ACL2_CENTAUR to `before' to obtain extra parallelism via the
# centaur/ books unless specific directories are specified, in which
# case we set ACL2_CENTAUR to `skip' to avoid certifying the centaur
# books needlessly.  (If a books directory depends on the centaur
# books, then its dependency should be recorded among the long list of
# dependencies below.)
ifdef ACL2_BOOK_DIRS
ifndef ACL2_CENTAUR
ACL2_CENTAUR ?= skip
endif
else
ACL2_CENTAUR ?= before
# The following can be any subset of DIRS2, and can be set by the user
# on the command line, e.g., from the ACL2 sources directory:
#   make -j 8 regression ACL2_BOOK_DIRS='symbolic paco'
# The directory dependencies (below) should guarantee that all
# necessary supporting directories are made before the ones specified
# explicitly in ACL2_BOOK_DIRS.
ACL2_BOOK_DIRS := $(DIRS2)
endif

ALL_PLUS_DIRS = $(DIRS1) $(ACL2_BOOK_DIRS)

ifdef ACL2
	ACL2_FOR_HONS ?= $(ACL2)
	ACL2_FOR_CENTAUR ?= $(ACL2)
else
	ACL2_FOR_HONS ?= $(shell cd .. ; pwd)/saved_acl2h
	ACL2_FOR_CENTAUR ?= $(shell cd .. ; pwd)/saved_acl2
ifdef ACL2_HONS_REGRESSION
# and ACL2 not defined
	export ACL2 = $(shell cd .. ; pwd)/saved_acl2h
endif
endif

# Since we have specified that ACL2_BOOK_DIRS is to be a subset of
# DIRS2, we don't need to add it explicitly on the next line.
.PHONY: $(DIRS1) $(DIRS2)

# Same as all-plus below, using DIRS2_EXCEPT_WK instead of DIRS2.  Much faster!  Omits
# books less likely to be needed, in particular, under workshops/.
all:
	@date ; $(TIME) $(MAKE) all-aux


# Next, specify all of the directory dependencies.  At this point we do this
# manually by inspecting the Makefiles.

arithmetic: cowles
data-structures: arithmetic
meta: arithmetic
ordinals: top-with-meta-cert
ihs: arithmetic data-structures
misc: data-structures top-with-meta-cert ordinals arithmetic ihs arithmetic-2 arithmetic-3 std/lists
make-event: misc arithmetic-3 arithmetic rtl
arithmetic-2: ihs
rtl: arithmetic meta top-with-meta-cert ordinals ihs misc arithmetic-2
# arithmetic-3 has no dependencies (but see arithmetic-3/extra)
arithmetic-3/extra: arithmetic-3 ihs rtl arithmetic-2 arithmetic-3
# arithmetic-5 has no dependencies
finite-set-theory: arithmetic ordinals
finite-set-theory/osets: unicode tools
powerlists: arithmetic ordinals data-structures
textbook: arithmetic top-with-meta-cert ordinals ihs
defexec: arithmetic misc ordinals
symbolic: arithmetic arithmetic-2 data-structures ihs misc ordinals models/jvm/m5
data-structures/memories: arithmetic-3 misc
unicode: arithmetic arithmetic-3 ihs ordinals tools misc system std/io std/lists std/ks
proofstyles: arithmetic-2 ordinals misc top-with-meta-cert
concurrent-programs/bakery: misc ordinals
concurrent-programs/german-protocol: misc
deduction/passmore: 
serialize: tools
clause-processors: top-with-meta-cert arithmetic-3 textbook arithmetic \
	misc tools data-structures arithmetic-5 system
quadratic-reciprocity: rtl
misc/misc2: rtl coi top-with-meta-cert
hints: misc
models/jvm/m1-original: arithmetic-3/extra
models/jvm/m1: arithmetic-5
models/jvm/m5: top-with-meta-cert ordinals misc ihs
# models/jvm/m5 is needed for paco/books, not paco
models/X86: tools arithmetic-5 arithmetic misc rtl defexec
paco: ihs ordinals top-with-meta-cert
hacking: misc
parallel: make-event tools
security: misc arithmetic-3 arithmetic-5
security/des: security misc centaur
sorting: arithmetic-3/extra
tools: arithmetic-5 misc xdoc
regex: tools cutil str misc
defsort: misc tools std/lists
str: arithmetic defsort tools xdoc misc std/ks
coi: arithmetic arithmetic-2 arithmetic-3 data-structures ihs make-event \
	misc ordinals rtl
wp-gen: ordinals
# xdoc has no dependencies
xdoc-impl: xdoc str tools finite-set-theory/osets
system: tools arithmetic arithmetic-5 misc
std/lists: arithmetic
std/alists: std/lists tools
std/typed-lists: std/lists cutil arithmetic
std/ks: std/lists ihs arithmetic xdoc
std/io: tools xdoc system std/lists std/ks arithmetic ihs arithmetic-3
cutil: xdoc xdoc-impl tools str misc finite-set-theory/osets \
       defsort unicode clause-processors system top-with-meta-cert
countereg-gen: xdoc arithmetic-5 tools defexec finite-set-theory/osets \
	arithmetic-3 arithmetic ordinals
leftist-trees: arithmetic-5 sorting
demos: make-event cutil misc tools arithmetic
taspi: misc arithmetic-3
models/y86: tools centaur misc arithmetic-5 rtl arithmetic defexec
oslib: cutil str tools misc
tau: arithmetic-5
add-ons: arithmetic misc hacking

# Let us wait for everything else before workshops.  Starting after
# Version_4.3 we include the coi books, because of
# workshops/2006/pike-shields-matthews/.
workshops: $(DIRS1) $(DIRS2_EXCEPT_WK)

$(DIRS1):
	@if [ -f $@/Makefile ]; then cd $@ ; $(MAKE) ; fi

$(DIRS2): top-with-meta-cert
	@if [ -f $@/Makefile ]; then cd $@ ; $(MAKE) ; fi

.PHONY: all-aux
all-aux: $(DIRS1) $(DIRS2_EXCEPT_WK)

# Certify all books that need certification.  If you want to get a
# total time for certifying all books, then first do "make clean".  By
# default we do the centaur books first, because one of them might
# support a non-centaur book.  This is quite a commitment: henceforth,
# the regression could in theory fail if we remove the centaur books
# (say, because someone has a problem with Perl).  We'll face that
# problem if it occurs; for example, we could remove the "offending"
# directory from DIRS2_EXCEPT_WK_COI, or we could use
# ACL2_CENTAUR=skip on the command line.

.PHONY: all-plus centaur

ifeq ($(ACL2_CENTAUR),before)
all-plus: $(ALL_PLUS_DIRS)
$(ALL_PLUS_DIRS): centaur
else
ifeq ($(ACL2_CENTAUR),after)
all-plus: centaur
centaur: $(ALL_PLUS_DIRS)
else
all-plus: $(ALL_PLUS_DIRS)
endif
endif

.PHONY: hons clean-hons
# For a parallel "make hons", use e.g.:
#   make hons ACL2_HONS_OPT="-j4"
# In general, ACL2_HONS_OPT is passed to the cert.pl command in centaur/.
# Note that this variable is set automatically in ../GNUmakefile using
# ACL2_JOBS.
hons:
	./cert.pl --targets regression-hons-targets \
	  $(ACL2_HONS_OPT) \
	  --acl2-books "`pwd`" \
	  --acl2 $(ACL2_FOR_HONS)

# WARNING: clean-hons will clean everywhere relevant to books/centaur/ under
# the books/ directory, not merely under books/centaur/.
clean-hons:
	rm -rf centaur/manual
	./cert.pl -c centaur/doc.lisp \
	  $(ACL2_HONS_OPT) \
	  --acl2-books "`pwd`" \
	  -q
	cd taspi/ ; make clean

# Clean all books, not only the "basic" ones.
.PHONY: clean
clean:
	@for dir in $(DIRS1) $(DIRS2) $(HONS_ONLY_DIRS) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) FAST_DEPS_FOR_CLEAN=1 clean ; \
	cd ..) ; \
	fi \
	done

# See instructions for hons above -- except we expect to use the
# centaur target with vanilla ACL2, as opposed to ACL2(h).
centaur:
	./cert.pl --targets regression-centaur-targets \
	  $(ACL2_HONS_OPT) \
	  --acl2-books "`pwd`" \
	  --acl2 $(ACL2_FOR_CENTAUR)

# WARNING: clean-centaur will clean everywhere relevant to books/centaur/ under
# the books/ directory, not merely under books/centaur/.
.PHONY: clean-centaur
ifeq ($(ACL2_CENTAUR),skip)
clean-centaur:
	@echo "Skipping actions for clean-centaur."
else
clean-centaur:
	rm -rf centaur/manual
	./cert.pl -c centaur/doc.lisp \
	  $(ACL2_HONS_OPT) \
	  --acl2-books "`pwd`" \
	  -q
endif

.PHONY: clean
clean: clean-centaur

# Tar up books and support, not including workshops or nonstd stuff.
.PHONY: tar
tar:
	tar cvf books.tar Makefile Makefile-generic Makefile-subdirs README README.html certify-numbers.lsp $(DIRS1) $(DIRS2_EXCEPT_WK)

# The following "short" targets allow for a relatively short test, in response
# to a request from GCL maintainer Camm Maguire.

.PHONY: short-clean
short-clean:
	@rm -f short-test.log
	@for dir in $(DIRS1) $(SHORTDIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) clean ; \
	cd ..) ; \
	fi \
	done

.PHONY: short-test-aux
short-test-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) all ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-cert
	@for dir in $(SHORTDIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) all ; \
	cd ..) ; \
	fi \
	done

.PHONY: short-test
short-test:
	@rm -f short-test.log
	$(MAKE) short-clean
	$(MAKE) short-test-aux > short-test.log 2> short-test.log
	@if [ ! -f short-test.log ] || (fgrep '**' short-test.log > /dev/null) ; then \
	(echo 'Short test failed!' ; exit 1) ; else \
	echo 'Short test passed.' ; fi

# The following target is primarily for developers to be able to check
# well-formedness of the ACL2 world after including each book.
# WARNING: Be sure to run "make regression" first!
# The explicit make of top-with-meta.cert is there in order to avoid
# removing that file after the .bkchk.out file is made (which
# otherwise happens, somehow!).

.PHONY: chk-include-book-worlds-top
chk-include-book-worlds-top:
	@(cd system ; $(MAKE) ; cd ..)
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) chk-include-book-worlds ; \
	cd ..) ; \
	fi \
	done
	@(cd arithmetic/ ; $(MAKE) -f ../Makefile-generic top-with-meta.cert ; cd ..)
	@(cd arithmetic/ ; $(MAKE) -f ../Makefile-generic top-with-meta.bkchk.out ; cd ..)
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) chk-include-book-worlds ; \
	cd ..) ; \
	fi \
	done

# The targets below create compiled files for books that may have
# already been certified in another lisp (.fasl files for all-fasl,
# etc.).  Of course, the underlying lisp of the ACL2 that is run
# should agree with the desired compiled file extension.
# IMPORTANT: In order to use the targets below, you will first need to
# have certified saving expansion files, e.g. with the following 'make'
# argument.
#   ACL2_SAVE_EXPANSION=t

.PHONY: fasl
fasl:
	@date ; $(TIME) $(MAKE) fasl-aux ; date

.PHONY: fasl-aux
fasl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fasl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-fasl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fasl ; \
	cd ..) ; \
	fi \
	done

.PHONY: fas
fas:
	@date ; $(TIME) $(MAKE) fas-aux ; date

.PHONY: fas-aux
fas-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fas ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-fas
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fas ; \
	cd ..) ; \
	fi \
	done

.PHONY: sparcf
sparcf:
	@date ; $(TIME) $(MAKE) sparcf-aux ; date

.PHONY: sparcf-aux
sparcf-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) sparcf ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-sparcf
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) sparcf ; \
	cd ..) ; \
	fi \
	done

.PHONY: ufsl
ufsl:
	@date ; $(TIME) $(MAKE) ufsl-aux ; date

.PHONY: ufsl-aux
ufsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) ufsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-ufsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) ufsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: 64ufasl
64ufasl:
	@date ; $(TIME) $(MAKE) 64ufasl-aux ; date

.PHONY: 64ufasl-aux
64ufasl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) 64ufasl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-64ufasl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) 64ufasl ; \
	cd ..) ; \
	fi \
	done

.PHONY: x86f
x86f:
	@date ; $(TIME) $(MAKE) x86f-aux ; date

.PHONY: x86f-aux
x86f-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) x86f ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-x86f
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) x86f ; \
	cd ..) ; \
	fi \
	done

.PHONY: o
o:
	@date ; $(TIME) $(MAKE) o-aux ; date

.PHONY: o-aux
o-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) o ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-o
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) o ; \
	cd ..) ; \
	fi \
	done

.PHONY: dfsl
dfsl:
	@date ; $(TIME) $(MAKE) dfsl-aux ; date

.PHONY: dfsl-aux
dfsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dfsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-dfsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dfsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: d64fsl
d64fsl:
	@date ; $(TIME) $(MAKE) d64fsl-aux ; date

.PHONY: d64fsl-aux
d64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) d64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-d64fsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) d64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: dx64fsl
dx64fsl:
	@date ; $(TIME) $(MAKE) dx64fsl-aux ; date

.PHONY: dx64fsl-aux
dx64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dx64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-dx64fsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dx64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: lx64fsl
lx64fsl:
	@date ; $(TIME) $(MAKE) lx64fsl-aux ; date

.PHONY: lx64fsl-aux
lx64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-lx64fsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: lx32fsl
lx32fsl:
	@date ; $(TIME) $(MAKE) lx32fsl-aux ; date

.PHONY: lx32fsl-aux
lx32fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx32fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-lx32fsl
	@for dir in $(DIRS2_EXCEPT_WK) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx32fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-fasl
all-fasl:
	@date ; $(TIME) $(MAKE) all-fasl-aux ; date

.PHONY: all-fasl-aux
all-fasl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fasl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-fasl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fasl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-fas
all-fas:
	@date ; $(TIME) $(MAKE) all-fas-aux ; date

.PHONY: all-fas-aux
all-fas-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fas ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-fas
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) fas ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-sparcf
all-sparcf:
	@date ; $(TIME) $(MAKE) all-sparcf-aux ; date

.PHONY: all-sparcf-aux
all-sparcf-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) sparcf ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-sparcf
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) sparcf ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-ufsl
all-ufsl:
	@date ; $(TIME) $(MAKE) all-ufsl-aux ; date

.PHONY: all-ufsl-aux
all-ufsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) ufsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-ufsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) ufsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-64ufasl
all-64ufasl:
	@date ; $(TIME) $(MAKE) all-64ufasl-aux ; date

.PHONY: all-64ufasl-aux
all-64ufasl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) 64ufasl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-64ufasl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) 64ufasl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-x86f
all-x86f:
	@date ; $(TIME) $(MAKE) all-x86f-aux ; date

.PHONY: all-x86f-aux
all-x86f-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) x86f ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-x86f
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) x86f ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-dfsl
all-dfsl:
	@date ; $(TIME) $(MAKE) all-dfsl-aux ; date

.PHONY: all-dfsl-aux
all-dfsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dfsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-dfsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dfsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-d64fsl
all-d64fsl:
	@date ; $(TIME) $(MAKE) all-d64fsl-aux ; date

.PHONY: all-d64fsl-aux
all-d64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) d64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-d64fsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) d64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-dx64fsl
all-dx64fsl:
	@date ; $(TIME) $(MAKE) all-dx64fsl-aux ; date

.PHONY: all-dx64fsl-aux
all-dx64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dx64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-dx64fsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) dx64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-lx64fsl
all-lx64fsl:
	@date ; $(TIME) $(MAKE) all-lx64fsl-aux ; date

.PHONY: all-lx64fsl-aux
all-lx64fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx64fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-lx64fsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx64fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-lx32fsl
all-lx32fsl:
	@date ; $(TIME) $(MAKE) all-lx32fsl-aux ; date

.PHONY: all-lx32fsl-aux
all-lx32fsl-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx32fsl ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-lx32fsl
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) lx32fsl ; \
	cd ..) ; \
	fi \
	done

.PHONY: all-o
all-o:
	@date ; $(TIME) $(MAKE) all-o-aux ; date

.PHONY: all-o-aux
all-o-aux:
	@for dir in $(DIRS1) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) o ; \
	cd ..) ; \
	fi \
	done
	@$(MAKE) top-with-meta-o
	@for dir in $(DIRS2) ; \
	do \
	if [ -f $$dir/Makefile ]; then \
	(cd $$dir ; \
	$(MAKE) o ; \
	cd ..) ; \
	fi \
	done

.PHONY: top-with-meta-cert
top-with-meta-cert: $(DIRS1)
	@echo "Using ACL2=$(ACL2)"
	cd arithmetic ; $(MAKE) top-with-meta.cert

.PHONY: top-with-meta-o
top-with-meta-o:
	cd arithmetic ; $(MAKE) top-with-meta.o

.PHONY: top-with-meta-fasl
top-with-meta-fasl:
	cd arithmetic ; $(MAKE) top-with-meta.fasl

.PHONY: top-with-meta-fas
top-with-meta-fas:
	cd arithmetic ; $(MAKE) top-with-meta.fas

.PHONY: top-with-meta-sparcf
top-with-meta-sparcf:
	cd arithmetic ; $(MAKE) top-with-meta.sparcf

.PHONY: top-with-meta-ufsl
top-with-meta-ufsl:
	cd arithmetic ; $(MAKE) top-with-meta.ufsl

.PHONY: top-with-meta-64ufasl
top-with-meta-64ufasl:
	cd arithmetic ; $(MAKE) top-with-meta.64ufasl

.PHONY: top-with-meta-x86f
top-with-meta-x86f:
	cd arithmetic ; $(MAKE) top-with-meta.x86f

.PHONY: top-with-meta-dfsl
top-with-meta-dfsl:
	cd arithmetic ; $(MAKE) top-with-meta.dfsl

.PHONY: top-with-meta-d64fsl
top-with-meta-d64fsl:
	cd arithmetic ; $(MAKE) top-with-meta.d64fsl

.PHONY: top-with-meta-dx64fsl
top-with-meta-dx64fsl:
	cd arithmetic ; $(MAKE) top-with-meta.dx64fsl

.PHONY: top-with-meta-lx64fsl
top-with-meta-lx64fsl:
	cd arithmetic ; $(MAKE) top-with-meta.lx64fsl

.PHONY: top-with-meta-lx32fsl
top-with-meta-lx32fsl:
	cd arithmetic ; $(MAKE) top-with-meta.lx32fsl
