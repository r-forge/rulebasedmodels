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

syntax: tmk ?options...? ?--? ?targets...?


  flow control / action 
  -----------------------------

    -h / -help      output this text
    -rules          output rule database
    -sysinfo        output system/config information
    -reconfig       reconfigure tmk (rebuild local cache files)
    -modver <mod>   output available versions of module <mod>
    -pretend        only display TCL commands that would be executed
    -par ?<n>?      switch on parallel processing, uses <n> threads 
                    on systems where tclsh supports threading.
                    this overrides the TMK_THREADS environment variable 
    -cont           continue on error as far as possible (not supported yet)



  code generation level and output directory
  ------------------------------------------

    -prf        profiling code 
    -dbg        debug code (default)
    -std        standard (simple optimizations)
    -opt        optimized code (normal level)
    -max        optimized code (high level, cpu specific)
    -arch <str> set architecture name to <str> and switch on
                architecture-dependent target directory
    -noarch     switch off architecture-dependent target directory


  file options 
  ------------

    -f <file>     read <file> instead of TMakefile ("-" for stdin)
    -proj <file>  read <file> instead of TMakefile.proj
    -priv <file>  read <file> instead of TMakefile.priv
    -nomakef      do not read TMakefile, e.g., to get \$ARCH, \$::cxx::COMPILER, 
                  % tmk -nomakef -silent -cmd 'puts \$ARCH'
                  % tmk -nomakef -silent -cmd 'puts \$::cxx::COMPILER'
    -noproj       do not read TMakefile.proj
    -nopriv       do not read TMakefile.priv


  target modification options 
  ---------------------------

    -force             build all specified targets unconditionally
    -mfdepend          include TMakefile as prerequisite for every target
    -up ?targets...?   pretend that these targets have been freshly updated
    -nup ?targets...?  pretend that these targets are old and remain untouched


  debugging, tracing, logging
  ---------------------------

    -verbose          echo currently executed command (default behaviour)
    -silent           no echo of currently executed command
    -debug            increase debugging level (may be spec'd multiple times)
    -nodebug          no debugging messages
    -vtrace <var>     trace all write accesses to the specified variable
    -ptrace <proc>    trace all calls of the specified procedure


  misc options
  ------------

    -local            switch off subdirectory processing
    -mod <name>       load module <name> after parsing the TMakefile
    -D <var>=<value>  set variable <var> to <value> before reading the
                      TMakefiles. Set to 1 if the '=<value>' part is omitted.
    -cmd <code>       executes <code> after reading the default module
	              and before reading the TMakefiles
    -init <code>      executes <code> before reading the default module,
	              right after command line processing
    -prefix <p>       print <p> before every line of output [default is "tmk:"]
    -version          print release version and core version 
                      (core version is cvs controlled version)
    -dumpversion      print only release version number
    -dumpcoreversion  print only core version number


  tmk mode
  --------

    -setrunmode <runmode=value> tmk runs under this mode. 
                       Example. tmk -setrunmode addressmode=64bit
