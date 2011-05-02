#*************************************************************************#
#*									 *#
#*		Makefile for the C5.0 system				 *#
#*		----------------------------				 *#
#*									 *#
#*************************************************************************#


CC	= gcc -ffloat-store
CFLAGS = -g -Wall -DVerbOpt -O0
LFLAGS = $(S)
SHELL  = /bin/csh


#	Definitions of file sets
#	New file ordering suggested by gprof

src =\
	global.c\
	c50.c\
	construct.c\
	formtree.c\
	info.c\
	discr.c\
	contin.c\
	subset.c\
	prune.c\
	p-thresh.c\
	trees.c\
	siftrules.c\
	ruletree.c\
	rules.c\
	getdata.c\
	implicitatt.c\
	mcost.c\
	confmat.c\
	sort.c\
	update.c\
	attwinnow.c\
	classify.c\
	formrules.c\
	getnames.c\
	modelfiles.c\
	utility.c\
	xval.c

obj =\
	 c50.o global.o\
	 construct.o formtree.o info.o discr.o contin.o subset.o prune.o\
	 p-thresh.o trees.o\
	 formrules.o siftrules.o ruletree.o rules.o\
	 xval.o\
	 getnames.o getdata.o implicitatt.o\
	 mcost.o classify.o confmat.o sort.o\
	 update.o utility.o\
	 modelfiles.o\
	 attwinnow.o\

all:
	make c5.0
	$(CC) $(LFLAGS) -o report report.c -lm


# debug version (including verbosity option)

c5.0dbg:\
	$(obj) defns.h extern.h text.h Makefile
	$(CC) -g -o c5.0dbg $(obj) -lm


# production version

c5.0:\
	$(src) defns.h text.h Makefile
	cat defns.h $(src)\
		| egrep -v 'defns.h|extern.h' >c50gt.c
	$(CC) $(LFLAGS) -O3 -o c5.0 c50gt.c -lm
	strip c5.0
	rm c50gt.c


$(obj):		Makefile defns.h extern.h text.h


.c.o:
	$(CC) $(CFLAGS) -c $<
