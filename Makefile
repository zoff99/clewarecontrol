# $Revision: 100 $
VERSION=4.3

DEBUG=-g -W -pedantic #-pg #-fprofile-arcs
LDFLAGS+=`pkg-config --libs hidapi-hidraw`
CXXFLAGS+=-O3 -Wall -DVERSION=\"$(VERSION)\" $(DEBUG) `pkg-config --cflags hidapi-hidraw`
CFLAGS+=$(CXXFLAGS)

OBJS=main.o USBaccessBasic.o USBaccess.o error.o

all: clewarecontrol

clewarecontrol: $(OBJS)
	$(CXX) $(OBJS) $(LDFLAGS) -o clewarecontrol

cleware_python cleware_python3:  pyswig
	$(subst cleware_,,$@) setup.py install

pyswig:
	swig -c++ -python cleware.i

cleware_perl:
	swig -c++ -perl5 cleware.i
	g++ -c `perl -MConfig -e 'print join(" ", @Config{qw(ccflags optimize cccdlflags)}, "-I$$Config{archlib}/CORE")'` cleware_wrap.cxx USBaccessBasic.cpp USBaccess.cpp
	g++ `perl -MConfig -e 'print $$Config{lddlflags}'` cleware_wrap.o USBaccessBasic.o USBaccess.o -o cleware.so
	./install-lib.pl

install: clewarecontrol
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp clewarecontrol $(DESTDIR)$(PREFIX)/bin
	mkdir -p $(DESTDIR)$(PREFIX)/share/man/man1
	cp clewarecontrol.1 $(DESTDIR)$(PREFIX)/share/man/man1/clewarecontrol.1
	gzip -9 $(DESTDIR)$(PREFIX)/share/man/man1/clewarecontrol.1

uninstall: clean
	rm -f $(DESTDIR)$(PREFIX)/bin/clewarecontrol
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/clewarecontrol.1

clean:
	rm -rf $(OBJS) clewarecontrol core gmon.out *.da build cleware_wrap.cxx *cleware*.so cleware.py* cleware.pm *.o

package: clean
	# source package
	rm -rf clewarecontrol-$(VERSION)*
	mkdir clewarecontrol-$(VERSION)
	cp -a *.c* *.h *.i *.pl *py readme*.txt clewarecontrol.1 Makefile LICENSE clewarecontrol-$(VERSION)
	tar cf - examples --exclude=.svn  | tar xvf - -C clewarecontrol-$(VERSION)
	tar czf clewarecontrol-$(VERSION).tgz clewarecontrol-$(VERSION)
	rm -rf clewarecontrol-$(VERSION)

stest:
	cppcheck -v --enable=all --inconclusive -I. . 2> err.txt
