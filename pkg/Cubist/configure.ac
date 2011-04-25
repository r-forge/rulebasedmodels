AC_INIT([Cubist])
GCC_COMPILER=`"${R_HOME}/bin/R" CMD config CC | grep "gcc"`
if test -n "$GCC_COMPILER"; then
  PKG_CFLAGS="-ffloat-store -g"
else
  PKG_CFLAGS="-g"
fi
AC_SUBST(PKG_CFLAGS)
AC_CONFIG_FILES([src/Makevars])
AC_OUTPUT
