dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_ALLOCA],
[# The Ultrix 4.2 mips builtin alloca declared by alloca.h only works
# for constant arguments.  Useless!
CL_LINK_CHECK(working alloca.h, cl_cv_header_alloca_h,
[#include <alloca.h>], [char *p = (char *) alloca(2 * sizeof(int));],
AC_DEFINE(HAVE_ALLOCA_H))dnl
decl="#ifdef __GNUC__
#define alloca __builtin_alloca
#else
#ifdef _MSC_VER
#include <malloc.h>
#define alloca _alloca
#else
#ifdef HAVE_ALLOCA_H
#include <alloca.h>
#else
#ifdef _AIX
 #pragma alloca
#else
#ifndef alloca
char *alloca ();
#endif
#endif
#endif
#endif
#endif
"
CL_LINK_CHECK([alloca], cl_cv_func_alloca,
$decl, [char *p = (char *) alloca(1);],
 , [alloca_missing=1])dnl
if test -n "$alloca_missing"; then
  # The SVR3 libPW and SVR4 libucb both contain incompatible functions
  # that cause trouble.  Some versions do not even contain alloca or
  # contain a buggy version.  If you still want to use their alloca,
  # use ar to extract alloca.o from them instead of compiling alloca.c.
  ALLOCA=alloca.${ac_objext}
  AC_DEFINE(NO_ALLOCA)
fi
AC_SUBST(ALLOCA)dnl
])
