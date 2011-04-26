AC_INIT([Cubist], [0.03])

AC_PROG_CC
AC_PROG_GREP
AC_CHECK_PROGS([ECHO], [echo], [:])

if test "$ECHO" = :; then
  AC_MSG_ERROR([This package needs echo.])
fi

if test "$GCC" = "yes"; then
  PKG_CFLAGS="-ffloat-store -g"
else
  PKG_CFLAGS="-g"
fi

AC_SUBST(PKG_CFLAGS)
AC_CONFIG_FILES([src/Makevars])
AC_OUTPUT
