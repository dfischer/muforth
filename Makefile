# $Id$
#
# This file is part of muforth.
#
# Copyright (c) 1997-2004 David Frech. All rights reserved, and all wrongs
# reversed.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# or see the file LICENSE in the top directory of this distribution.
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###
### Makefile for muforth, a "micro" Forth
###

### 2004-jun-24. daf. Made this file as generic as possible, stripping out
### all the "web projects" stuff. Now it should compile with BSD make or
### GNU make.

VERSION=	0.02

CFLAGS=		-O2 -Wall -fomit-frame-pointer
#CFLAGS=		-g -Wall -fomit-frame-pointer -DDEBUG -DBEING_DEFINED
LDFLAGS=

# If any of these files changes, make a new version.h
VERSOBJS=	kernel.o interpret.o compile.o dict.o file.o \
			error.o time.o tty.o select.o i386_lib.o

ALLOBJS=	${VERSOBJS} muforth.o
DEPFILES=	Makefile muforth.h env.h

.PHONY: all clean

all : public.h muforth

${ALLOBJS} : ${DEPFILES}

muforth.o : version.h

public.h : ${ALLOBJS:S/.o/.ph/}
	(echo "/* This file is automagically generated. Do not edit! */"; \
	cat ${.ALLSRC}) > ${.TARGET}

forth_chain.h : public.h gen_dict_chain.sed
	(echo "/* This file is automagically generated. Do not edit! */"; \
	sed -E \
		-e '/^void mu_compiler/d' \
		-f gen_dict_chain.sed ${.ALLSRC} \
	) > ${.TARGET}

compiler_chain.h : public.h gen_dict_chain.sed
	(echo "/* This file is automagically generated. Do not edit! */"; \
	sed -E \
		-e '/^void mu_compiler/!d' \
		-e 's/mu_compiler_/mu_/' \
		-f gen_dict_chain.sed \
		-e 's/mu_/mu_compiler_/' ${.ALLSRC} \
	) > ${.TARGET}

dict.o : forth_chain.h compiler_chain.h

.SUFFIXES : .ph

.c.ph : Makefile
	@echo Making ${.TARGET}
	@(echo "/* ${.IMPSRC} */"; \
	sed -E -n \
		-e '/^#if 0/q' \
		-e '/^static /d' \
		-e 's/^([a-z]+ \**[a-z_0-9]+)\((void)?\).*$$/\1(void);/p' \
		-e 's/^(pw [a-z_0-9]+).*;$$/extern \1;/p' \
		${.IMPSRC}; \
	echo) > ${.TARGET}

.s.ph : Makefile
	@echo Making ${.TARGET}
	@(echo "/* ${.IMPSRC} */"; \
	sed -E -n \
		-e 's/^ +\.globl +([a-z_0-9]+).*/void \1(void);/p' \
		${.IMPSRC}; \
	echo) > ${.TARGET}

env.h : envtest
	./envtest > ${.TARGET}

version.h : Makefile ${VERSOBJS}
	echo "#define VERSION \"${VERSION}\"" > version.h
	echo "time_t build_time = `date \"+%s\"`;" >> version.h

muforth : ${ALLOBJS} ${DEPFILES}
	${CC} ${LDFLAGS} -o $@ ${ALLOBJS} ${LIBS}

.c.asm :
	${CC} ${CFLAGS} -S -o ${.TARGET} -c ${.IMPSRC}

clean :
	rm -f muforth version.h *.o *.asm *.ph
	rm -f public.h forth_chain.h compiler_chain.h

## For merging changes in other branches into HEAD
.if defined (BRANCH)

syncpoint !
	cvs rtag -r ${BRANCH} -F ${BRANCH}_merged_to_HEAD muforth

do_merge !
	cvs update -j ${BRANCH}_merged_to_HEAD -j ${BRANCH}

merge ! do_merge syncpoint

.elif make(syncpoint) || make(do_merge) || make(merge)
.error You need to define a source BRANCH to merge from.
.endif
