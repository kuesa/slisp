dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2003 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.57)

AC_DEFUN([CL_GETCWD],
[CL_LINK_CHECK([getcwd], cl_cv_func_getcwd, [
#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#include <unistd.h>
#endif
], [getcwd((char*)0,1024);], AC_DEFINE(HAVE_GETCWD,,[have getcwd()]),)
if test $cl_cv_func_getcwd = yes; then
CL_PROTO([getcwd], [
CL_PROTO_TRY([
#include <stdlib.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
], [char* getcwd (char* buf, int bufsize);], [char* getcwd();],
cl_cv_proto_getcwd_arg2="int", cl_cv_proto_getcwd_arg2="size_t")
], [extern char* getcwd (char*, $cl_cv_proto_getcwd_arg2);])
AC_DEFINE_UNQUOTED(GETCWD_SIZE_T,$cl_cv_proto_getcwd_arg2,[the type of `bufsize' in getcwd()])
fi
])
