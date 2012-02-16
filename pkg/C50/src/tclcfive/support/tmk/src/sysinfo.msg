----------------------------------------------------------
tmk release $::tmk::Release (core version $::tmk::CoreVersion)
Copyright (C) 1999-2005, Hartmut Schirmacher, Stefan Brabec,
                         Hendrik Lensch, Wolfgang Heidrich, 
                         Michael Goesele, Hitoshi Yamauchi
*** visit the tmk web pages at http://tmk.sourceforge.net/ ***
----------------------------------------------------------
tmk comes with ABSOLUTELY NO WARRANTY; for details see 
the file ${::tmk::dir_src}/LICENSE.TXT.
tmk is free software, and you are welcome to redistribute
it under the conditions mentioned in the license.
----------------------------------------------------------

CPU type (\$CPU) ......................... [$CPU]
number of CPUs (\$NRCPUS)................. [$NRCPUS]
cpu core frequency in MHz (\$CPUFREQ)..... [$CPUFREQ]
machine vedor (\$VENDOR) ................. [$VENDOR]
operating system name (\$OS) ............. [$OS]
operating system version (\$OSVER) ....... [$OSVER]
operating system class (\$OSCLASS) ....... [$OSCLASS]
host name (\$HOST) ....................... [$HOST]
network domain (\$DOMAIN) ................ [$DOMAIN]

current code level (\$CODELEVEL) ......... [$CODELEVEL]
default output directory (\$ARCH) ........ [$ARCH_DEF]

tmk script ..................... [$::tmk::Script]
tmk directory .................. [$::tmk::dir]

tmk site config directory ...... [$::tmk::dir_site]
user's site config directory ... [$::tmk::dir_priv/site-config]

user's config cache directory .. [$::tmk::dir_cache]
cache file for this system ..... [$cache_file]

note: you can regenerate the config cache using 'tmk -reconfig'
      you can get each variable using -cmd option if that is defined. 
      e.g. tmk -nomakef -silent -cmd 'puts \$ARCH', see tmk -h