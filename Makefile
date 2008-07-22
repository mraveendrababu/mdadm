#
# mdadm - manage Linux "md" devices aka RAID arrays.
#
# Copyright (C) 2001-2002 Neil Brown <neilb@cse.unsw.edu.au>
#
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#    Author: Neil Brown
#    Email: <neilb@cse.unsw.edu.au>
#    Paper: Neil Brown
#           School of Computer Science and Engineering
#           The University of New South Wales
#           Sydney, 2052
#           Australia
#

# define "CXFLAGS" to give extra flags to CC.
# e.g.  make CXFLAGS=-O to optimise
TCC = tcc
UCLIBC_GCC = $(shell for nm in i386-uclibc-linux-gcc i386-uclibc-gcc; do which $$nm > /dev/null && { echo $$nm ; exit; } ; done; echo false No uclibc found )
DIET_GCC = diet gcc

KLIBC=/home/src/klibc/klibc-0.77

KLIBC_GCC = gcc -nostdinc -iwithprefix include -I$(KLIBC)/klibc/include -I$(KLIBC)/linux/include -I$(KLIBC)/klibc/arch/i386/include -I$(KLIBC)/klibc/include/bits32

CC = $(CROSS_COMPILE)gcc
CXFLAGS = -ggdb
CWFLAGS = -Wall -Werror -Wstrict-prototypes

ifdef DEBIAN
CPPFLAGS= -DDEBIAN
else
CPPFLAGS=
endif

SYSCONFDIR = /etc
CONFFILE = $(SYSCONFDIR)/mdadm.conf
CONFFILE2 = $(SYSCONFDIR)/mdadm/mdadm.conf
MAILCMD =/usr/sbin/sendmail -t
CONFFILEFLAGS = -DCONFFILE=\"$(CONFFILE)\" -DCONFFILE2=\"$(CONFFILE2)\"
CFLAGS = $(CWFLAGS) $(CXFLAGS) -DSendmail=\""$(MAILCMD)"\" $(CONFFILEFLAGS)

# If you want a static binary, you might uncomment these
# LDFLAGS = -static
# STRIP = -s

INSTALL = /usr/bin/install
DESTDIR = 
BINDIR  = /sbin
MANDIR  = /usr/share/man
MAN4DIR = $(MANDIR)/man4
MAN5DIR = $(MANDIR)/man5
MAN8DIR = $(MANDIR)/man8

OBJS =  mdadm.o config.o mdstat.o  ReadMe.o util.o Manage.o Assemble.o Build.o \
	Create.o Detail.o Examine.o Grow.o Monitor.o dlink.o Kill.o Query.o \
	Incremental.o \
	mdopen.o super0.o super1.o super-ddf.o super-intel.o bitmap.o \
	restripe.o sysfs.o sha1.o mapfile.o crc32.o sg_io.o msg.o
SRCS =  mdadm.c config.c mdstat.c  ReadMe.c util.c Manage.c Assemble.c Build.c \
	Create.c Detail.c Examine.c Grow.c Monitor.c dlink.c Kill.c Query.c \
	Incremental.c \
	mdopen.c super0.c super1.c super-ddf.c super-intel.c bitmap.c \
	restripe.c sysfs.c sha1.c mapfile.c crc32.c sg_io.c msg.c

MON_OBJS = mdmon.o monitor.o managemon.o util.o mdstat.o sysfs.o config.o \
	Kill.o sg_io.o dlink.o ReadMe.o super0.o super1.o super-intel.o \
	super-ddf.o sha1.o crc32.o msg.o


STATICSRC = pwgr.c
STATICOBJS = pwgr.o

ASSEMBLE_SRCS := mdassemble.c Assemble.c Manage.c config.c dlink.c util.c \
	super0.c super1.c super-ddf.c super-intel.c sha1.c crc32.c sg_io.c
ASSEMBLE_AUTO_SRCS := mdopen.c mdstat.c sysfs.c
ASSEMBLE_FLAGS:= $(CFLAGS) -DMDASSEMBLE
ifdef MDASSEMBLE_AUTO
ASSEMBLE_SRCS += $(ASSEMBLE_AUTO_SRCS)
ASSEMBLE_FLAGS += -DMDASSEMBLE_AUTO
endif

all : mdadm mdmon mdadm.man md.man mdadm.conf.man

everything: all mdadm.static swap_super test_stripe \
	mdassemble mdassemble.auto mdassemble.static mdassemble.man \
	mdadm.Os mdadm.O2
# mdadm.uclibc and mdassemble.uclibc don't work on x86-64
# mdadm.tcc doesn't work..

mdadm : $(OBJS)
	$(CC) $(LDFLAGS) -o mdadm $(OBJS) $(LDLIBS)

mdadm.static : $(OBJS) $(STATICOBJS)
	$(CC) $(LDFLAGS) -static -o mdadm.static $(OBJS) $(STATICOBJS)

mdadm.tcc : $(SRCS) mdadm.h
	$(TCC) -o mdadm.tcc $(SRCS)

dadm.uclibc : $(SRCS) mdadm.h
	$(UCLIBC_GCC) -DUCLIBC -DHAVE_STDINT_H -o mdadm.uclibc $(SRCS) $(STATICSRC)

mdadm.klibc : $(SRCS) mdadm.h
	rm -f $(OBJS) 
	gcc -nostdinc -iwithprefix include -I$(KLIBC)/klibc/include -I$(KLIBC)/linux/include -I$(KLIBC)/klibc/arch/i386/include -I$(KLIBC)/klibc/include/bits32 $(CFLAGS) $(SRCS)

mdadm.Os : $(SRCS) mdadm.h
	gcc -o mdadm.Os $(CFLAGS)  -DHAVE_STDINT_H -Os $(SRCS)

mdadm.O2 : $(SRCS) mdadm.h
	gcc -o mdadm.O2 $(CFLAGS)  -DHAVE_STDINT_H -O2 $(SRCS)

mdmon : $(MON_OBJS)
	$(CC) $(LDFLAGS) -o mdmon $(MON_OBJS) $(LDLIBS)
msg.o: msg.c msg.h

test_stripe : restripe.c mdadm.h
	$(CC) $(CXFLAGS) $(LDFLAGS) -o test_stripe -DMAIN restripe.c

mdassemble : $(ASSEMBLE_SRCS) mdadm.h
	rm -f $(OBJS)
	$(DIET_GCC) $(ASSEMBLE_FLAGS) -o mdassemble $(ASSEMBLE_SRCS)  $(STATICSRC)

mdassemble.static : $(ASSEMBLE_SRCS) mdadm.h
	rm -f $(OBJS)
	$(CC) $(LDFLAGS) $(ASSEMBLE_FLAGS) -static -DHAVE_STDINT_H -o mdassemble.static $(ASSEMBLE_SRCS) $(STATICSRC)

mdassemble.auto : $(ASSEMBLE_SRCS) mdadm.h $(ASSEMBLE_AUTO_SRCS)
	rm -f mdassemble.static
	$(MAKE) MDASSEMBLE_AUTO=1 mdassemble.static
	mv mdassemble.static mdassemble.auto

mdassemble.uclibc : $(ASSEMBLE_SRCS) mdadm.h
	rm -f $(OJS)
	$(UCLIBC_GCC) $(ASSEMBLE_FLAGS) -DUCLIBC -DHAVE_STDINT_H -static -o mdassemble.uclibc $(ASSEMBLE_SRCS) $(STATICSRC)

# This doesn't work
mdassemble.klibc : $(ASSEMBLE_SRCS) mdadm.h
	rm -f $(OBJS)
	$(KLIBC_GCC) $(ASSEMBLE_FLAGS) -o mdassemble $(ASSEMBLE_SRCS)

mdadm.man : mdadm.8
	nroff -man mdadm.8 > mdadm.man

md.man : md.4
	nroff -man md.4 > md.man

mdadm.conf.man : mdadm.conf.5
	nroff -man mdadm.conf.5 > mdadm.conf.man

mdassemble.man : mdassemble.8
	nroff -man mdassemble.8 > mdassemble.man

$(OBJS) : mdadm.h bitmap.h

sha1.o : sha1.c sha1.h md5.h
	$(CC) $(CFLAGS) -DHAVE_STDINT_H -o sha1.o -c sha1.c

install : mdadm mdmon install-man
	$(INSTALL) -D $(STRIP) -m 755 mdadm $(DESTDIR)$(BINDIR)/mdadm
	$(INSTALL) -D $(STRIP) -m 755 mdmon $(DESTDIR)$(BINDIR)/mdmon

install-static : mdadm.static install-man
	$(INSTALL) -D $(STRIP) -m 755 mdadm.static $(DESTDIR)$(BINDIR)/mdadm

install-tcc : mdadm.tcc install-man
	$(INSTALL) -D $(STRIP) -m 755 mdadm.tcc $(DESTDIR)$(BINDIR)/mdadm

install-uclibc : mdadm.uclibc install-man
	$(INSTALL) -D $(STRIP) -m 755 mdadm.uclibc $(DESTDIR)$(BINDIR)/mdadm

install-klibc : mdadm.klibc install-man
	$(INSTALL) -D $(STRIP) -m 755 mdadm.klibc $(DESTDIR)$(BINDIR)/mdadm

install-man: mdadm.8 md.4 mdadm.conf.5
	$(INSTALL) -D -m 644 mdadm.8 $(DESTDIR)$(MAN8DIR)/mdadm.8
	$(INSTALL) -D -m 644 md.4 $(DESTDIR)$(MAN4DIR)/md.4
	$(INSTALL) -D -m 644 mdadm.conf.5 $(DESTDIR)$(MAN5DIR)/mdadm.conf.5

uninstall:
	rm -f $(DESTDIR)$(MAN8DIR)/mdadm.8 md.4 $(DESTDIR)$(MAN4DIR)/md.4 $(DESTDIR)$(MAN5DIR)/mdadm.conf.5 $(DESTDIR)$(BINDIR)/mdadm

test: mdadm test_stripe swap_super
	@echo "Please run 'sh ./test' as root"

clean : 
	rm -f mdadm mdmon $(OBJS) $(MON_OBJS) $(STATICOBJS) core *.man \
	mdadm.tcc mdadm.uclibc mdadm.static *.orig *.porig *.rej *.alt \
	mdadm.Os mdadm.O2 \
	mdassemble mdassemble.static mdassemble.auto mdassemble.uclibc \
	mdassemble.klibc swap_super \
	init.cpio.gz mdadm.uclibc.static test_stripe

dist : clean
	./makedist

testdist : everything clean
	./makedist test

TAGS :
	etags *.h *.c
