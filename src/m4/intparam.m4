dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2003 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ(2.13)

AC_DEFUN([CL_MACHINE],
[AC_REQUIRE([AC_PROG_CC])dnl
AC_REQUIRE([AC_C_CHAR_UNSIGNED])dnl
cl_machine_file_c=$2
cl_machine_file_h=$3
if test $cross_compiling = no; then
if test -z "$[$4]"; then
AC_CHECKING(for [$1])
cat > conftest.$ac_ext <<EOF
#include "confdefs.h"
EOF
cat "$cl_machine_file_c" >> conftest.$ac_ext
ORIGCC="$CC"
if test $ac_cv_prog_gcc = yes; then
# gcc -O (gcc version <= 2.3.2) crashes when compiling long long shifts for
# target 80386. Strip "-O".
CC=`echo "$CC " | sed -e 's/-O //g'`
fi
AC_TRY_EVAL(ac_link)
CC="$ORIGCC"
if test -s conftest; then
  echo "creating $cl_machine_file_h"
  ./conftest > conftest.h
  if cmp -s "$cl_machine_file_h" conftest.h 2>/dev/null; then
    # The file exists and we would not be changing it
    rm -f conftest.h
  else
    rm -f "$cl_machine_file_h"
    mv conftest.h "$cl_machine_file_h"
  fi
  [$4]=1
else
  echo "creation of $cl_machine_file_h failed"
fi
rm -f conftest*
fi
else
echo "cross-compiling - cannot create $cl_machine_file_h"
fi
])
