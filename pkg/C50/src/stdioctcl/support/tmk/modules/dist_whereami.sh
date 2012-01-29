#!/bin/sh

# ------------------------------------------------------------------------
# determine location of the executed script 
# comments/suggestions to: Hartmut Schirmacher (schirmacher@mpi-sb.mpg.de)
# ------------------------------------------------------------------------

# determine abs or rel path of the called thing (e.g. symlink)
case $0 in
   /*) name=$0 ;;
   .*) name=`pwd`/$0 ;;
    *) name=`which $0` ;;
esac
case $name in
   /*) ;;
    *) name=`pwd`/$name ;;
esac
CALLNAME=`basename $name`
PROGNAME=$CALLNAME
LOCATION=`dirname $name`

# expand links until we have the real thing
while ( [ -L $name ] ) do \
    PROGNAME=`basename $name` 
    name=`/bin/ls -l $name | sed 's/.* -> //g'`
    # update $name so that it contains the absolute path
    case $name in
        /*)  ;; 
         *)  name=$LOCATION/$name ;;
    esac
    LOCATION=`dirname $name`
done
SCRIPTNAME=`basename $name`

# now, if the result does not exist, something's wrong
if [ ! -s $name ] ; then \
    echo "cannot determine real location of $0." ;\
    exit 1; \
fi

# now we have:
# - $CALLNAME: the name of the thing that has been called
# - $PROGNAME: the name of the last symbolic link pointing to this script  
#              (important for multi-program wrappers)
# - $SCRIPTNAME: the real name of the script
# - $LOCATION: the absolute path of where the script resides

