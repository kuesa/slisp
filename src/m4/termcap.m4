dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold

AC_PREREQ(2.13)

AC_DEFUN([CL_TERMCAP],[
dnl Some systems have tgetent(), tgetnum(), tgetstr(), tgetflag(), tputs(),
dnl tgoto() in libc, some have it in libtermcap, some have it in libncurses.
dnl When both libtermcap and libncurses exist, we prefer the latter,
dnl because libtermcap is being phased out.
dnl libcurses is useless: all platforms which have libcurses also have
dnl libtermcap, also they were all different on the various Unix systems,
dnl and often buggy
termcap_prefix=""
AC_ARG_WITH([libtermcap-prefix],
[  --with-libtermcap-prefix[=DIR]  search for ncurses and termcap in DIR],
[case "$withval" in (/*) termcap_prefix=$withval; ;; esac])
if test x$termcap_prefix != x; then
  LDFLAGS_save=$LDFLAGS
  LDFLAGS=$LDFLAGS" -L$termcap_prefix/lib"
fi
LIBTERMCAP="broken"
INCTERMCAP=""
AC_SEARCH_LIBS(tgetent, ncurses termcap, LIBTERMCAP="")
if test x$termcap_prefix != x; then
  LDFLAGS=$LDFLAGS_save
  if test $LIBTERMCAP != broken; then
    INCTERMCAP=-I$termcap_prefix/include
    LIBTERMCAP=-L$termcap_prefix/lib
  fi
fi
AC_SUBST(LIBTERMCAP)
AC_SUBST(INCTERMCAP)
])
