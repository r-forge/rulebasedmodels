@echo off
rem "TMK execution wrapper for windows "
rem "$Id: tmk.bat,v 1.4 2000/07/20 16:15:59 htschirm Exp $"

if not exist %TMK_TCLSH% goto failedtclsh
if not exist %TMK_HOME%\SRC\TMK goto failedhome

%TMK_TCLSH% %TMK_HOME%\SRC\TMK %1 %2 %3 %4 %5 %6 %7 %8 %9
goto end

:failedhome
echo "cannot find tmk: TMK_HOME unset or wrong !"
goto end
:failedtclsh
echo "cannot find Tcl shell: TMK_TCLSH unset or wrong !"
goto end
:end
