dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2003 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_GETHOSTNAME],
[AC_CHECK_FUNCS(gethostname)dnl
if test $ac_cv_func_gethostname = yes; then
CL_PROTO([gethostname], [
for x in 'int' 'size_t' 'unsigned int'; do
if test -z "$have_gethostname"; then
AC_TRY_COMPILE([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef __BEOS__
#include <sys/socket.h>
#include <netdb.h>
#endif
]AC_LANG_EXTERN[
#if defined(__STDC__) || defined(__cplusplus)
int gethostname (char* name, $x namelen);
#else
int gethostname();
#endif
], [],
cl_cv_proto_gethostname_arg2="$x"
have_gethostname=1)
fi
done
], [extern int gethostname (char*, $cl_cv_proto_gethostname_arg2);])
AC_DEFINE_UNQUOTED(GETHOSTNAME_SIZE_T,$cl_cv_proto_gethostname_arg2,[type of `namelen' in gethostname() declaration])
fi
])
