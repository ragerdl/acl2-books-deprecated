
# Note: We no longer maintain a Makefile-based approach to certifyingg
# individual workshops/ directories (see cert.pl and
# books/GNUmakefile), so 2014 and beyond are omitted just below.
DIRS = 1999 2000 2002 2003 2004 2006 2007 2009 2011 2013
include ../Makefile-psubdirs

# Because 2003/greve-wilding_mbe/support/fpst.cert
# depends on ../../../1999/graph/linear-find-path.cert, we add:
2003: 1999

tar:
	@for dir in $(DIRS) ; \
	do \
	(cd $$dir ; \
	$(MAKE) tar ; \
	cd ..) ; \
	done
