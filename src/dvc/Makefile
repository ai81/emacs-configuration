

PACKAGE_TARNAME = dvc
PACKAGE_VERSION = 0

# location of required programms
AUTOCONF = autoconf
TAR = tar
RM   = @RM@
prefix = /usr/local
datarootdir= ${prefix}/share
info_dir = ${datarootdir}/info
srcdir = .
lispdir= $(prefix)/share/emacs/site-lisp/dvc

SUBDIRS = lisp texinfo

MKDIR_P = /bin/mkdir -p

##############################################################################
all: dvc info dvc-load.el

Makefile: config.status $(srcdir)/Makefile.in
	./config.status $@

dvc-load.el: config.status $(srcdir)/dvc-load.el.in
	./config.status $@

$(srcdir)/configure: $(srcdir)/configure.ac
	cd $(srcdir) ; $(AUTOCONF)
	./config.status --recheck

config.status: $(srcdir)/configure
	./config.status --recheck

info pdf dvi html:
	cd texinfo; $(MAKE) $@

dvc:
	cd lisp; $(MAKE)

dvc-verbose:
	cd lisp; $(MAKE) all-verbose

dvc-pkg.el: $(srcdir)/config.status
	@echo Creating $@
	@( echo ';;; $@ (ELPA generated installer file -- do not edit!)' ; \
	   echo '(define-package "dvc" "$(PACKAGE_VERSION)"'  \
	   	'  "The Emacs interface to Distributed Version Control Systems")' ) \
	 > $@

lisp/dvc-version.el:
	cd lisp; $(MAKE) dvc-version.el

%-recursive:
	@for dir in $(SUBDIRS) ; do ( cd $$dir; $(MAKE) $* ) ; done

install: dvc-load.el install-recursive
	sed -e 's|@''lispdir''@|'"$(lispdir)"'|'	\
	    -e 's|@''info_dir''@|'"$(info_dir)"'|'	\
	    $(srcdir)/dvc-load-install.el.in		\
	  > $(lispdir)/dvc-load.el

uninstall: uninstall-recursive
	rmdir $(lispdir) || true

clean: clean-recursive
	rm -f dvc-load.el dvc-load-install.el

distclean: clean distclean-recursive
	rm -rf configure config.status config.log autom4te.cache/ Makefile $(distdir) $(distdir).tar*

maintainer-clean: maintainer-clean-recursive

##############################################################################
distdir		= $(PACKAGE_TARNAME)-$(PACKAGE_VERSION)

lispfiles	= lisp/Makefile.in lisp/dvc-site.el.in \
		  lisp/contrib/*.el lisp/tests/*.el lisp/*.el
docfiles	= texinfo/Makefile.in texinfo/dvc.texinfo texinfo/dvc.info
miscfiles	= Makefile.in COPYING INSTALL* install-sh \
		  dvc-load.el.in dvc-load-install.el.in \
		  lisp/dvc-version.el \
		  texinfo/dvc-version.texinfo \
		  configure.ac configure
extradist	=

distfiles = $(lispfiles) $(docfiles) $(miscfiles) $(extradist)

dist:
	rm -rf $(distdir) $(distdir).tar.gz
	mkdir $(distdir)
	build=`pwd` ; dd=$$build/$(distdir) ; cd $(srcdir) ;	\
	for f in $(distfiles) ; do d='.' ;			\
	  if [ -f $$build/$$f ] ; then d=$$build ; fi ;		\
	  e=`dirname $$f` ; f=`basename $$f` ;			\
	  test -d $$dd/$$e || $(MKDIR_P) $$dd/$$e ;		\
	  cp -p $$d/$$e/$$f $$dd/$$e/$$f ; done
	$(TAR) cf - $(distdir) | gzip --best > $(distdir).tar.gz
	rm -rf $(distdir)

tarball:
	$(MAKE) dist				\
	  distdir=$(PACKAGE_TARNAME)-snapshot	\
	  extradist='debian/* docs/* scripts/*'

package: dvc-pkg.el info lisp/dvc-version.el
	rm -rf $(distdir) $(distdir).tar
	mkdir $(distdir)
	cp -r docs $(distdir)
	cp COPYING $(distdir)
	cp dvc-pkg.el lisp/*el texinfo/dvc.info $(distdir)
	install-info --info-dir=$(distdir) $(distdir)/dvc.info
	$(TAR) cf $(distdir).tar $(distdir)

.INTERMEDIATE: dvc-pkg.el

.PHONY: all info pdf dvi html dvc dvc-verbose \
	install uninstall \
	clean distclean maintainer-clean \
	dist tarball package
