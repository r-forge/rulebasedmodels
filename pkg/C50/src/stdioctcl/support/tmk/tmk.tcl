#! /bin/env tclsh

namespace eval tmk {}

# ========================================================================
# some user-visible general helper routines
# ========================================================================

# only set a variable if it's not already defined; also create namespace
proc ifdef {var then_part {else_part {}} } {
    if {[uplevel 1 info vars $var] eq {}} {
	uplevel 1 $else_part
    } else {
	uplevel 1 $then_part
    }
}
# only set a variable if it's not already defined; also create namespace
proc set_ifndef {var val} {
    if {[uplevel 1 info vars $var] eq {}} {
	set ns [namespace qualifiers $var]
	set v  [namespace tail $var]
	# special case: the global namespace must be "::", not ""
	if {([string range $var 0 1] eq "::") && ($ns eq {})} {
	    set ns ::
	}
	if {$ns eq {}} {
	    set ns [uplevel 1 namespace current]
	}
	uplevel 1 [list namespace eval $ns [list variable $v $val]]
    }
}

# only set a variable (by evaluating an expression) if it's not already defined
#proc eval_ifndef {var expr} {
#    upvar $var v
#    if {![info exists v]} {
#	uplevel 1 "variable $var \"$expr\""
#    }
#}

# only define a procedure if it's not already defined
proc proc_ifndef {name params body} {
    if {[llength [info commands $name]] == 0} {
	proc $name $params $body
    }
}

# assert that the condition is true; else exit with an internal error
proc assert {cond} {

    global __OutputPrefix
    upvar __assertCond acond
    upvar __assertMsg  msg
    set msg "${__OutputPrefix} assertion failed:\n  $cond"
    set acond $cond
    uplevel 1 {if {![expr $__assertCond]} {error $__assertMsg}}
}

# return <n> blanks
proc blanks {n} {
    set r {}
    while {$n>0} {append r { }; incr n -1}
    return $r
}

# output fatal error and exit with code 1
proc exit_msg {msg args} {

    puts stderr "${::__OutputPrefix} $msg"

    #if $::__DbgLevel {
    #    # this gives a stack trace
    #    error "${::__OutputPrefix} exiting."
    #} else {
    #    # this only produces the error message and exits
    #    puts stderr "${::__OutputPrefix} exiting."
    #} 

    if {[info exists ::__Threads] && $::__UseThreads} {
	if [llength $::__RunningThreads] {
	    log_msg "waiting for threads $::__RunningThreads to finish"
	    ::tmk::wait_for_threads_name $::__RunningThreads
	}
    }
    if {[llength $args]} {
	return -options [lindex $args 0] $msg
    } else {
	return -code error $msg
    }
}

# output debugging message if the level is <= __DbgLevel
proc dbg_msg {msg {level 1}} {
    global __DbgLevel
    if {$level <= $__DbgLevel} {log_msg "\[dbg\] $msg"}
}

# output currently executed commands
# if args contains "noprefix", no prefix is used
proc log_msg {msg args} {
    global __DoLog __OutputPrefix
    if $__DoLog {
	if [lcontains $args noprefix] {
	    puts stdout $msg
	} else {
	    puts stdout "${__OutputPrefix} $msg"
	}
    }
}



# ========================================================================
# rule storage/retrieval routines
# ========================================================================

# add a rule for a single target pattern in a global struct
# uses associative arrays
proc __AddRule {pat dep cmd} {

    global __Rules

    # normalize it so the cache will work
    set pat [targetname_short $pat]
    dbg_msg "adding rule $pat <- $dep"
    lappend __Rules($pat) [list $pat $dep $cmd]

}

# retrieve list of rules for a certain pattern.
# note that <pat> should be trimmed before handing it to any proc
proc __GetListOfRules {pat} {
    global __Rules
    if [info exists __Rules($pat)] {
	return $__Rules($pat)
    } else {
	return [list]
    }
}

# retrieve target pattern from a single rule
proc __GetRulePattern {rule} {return [lindex $rule 0]}

# retrieve source file expressions from a single rule
proc __GetRuleSources {rule} {return [lindex $rule 1]}

# retrieve commands from a single rule 
proc __GetRuleCmd     {rule} {return [lindex $rule 2]}

# ========================================================================
# secondary dependencies storage/retrieval routines
# ========================================================================

# add secondary dependencies for a single target pattern in a global struct
# uses associative arrays
proc __AddSecondaries {pat dep} {

    if {[string trim $dep] eq {}} {return}
#    set pat [targetname_short [string trim $pat]]
#    set dep [lmap $dep {[targetname_short $ITEM]}]
    dbg_msg "adding depend ($pat,$dep)"

    # this function only stores a SINGLE pattern!
    assert {[llength $pat] == 1}

    # check if rule for this pattern already exists
    if {! [info exists ::__Secondaries($pat)]} {
	set ::__Secondaries($pat) [list]
    }

    # add new rule to list of rules
    lappend ::__Secondaries($pat) $dep
}

# retrieve list of secondary dependencies for a certain pattern.
proc __GetSecondaries {pat} {

    if [info exists ::__Secondaries($pat)] {
	return $::__Secondaries($pat)
    } else {
	return [list]
    }

}

# ========================================================================
# file searching and parsing
# ========================================================================

#  execute tcl-script (and check for filename conversion)
proc __source {scriptname} {
    if {![file readable $scriptname]} {
	exit_msg "cannot read file $scriptname"
    }
    dbg_msg "executing file $scriptname" 2
    uplevel 1 [list source $scriptname]
#    uplevel 1 source $scriptname
}

# process a makefile. 
proc __ReadMakefile {makefilename} {
    if [file readable $makefilename] {

	# simply parse the makefile as TCL source code in global context
	dbg_msg "----- begin processing $makefilename -----"
	uplevel \#0 [list __source $makefilename]
	dbg_msg "----- end processing $makefilename -----"

    } else {
	exit_msg "could not read $makefilename"
    }
}

# search "TMakefile.project" and "TMakefile.priv", and set PROJDIR
proc __FindGlobalMakefiles {} {

    global __ProjectMakefile __DefaultProjectFileName 
    global __PrivateProjectMakefile __DefaultPrivateProjectFileName
    global ::PROJDIR ::ARGS

    # explicitly do not read a project file (who will ever need this?)
    if {$__ProjectMakefile eq "{}"} {
	set PROJDIR [pwd]
	dbg_msg "skipping TMakefile.proj, setting PROJDIR to $PROJDIR"
	return {}
    }
    
    # -proj not specified? -> look in . .. ../.. ../../.. ...
    if {$__ProjectMakefile eq {}} {
	
	set path [pwd]
	set oldPath dummy$path 
	set found 0
	while {$path ne $oldPath} {
	    set file [file join $path TMakefile.proj]
	    if [file readable $file] {
		set __ProjectMakefile [normalize_filename $file]
		set PROJDIR [file dirname $file]
		dbg_msg "found $file"
		set found 1
		break
	    }
	    dbg_msg "no readable file $file" 2
	    set oldPath $path
	    set path [file dirname $path]
	}

	if {!$found} {
	    set PROJDIR [pwd]
	    dbg_msg "no TMakefile.proj found, setting PROJDIR to $PROJDIR"
	}
	
    } else {
	# use the specified TMakefile.proj
	set PROJDIR [file dirname $__ProjectMakefile]
    }
   
    # -nopriv specified -> just return the .proj file
    if {$__PrivateProjectMakefile eq "{}"} {
	return [list $__ProjectMakefile]
    } 
    # -priv specified? 
    if {$__PrivateProjectMakefile ne {}} {
	return [list $__ProjectMakefile $__PrivateProjectMakefile]
    }
    # look in same directory as .proj
    set file [file rootname $__ProjectMakefile].priv
    if [file readable $file] {
	dbg_msg "found $file"
	set __PrivateProjectMakefile $file
	return [list $__ProjectMakefile $__PrivateProjectMakefile]
    } else {
	set __PrivateProjectMakefile "{}"
	dbg_msg "no readable file $file"
	return [list $__ProjectMakefile]
    }
}

# ========================================================================
# building-time subroutines
# ========================================================================

# compare patterns and create list of all matching rules
proc __GetMatchingRules {target} {

    global __Rules

    # match against all defined target patterns 
    set result [list]
    foreach pat [array names __Rules] {
	if [string match $pat $target] {
	    lappend result {*}$__Rules($pat)
	}
    }

    return $result
}

# compare patterns and create list of all matching secondary dependencies
proc __GetMatchingSecondaries {target} {

    set ts [targetname_short $target]
    
    # loop over all defined rules
    variable result [list]
    foreach pat [array names ::__Secondaries] {
	if [string match $pat $ts] {
	    foreach sec $::__Secondaries($pat) {
		# evaluate T-expression
		set sec [__T_Expr $pat $target $ts $sec \#0 TARGET {}]
		# after T-expr expansion, we can do the dependency exclusions
		__exclude sec $::DEPEND_EXCLUDE \
			"$ts's secondary dependencies" 2
		lappend result {*}$sec
	    }
	}
    }
    return $result
}

# check if a target exists in the specified directory or in .../$ARCH/...
# NOTE: function may change $targetvarname to the correct target location!
# NOTE: returns last modification time in $modtimevarname
proc __TargetExists {targetvarname modtimevarname} {
    upvar $targetvarname target
    upvar $modtimevarname mtime

    global ::USE_ARCH ::ARCH
    assert {[info exists USE_ARCH]}

    # first look in architecture-dependent target directory?
    if $USE_ARCH {
	assert {[info exists ARCH]}
	set dir [file dirname $target] ;   # target base directory name
	set tail [file tail $target]   ;   # target name excluding directory
	set newtarget [file join $dir $ARCH $tail] ; # new target location
	normalize_filevar newtarget
	if [file exists $newtarget] {
	    set target $newtarget ; # !!! changes upvar !!!
	    set mtime [file mtime $newtarget] ; # !!! changes upvar !!!
	    return 1
	} 
    } 
    
    # now look if its in the specified directory
    normalize_filevar target
    if [file exists $target] {
	set mtime [file mtime $target] ; # !!! changes upvar !!!
	return 1
    } else {
	return 0
    }
}

# Find the named file recursively in the specified path
# If a third argument is given, call that procedure with a file name
# argument in order to determine whether the file is suitable. The procedure
# should return 1 if the file is the right one, 0 else.
proc find-file {path filename args} {

    if {0 == [file exists $path]} {
	return {}
    }

    dbg_msg "searching in $path" 3

    # exists in this path?
    if [file exists [file join $path $filename]] {

	# call procedure?
	if [llength $args] {
	    if [$args [file join $path $filename]] {
		return [file join $path$filename]
	    }
	} else {
	    return [file join $path $filename]
	}
    }

    # recurse down
    set d [lfilter [glob -nocomplain -directory $path *] {[file isdirectory $ITEM]}]
    foreach x $d {
	set r [find-file $x $filename $args]
	if [llength $r] {
	    return $r
	}
    }

    return {}
}

# remove leading/trailing spaces
# check if a to-be-built target has to be put into an ARCH directory
# if so, create directory and change target location
# NOTE: function may change $targetvarname to the correct target location!
proc __PrepareNewTarget {targetvarname} {

    upvar $targetvarname target

    # check if we need to append $ARCH to the dir path

    set target [targetname_long $target]
    set newdir [file dirname $target]

    # check if we need to create the directory first
    if [file exists $newdir] {
	if [file isdirectory $newdir] {
	    return  ; # ok, it's already there
	} else {
	    __ExitErr "$newdir already exists, but it is not a directory."
	}
    } else {
	dbg_msg "creating directory $newdir" 2
	__CreateDirRecursively $newdir
    }
}

# recursively create all non-existent parts of a directory path
proc __CreateDirRecursively {dirname} {
    if [file exists $dirname] {
	if [file isdirectory $dirname] {
	    return
	} else {
	    exit_msg "$dirname already exists, but it is not a directory."
	}
    } else {
	file mkdir $dirname
    }
}

# exclude matching things from a list, write dbg message
proc __exclude {varName patlist what {level 1}} {
    
    upvar $varName list
    set ex [lmatch $list $patlist]
    if [llength $ex] {
	dbg_msg "excluding \[$ex\] from $what" $level
	set list [lminus $list $ex]
    }

}

# query state of a target ("failed", "updated", "untouched", or {})
# -  write file modification time or failure message into time_or_msg
proc target_state {target {time_or_msg __ttime}} {
    global __TCACHE
    upvar $time_or_msg msg
    set msg {}
    set short [targetname_short $target]
    if [info exists __TCACHE($short)] {
	set cache $__TCACHE($short)
	set msg [lindex $cache 2]
	return [lindex $cache 1]
    }
    return {}
}

# mark a target as updated; internally called with dbglevel 2
proc target_updated {target {time now} {dbglevel 1}} {
    global __TCACHE 
    if {$time eq "now"} {set time [clock seconds]}
    set ts [targetname_short $target]
    dbg_msg "marking $ts as updated ([clock format $time])" $dbglevel
    set __TCACHE($ts) [list $target updated $time]
    return updated
}

# mark a target as updated; internally called with dbglevel 2
# default timestamp is file mtime if file exists, or 0 else
proc target_untouched {target {time mtime} {dbglevel 1}} {
    global __TCACHE 
    if {$time eq "mtime"} {
	if {![__TargetExists target time]} { ;# sets time upon success
	    set time 0
	}
    }
    set ts [targetname_short $target]
    dbg_msg "marking $ts as untouched ([clock format $time])" $dbglevel
    set __TCACHE($ts) [list $target untouched $time]
    return untouched
}

# mark a target as failed; internally called with dbglevel 2; return state
proc target_failed {target msg {dbglevel 1}} {
    global __TCACHE
    set ts [targetname_short $target]
    dbg_msg "marking $ts as failed ($msg)" $dbglevel
    set __TCACHE($ts) [list $target failed $msg]
    return failed
}

# return cache entry in readable form
proc __print_tcache {t} {
    global __TCACHE 
    if [info exists __TCACHE($t)] {
	set c $__TCACHE($t)
	set stat [lindex $c 1]
	set time [lindex $c 2]
	if {($stat eq "updated") || ($stat eq "untouched")} {
	    return $t:$stat:[clock format $time]
	} elseif {$stat eq "failed"} {
	    return $t:failed:$time
	} else {
	    exit_msg "unknown cache contents for $t"
	}
    } else {
	return "$t: not in target cache"
    }
}


# ************************************
# *** here comes the core of tmk ***
# ************************************

# user-friendly frontend to __Build, returns list with each target's status 
proc build_now {targetlist} {
    set result {}
    foreach x $targetlist {
	puts "building $x"
	lappend result [__Build x msg]
    }
    set ::__AlreadyBuilding 0
    return $result
}

# try to recursively build target 
# NOTE: $targetvarname may be changed according to $USE_ARCH and $ARCH in order
#       to point to the correct target location!
# NOTE: _msg will contain some error message if "failed" is returned
# path contains the list of dependent targets that require this target
#   in the current chain of reasoning; it is used to detect cycles
proc __Build {targetvarname _msg {path {}}} {

    # possible results
    global __TCACHE __ForceBuilding __AlreadyBuilding
    global ::TARGETS ::EXCLUDE 

    # mark that it's now too late to call things like 'build'
    set __AlreadyBuilding 1

    # real target location
    upvar $targetvarname target
    set shorttarget [targetname_short $target]
    dbg_msg "checking target: $shorttarget" 3
    upvar $_msg msg
    set msg {}

    # check cycles
    if [lcontains $path $shorttarget] {
	set msg "dependency loop:\n"
	append msg "   \[[join $path " <- "] <- $shorttarget]"
	exit_msg $msg
    } else {
	lappend path $shorttarget
    }


    # look up target in cache
    # contents of cache: (complete target name, building result, mod time)
    set state [target_state $shorttarget ttime] 
    if {$state ne {}} {
	set target [lindex $__TCACHE($shorttarget) 0]
	dbg_msg "cache hit ($target:$state:$ttime)" 2
	return $state
    }

    
    # find target, and set $target to the real name
    set target_exists [__TargetExists target ttime]

    # check if the target which is not yet finished 
    # is currently beeing updated 
    if {$target_exists == 0} {
	#  create name to look in the cache
	global ::USE_ARCH ::ARCH
	assert {[info exists USE_ARCH]}
	global __TCACHE 
	set lookuptarget [file join $ARCH/[file tail $target]]
	set mytarget [targetname_short $lookuptarget]
	if {[info exists __TCACHE($mytarget)]} {
	    if {[lindex $__TCACHE($mytarget) 1] eq "updated"} {
		return 
	    }
	    
	}
    }


    # look if it has to be excluded
    global ::EXCLUDE
    if {[lmatch $shorttarget $EXCLUDE] ne {}} {
	return exclude
    }

    # secondary dependencies are rule-invariant, but target-dependent
    set tseconds [__GetMatchingSecondaries $target]
    __exclude tseconds $EXCLUDE "$shorttarget's secondary dependencies"
    set tseconds [lmap $tseconds {[targetname_short $ITEM]}]

    # there may be a number of rules for the same target, 
    #   so try them until one can be executed (e.g. all prerequisites exist)
    set rules [__GetMatchingRules $shorttarget]

    # trivial reject
    if {[llength $rules] == 0} { ;#  && [llength $tseconds] == 0

	if {[__TargetExists target ttime]} {
	    set msg "no rule how to make ${target}, but it exists."
	    dbg_msg $msg 2
	    return [target_untouched $target $ttime 2]
	} else {
	    append dbg ..
	    set msg "no rule how to make non-existing ${target}"
	    dbg_msg $msg 1
	    return [target_failed $target $dbg 2]
	}
    }

    dbg_msg  "potential rules for $shorttarget: $rules" 2 

    # try all rules 
    set rule_failure_log {} ;# here we collect all failed rules
    set failed 0
    foreach rule $rules {

	# exit condition
	set try_next_rule 0
	set pattern [__GetRulePattern $rule]
	set sources [__GetRuleSources $rule]

	# try to build all rule source files and secondary dependencies;
	# register the file mod times on that occasion
	set target_needs_update [expr ! $target_exists]
	set realsources {} ;# this will contain the correct locations ($ARCH)
	set realdep     {} 

	# expand T-expressions in $sources
	set tsources [__T_Expr $pattern $target $shorttarget \
		$sources \#0 TARGET {}]
	set slen [llength $tsources]

	# unexpand target names for the sake of the cache
	set tsources [lmap $tsources {[targetname_short $ITEM]}]

	# remove excluded targets (short names!)
	__exclude tsources $EXCLUDE "$shorttarget's primary dependencies"

	# check if all depdency files are there and check their mtime
	set allsrc [list {*}$tsources __XXX__ {*}$tseconds]
	
	# dbg
	set nsources [llength $tsources]
	if {$::__DbgLevel == 1} {
	    dbg_msg "$target <- \[$tsources\], \[[llength $tseconds] secondary dep.\]"
	} else {
	    dbg_msg "$target <- \[$tsources\], \[$tseconds\]" 2
	}
	set isSecondary 0

	foreach src $allsrc {

	    # switch from primaries to secondaries?!
	    if {$src eq "__XXX__"} {

		# special: check if there are no primary dependencies left
		# because of exclusion ; in that case skip this target
		if {($nsources == 0) && ($slen > 0)} {
		    dbg_msg "skipping $shorttarget due to exclusion (no source files left)"
		    # process with next rule???
		    return exclude
		}

		set isSecondary 1
		continue 
	    }
  
	    # try to build prerequisites
	    normalize_filevar src 
	    set result [__Build src msg $path]
	    
	    # special case: skip if source has been excluded for some reason 
	    if {$result eq "exclude"} {
		if {!$isSecondary} {
		    incr nsources -1
		}
		continue
	    } 

	    # add to the list of actually used source / dep files
	    if $isSecondary {
		lappend realdep $src
	    } else {
		lappend realsources $src
	    }

	    if {$result eq "failed"} {

		# if a secondary dependency fails, this is FATAL!
		#  (does not only affect this rule, but all rules)
		if $isSecondary {
		    set err "cannot build $target because $src is missing."
		    set dname [filename_dep [file rootname $target]]
		    if [file exists $dname] {
			append err "\n -> invalid dependency file $dname?"
		    }
		    exit_msg $err
		}

		# if a primary dependency fails, well ... try the next rule
		append rule_failure_log "- could not build $shorttarget from $src:\n"
		append rule_failure_log "  $msg\n"
		set try_next_rule 1
		set failed 1

	    } else {

		# if we've updated a target, we don't need to check its mtime
		# (this also works for virtual targets which get never built)
		if {$result eq "updated"} {
		    dbg_msg "$target must be built because $src has been updated"
		    set target_needs_update 1
		}

		# if we haven't detected that we need an update so far...
		if {!$target_needs_update} {
		    ### DEBUG BEGIN 2004-11-11(Thu) Hitoshi
		    if {[llength $__TCACHE([targetname_short $src])] < 3} {
			puts "DEBUG: Sometimes this __TCACHE has no item, but why?"
			puts "DEBUG: $__TCACHE([targetname_short $src])"
		    }
		    ### DEBUG END   2004-11-11(Thu) Hitoshi
		    set stime [lindex $__TCACHE([targetname_short $src]) 2]
		    if {$stime > $ttime} {
			set target_needs_update 1
			dbg_msg "$target must be built because $src is newer"
			dbg_msg "  (target: $ttime src: $stime)" 2
		    } elseif $__ForceBuilding {
			# build unconditionally?
			if [lcontains $TARGETS $shorttarget] {
			    set target_needs_update 1
			    dbg_msg "$target must be built because of -force"
			}
		    }
		}
	    }

	    if $try_next_rule {break}
	}




	if {[llength $allsrc] > 1} {
	    dbg_msg "back to processing $shorttarget" 2
	}

	# if no source files are specified (only __XXX__), 
	#   build unconditionally
	if {( [llength $allsrc] == 1 ) && ( ! $target_exists )} {
	    
	    __PrepareNewTarget target ; # this may change $target!
	    dbg_msg "$target gets built because it has no prerequisites and does not exist"
	    return [__ExecTargetCode $pattern $target [__GetRuleCmd $rule] \
		    $shorttarget {}]

	}

	# successfully matched a rule -> apply or leave target untouched
	if {!$try_next_rule} {

	    dbg_msg "$target <- \[$realsources\], \[$realdep\]" 2

	    if {!$target_exists} {
		dbg_msg "$target must be built because it does not exist."
	    }

	    if {$target_needs_update} {

 

		# apply commands to build the target
		__PrepareNewTarget target ; # this may change $target!

		# waiting for all relevant threads to finish 
		if $::__UseThreads {
		    if [::tmk::wait_for_threads_name [list {*}$realsources {*}$realdep]] {
			exit_msg "at least on thread failed"
		    }
		}
 		return [__ExecTargetCode $pattern $target \
			[__GetRuleCmd $rule] $shorttarget $realsources]
		
	    } else {
		dbg_msg "nothing to be done for $target"
		return [target_untouched $target $ttime 2]

	    }

	} 

    } ; # end of <loop over all rules>

    if [file exists $target] {
	dbg_msg "leaving $target untouched because no rule applies"
	return [target_untouched $target $ttime 2]
    } else {
	set msg "no rule applicable for building $target"
	if {[string trim $rule_failure_log] ne {}} {
	    append msg "\n$rule_failure_log"
	}
	dbg_msg $msg
	return [target_failed $target $msg 2]
    }
    
}

# output the current list of valid rules and secondary dependencies
proc __OutputRules {fileId} {

    global __Rules

    foreach pat [array names __Rules] {

	# output all rules for this pattern
	foreach rule $__Rules($pat) {
	    
	    puts $fileId "$pat <- [__GetRuleSources $rule]:"
	    puts $fileId "    [__GetRuleCmd $rule]"

	}

	# output all secondary dependencies for this pattern
	set dep [__GetMatchingSecondaries $pat]
	if [llength $dep] {
	    puts $fileId "$pat secondary dependencies:"
	    puts $fileId "    $dep"
	}
    }
}


# ========================================================================
# user commands for defining targets/dependencies/exceptions
# ========================================================================

# define rule for list of target patterns
proc target {targets depfiles cmd} {

    global __SelfDepend __Makefilename __AlreadyBuilding
    set result {}

    foreach target $targets {
	set t [targetname_short $target]
	lappend result $t
	if $__AlreadyBuilding {
	    exit_msg "defining target $t after building has started."
	}
	__AddRule $t $depfiles $cmd
	if $__SelfDepend {depend $t $__Makefilename}
    }

    return $result
}

# skip execution of the ``normal'' rule in an exception
proc exception_return {} {
    global __ex_skip
    set __ex_skip 1
}

# define an exception for a list of target patterns
proc exception {targets vars script} {

    global __ExceptionScript __ExceptionVars 

    foreach target $targets {
	set t [targetname_short $target]
	if [__PatternInCache $t match] {
	    log_msg "warning: defining exception for $t after $match has been processed."
	}
	set __ExceptionScript($t) $script
	set __ExceptionVars($t)   $vars
    }

}

# define secondary dependencies (those not coming with a building rule)
proc depend {targets depfiles} {
    # todo: normalize DEPEND_EXCLUDE
    # global ::DEPEND_EXCLUDE 

    foreach target $targets {

	set t [targetname_short $target]
	if [__PatternInCache $t match] {
	    log_msg "***** WARNING: calling depend for $t after $match has been processed."
	}
	
#	dbg_msg "secondary: $t <- \{$depfiles\}" 1
	__AddSecondaries $t $depfiles
    }
} 


# define which targets to build by default
proc build {targets} {

    global ::TARGETS __AlreadyBuilding

    foreach target $targets {
	set t [targetname_short $target]
	if $__AlreadyBuilding {
	    exit_msg "calling 'build' after building has already started"
	}
	dbg_msg "adding default target $t" 
	lappend TARGETS $t
    }
}

# check if the single pattern matches any target in the cache 
# return matched target if any
proc __PatternInCache {pat {matchVar __xxx}} {

    global __TCACHE
    set names [array names __TCACHE]
    set t [lsearch -glob $names $pat]
    if {$t != -1} {
	upvar $matchVar up
	set up [lindex $names $t]
	return 1
    }
    return 0
  
}

# ===========================================================================
# subdirectory processing 
# ===========================================================================

# process outer list of inner lists of subdirectories;
# all items of an inner list can be processed independently (in parallel)
proc subdir {subdirslist} {
    lappend ::tmk::SUBDIRS {*}$subdirslist
}

# declare a target local-only. This will prevent subdirectory processing
#   when this target is specified
proc local_only {targetlist} {
    foreach target $targetlist {
	dbg_msg "marking $target as local-only"
	lappend ::tmk::LOCALTARGETS $target
    }
}

# process all subdirs that have been declared so far
proc tmk::process_subdirs {} {

    if {[llength tmk::SUBDIRS] < 1} {
	dbg_msg "no subdirs specified" 2
    }
    # remove local-only targets from command line
    foreach x $::tmk::localtargets {lremove ::ARGS $x}

    # conditions under which we should not process subdirectories
    if [llength $::tmk::localtargets] {
	if {![llength $::tmk::normaltargets]} {
	    dbg_msg "only local targets specified  - skipping subdirs"
	    return
	}
    }
    if {[lsearch -exact $::ARGS {-f}] != -1} {
	dbg_msg "skipping subdirectory processing (-f specified)"
	return 
    }

    # pass TMakefile.proj and TMakefile.priv down to subprocesses later
    lremove ::ARGS -noproj ; lremove ::ARGS -nopriv
    lremove ::ARGS -proj 1 ; lremove ::ARGS -priv 1

    # remember where we are now
    dbg_msg "processing subdirs: $tmk::SUBDIRS" 2
    set currentdir [pwd]
    normalize_filevar currentdir

    # normalize path names
    set ::SUBDIR_EXCLUDE [lmap $::SUBDIR_EXCLUDE {[normalize_filevar ITEM]}]

    # loop through outer list
    set changed 0
    foreach subdirs $::tmk::SUBDIRS {

	# normalize path names
	set subdirs [lmap $subdirs {[normalize_filevar ITEM]}]

	# exclude certain directories from subdirectory list
	set subdirs [lminus $subdirs $::SUBDIR_EXCLUDE]

	# exclude everything which is not a directory
	set subdirs [lfilter $subdirs {[file isdirectory $ITEM]}]

	# use only those dirs  where we find a TMakefile
	set subdirs [lfilter $subdirs {[file exists [file join $ITEM TMakefile]]}]

	# recursively call tmk in all those items that are directories
	set parallel [expr [llength $subdirs] > 1]
	if $parallel {
	    dbg_msg "processing in parallel: $subdirs"
	}
 
	foreach dir $subdirs {
	    
	    # pass location of project TMakefiles down to subprocesses
	    set pmf {}
	    if {![file readable [file join $dir TMakefile.proj]]} {
		if {$::__ProjectMakefile eq "{}"} {
		    lappend pmf -noproj
		} else {
		    lappend pmf -proj $::__ProjectMakefile
		    if {$::__PrivateProjectMakefile eq "{}"} {
			lappend pmf -nopriv
		    } else {
			lappend pmf -priv $::__PrivateProjectMakefile
		    }
		}
	    }
	    

	    # when processing in parallel, add some output prefix for logging
	    if {!$parallel} {
		dbg_msg "processing subdir $dir"
		set prefix [list] 
	    } else {
		set prefix [list -prefix tmk:[file tail $dir]:]
	    }
	    
	    # execute tmk in subdir; make sure stdout/stderr 
	    # remain the same
	    cd $dir
	    set cmd [list {*}$::TMK {*}${pmf} -D __TmkInSubdir=1 \
		{*}$::ARGS {*}$prefix >@stdout 2>@stderr <@stdin]

	    dbg_msg "calling $cmd"

	    # do NOT protocol this recursive execution
	    if {[info commands ::tmk::old_exec] ne {}} {
		set exec ::tmk::old_exec
	    } else {
		set exec exec
	    }
	    # TODO: parallel execution
	    if {[catch {$exec -- {*}$cmd} msg] != 0} {
		exit_msg $msg
	    }
	    
	    cd $currentdir
	    set changed 1
	}
    }
    
    if $changed {
	log_msg {} noprefix
	log_msg "back in directory $currentdir"
    }
    
}

# ============================================================================
# module handling
# ============================================================================

# execute all modules in the list
# module name may contain ::version
proc module {modules} {

    global ::tmk::dir MODULES env

    foreach mod $modules {
	
	# specific version requested?
	set p [string first :: $mod]
	set mod [string tolower $mod]
	if {$p != -1} {
	    set modver [string range $mod [expr $p + 2] end]
	    set mod [string range $mod 0 [expr $p - 1]]
	    dbg_msg "requested module $mod \[$modver\]" 2
	} else {
	    # default: get active or default version
	    if [lcontains $MODULES ${mod}] {
		eval set modver \$\{::${mod}::VERSION\}
		dbg_msg "using already active version \[$modver\] for $mod" 2
	    } else {
		if {[info vars ::${mod}::DEFAULT_VERSION] ne {}} {
		    eval set modver \$\{::${mod}::DEFAULT_VERSION\}
		    dbg_msg "using default version \[$modver\] for $mod" 2
		} else {
		    set modver {}
		    dbg_msg "no version given for $mod" 2
		}
	    }
	}


	# module already loaded? check for version conflict!
	if [lcontains $MODULES ${mod}] {
	    eval set actVers \$\{::${mod}::VERSION\}
	    if {$actVers == $modver} {
		dbg_msg "module $mod already loaded" 2
		continue
	    } else {
		set conf "$mod \[$actVers\] and $mod \[$modver\]"
		exit_msg "cannot load two versions of same module\n  ($conf)"
	    }
	}

	# register module, and set active version
	lappend MODULES ${mod}
	namespace eval ::${mod} [list variable VERSION $modver]

	# this imports the right config vars (e.g. of a version) into ::$mod
	load_submodule $mod $modver

	# look if some macro variables <modulename>::<something> are set,
	# and if so, do the corresponding action
	set found [__eval_module_macros $mod]

	# load module file
	set file [::tmk::find_module_file $mod dirs]
	if {$file ne {}} {
	    dbg_msg "reading module $mod file $file"
	    uplevel \#0 [list namespace eval ::${mod} [list __source $file]]
	} else {
	    if {!$found} {
		set msg "module $mod version $modver requested,\n"
		append msg "  but no ${mod}::... config variables found,\n"
		append msg "  and no $mod.tmk file found in \[$dirs\]"
		exit_msg $msg
	    }
	}
    }

}

# find a module file in the appropriate path
proc ::tmk::find_module_file {module {pathvarname __xxx}} {

    global env ::tmk::MODULE_PATH
    
    set mod [string tolower $module]
    # search module file in the current dir and the path
    set dirs [list . {*}${::tmk::MODULE_PATH}]

    if [info exists env(TMK_MODULE_PATH)] {
	lappend dirs {*}$env(TMK_MODULE_PATH)
    }
    lappend dirs [file join $::tmk::dir modules]

    # pass path to caller
    upvar $pathvarname path
    set path $dirs

    # now look for the first one we find
    return [lindex [find_in_pathlist $mod.tmk $dirs] 0]
}


# activate a specific submodule (e.g. version) of a module's variables
# by importing the vars+procs from ::module::ver into ::module
# - recursively: import mod <- mod::v1 <- mod::v1::v1.1
proc load_submodule {mod version} {
    
    # create namespace if not already done
    namespace eval ::$mod {}
    
    # recurse until we reach the last version segment
    set p [string first :: $version]
    if {$p != -1} {
	set rmod "${mod}::[string range $version 0 [expr $p - 1]]"
	load_submodule $rmod [string range $version [expr $p + 2] end]
	set version [string range $version 0 [expr $p - 1]]
    }

    # no special version requested? nothing to do
    if {[string trim $version] eq {}} {
	return 
    }
    set v ::${mod}::$version

    set v [string map {:::: ::} $v]
    if {![lcontains [namespace children ::$mod] $v]} {
	exit_msg "version ${version} of module ${mod} does not exist." 
    }

    # override the generic variables with those for the specific version
    set ns ::${mod}::${version}
    foreach v [info vars ${ns}::*] {
	dbg_msg "$v -> ::${mod}::[namespace tail $v]" 2
	eval set ${mod}::[namespace tail $v] \$\{$v\}
    }
    # now the same procedure for procedures (as every year)
    namespace eval ${ns} namespace export *
    namespace eval ::${mod} namespace import -force ${ns}::*

}

# look which of the module macros are set, and trigger corresponding action
# return if any variable was found
proc __eval_module_macros {names} {
    global MODULE_ACTION
    set found 0
    foreach name $names {
	set name [string tolower $name]
	foreach var [array names MODULE_ACTION] {
	    if {[info vars ::${name}::${var}] ne {}} {
		set found 1
		dbg_msg "executing config macro $var for module $name" 2
		uplevel \#0 [list set __MODNAME $name]
		uplevel \#0 namespace eval ::$name [list $MODULE_ACTION($var)]
	    }
	}
    }
    return $found
}

# recursively list all children namespaces of a given absolute namespace
proc tmk::children_namespaces {ns} {
    namespace eval $ns {}
    set ch [namespace eval :: [list namespace children $ns]]
    set result {}
    foreach c $ch {
	lappend result $c
	lappend  result {*}[tmk::children_namespaces $c]
    }
    return $result
}

# Register some code which has to be executed right before starting to build
#   the targets. This is used (for example) in the modules.
proc eval_later {proc} {

    global __BBProcs 
    lappend __BBProcs [uplevel 1 [list namespace code $proc]]

}

# return normalized absolute namespace for a given variable or procedure
proc tmk::full_namespace {name} {
    set name [string trim $name]
    set ns [namespace qualifiers $name]
    if {($ns eq {}) && ([string range $name 0 1] eq "::")} {
	set ns ::
    } else {
	set ns [uplevel 1 namespace current]::$ns
    }
    set ns [split $ns :]
    lremove ns {}
    return ::[join $ns ::]
}


# return normalized procedure name for tracing a variable / procedure
#   and return namespace name in ns_var
proc tmk::trace_proc_name {name} {
    set ns [uplevel 1 tmk::full_namespace $name]
    set procname ${ns}::[namespace tail $name]
    regsub -all : $procname _ procname
    return ::tmk::__trace$procname
}

# Evaluate the value for a variable just when the variable is first needed.
#   The value expression is treated as the body of a procedure (use return)
#  if msg_only, then the variable isn't changed, but only the code is executed
proc set_lazy {varname script {msg_only 0}} {
    
    set ns       [uplevel 1 tmk::full_namespace $varname]
    set var      [namespace tail $varname]
    set procname [tmk::trace_proc_name $varname]

    # set the on-read trace
    namespace eval ::$ns [list variable $var {<lazy>}]
    trace variable ${ns}::$var r  ${procname}_lazy
    trace variable ${ns}::$var wu ${procname}_lazy_forget

    # define the evalutation procedure to be called
    set body {

	dbg_msg "lazily setting ${ns}::$var" 3
	
	# call the defining procedure
	if $msg_only {
	    set cmd ${procname}_lazy_expr
	} else {
	    set cmd "variable $var \[${procname}_lazy_expr\]"
	}
	namespace eval ${ns} \$cmd

	# if var is traced, output result!
	if [lcontains \$::tmk::traced_vars ${ns}::$var] {
	    uplevel 1 $procname
	}
	# now stop expanding the variable's value on further read ops
	${procname}_lazy_forget \$__name \$__elem xy
    }	
    proc ${procname}_lazy_expr {} [list uplevel \#0 $script]
    proc ${procname}_lazy {__name __elem __op} [subst -nocommands $body]

    # override lazy evaluation if variable is written or unset lateron
    set body {

	dbg_msg "forgetting lazy value for ${ns}::$var" 3
	# delete all traces for this variable
        trace vdelete ${ns}::$var r ${procname}_lazy
        trace vdelete ${ns}::$var wu ${procname}_lazy_forget
        rename ${procname}_lazy {}
        rename ${procname}_lazy_expr {}
        rename ${procname}_lazy_forget {}
    }
    proc ${procname}_lazy_forget {name elem op} [subst -nocommands $body]
}

# lazy-evaluate the value for a variable;
#   update the value every time the 'dependency variable' is changed
proc set_connected {varname depvars script} {
    
    set ns       [uplevel 1 tmk::full_namespace $varname]
    set var      [namespace tail $varname]
    set procname [tmk::trace_proc_name $varname]

    # set the on-read trace for the targeted variable
    namespace eval ::$ns {}
    trace variable ${ns}::$var r ${procname}_lazy
    # set the on-modification trace for the dependency variables
    set depvars_full {}
    foreach depvar $depvars {
	set dns       [uplevel 1 tmk::full_namespace $depvar]
	set dvar      [namespace tail $depvar]
	lappend depvars_full ${dns}::$dvar
	namespace eval ::$dns {}
	trace variable ${dns}::$dvar w ${procname}_lazy
    }
    
    # define the evalutation procedure to be called
    set body {

	# if some dep var is not set yet, don't eval lazy expr
	foreach v {$depvars_full} {
	    if {[uplevel 1 info vars \$v] eq {}} {
		dbg_msg "cannot set ${ns}::$var yet because \$v is not set"
		return
	    }
	}
	
	# call the defining procedure
	namespace eval ::${ns} [list variable $var \[${procname}_lazy_expr\]]
	# if var is traced, output result!
	if [lcontains \$::tmk::traced_vars ${ns}::$var] {
	    uplevel 1 $procname
	}
	# now stop expanding the variable's value on further read ops
        trace vdelete ${ns}::$var r ${procname}_lazy
    }
    proc ${procname}_lazy_expr {} [list uplevel \#0 $script]
    proc ${procname}_lazy {__name __elem __op} [subst -nocommands $body]
}

# delete dependencies to other variables (as done by set_connected)
proc set_disconnect {varname depvars} {

    # remove the on-modification trace for the dependency variables
    set procname [tmk::trace_proc_name $varname]
    foreach depvar $depvars {
	set dns       [uplevel 1 tmk::full_namespace $depvar]
	set dvar      [namespace tail $depvar]
	namespace eval ::$dns {}
	trace vdelete ${dns}::$dvar w ${procname}_lazy
    }

}

# ========================================================================
# additional helper commands for use in TMakefiles
# ========================================================================

# file containing dependency information 
proc filename_dep {shortname} {return $shortname.dep}

# echo a command before doing it
proc echo args {
    global __DoLog
    if $__DoLog {
	uplevel [list puts \{$args\}]
	flush stdout
    }
    uplevel 1 $args
}

# echo and execute a command, 
# and cleanly exit with an error message if needed
proc cmd args {

    global __DoCmd __DoLog

    if $__DoLog {
	puts $args
	flush stdout
    }

    if $__DoCmd {
	if [catch {uplevel exec $args >@stdout 2>@stderr <@stdin} m o] {
	    exit_msg $m $o
	} 
    }
    return 1
   
}


# execute a command, and do NOT redirect output to stdout/stderr; 
# cleanly exit with an error message if needed
proc cmd_quiet args {
    global __DoCmd
    if $__DoCmd {
	if [catch {uplevel exec $args} msg opts] {
	    exit_msg $msg $opts
	} 
    }
    return 1
}


# read a named file and append it to a given variable
# don't append anything if the file does not exist
proc read_file {filename varName} {
    upvar $varName result
    if [file exists $filename] {
	set f [open $filename r]
	while {![eof $f]} {
	    append result [gets $f]\n
	}
	close $f
    } else {
	if {![info exists result]} {
	    set result {}
	}
    }
}

# write a string into a file; if args is "append", append to existing file
proc write_file {filename varName args} {
    upvar $varName txt
    if {$args eq "append"} {
	set f [open $filename a+]
    } else {
	set f [open $filename w]
    }
    puts $f $txt
    close $f
}

# ===========================================================================
# array related procedure
# ===========================================================================
# \param  _arrayName an array name to look up.
# \param  _key
# \return return 1 if _arrayName(_key) exists.
proc arraykeyexistp {_arrayName _key} {
    upvar ::$_arrayName array1
    assert [array exists array1] 
    if {[info exist array1($_key)]} {
        # puts "key exists"
        return 1
    } else {
        # puts "no key"
        return 0
    }
}

# \param  _arrayName an array name to look up.
# \param  _key       key of associative array.
# \param  _val       value. A list is also acceptable.
# \return return 1 if [ $_arrayName($_key) == $val ] == 1.
proc arraykeyvalexistp {_arrayName _key _val} {
    upvar _arrayName array
    if {[arraykeyexistp $_arrayName $_key]} {
        foreach elem $array($key) {
            if {$elem == $_val} {
                # puts "_key _val exists"         
                return 1
            }
        }
    }
    return 0
}

#
# runmode convenient function \internal
# such key exist?
#
proc ::tmk::is_runmodestat {_key} {
    return [ arraykeyexistp __RunModeStatList $_key ]
}

#
# runmode convenient function \internal
# get the value of \param _key
#
proc ::tmk::get_runmodestat {_key} {
    global __RunModeStatList

    if ![::tmk::is_runmodestat $_key] {
	dbg_msg "no such runmode key ($_key)"
	return 0
    } else {
	return $__RunModeStatList($_key)
    }
}
#
# runmode convenience function \internal
# set the key and value with checking candidates list.
# \param _keyval "key=value", ex. "addressmode=64bit"
# \return true if key is exist and set is succeeded.
#
proc ::tmk::set_runmodestat {_keyval} {
    global __AvailableRunModeStatLList
    global __RunModeStatList

    set kv  [split  $_keyval =]
    set key [lindex $kv      0]
    if {[llength $kv] == 1} {
	dbg_msg "($kv) is key=, the value is missing."
	return 0
    } else {
	set value [lindex $kv 1]
    }
    
    if {[arraykeyvalexistp __AvailableRunModeStatLList $key $value]} {
	set __RunModeStatList($key) $value
	return 1
    } else {
	dbg_msg "could not find mode = $key, value = $value, no set."
	return 0
    }
}

# ===========================================================================
# file/target name handling 
# ===========================================================================

# if USE_ARCH is on, insert $ARCH as last path segment if it's not 
# already somewhere in the path
proc targetname_long  {target} {

    normalize_filevar target

    # no ARCH? don't do anything 
    if {!$::USE_ARCH} {return $target}

    set d [file split $target]
    if {([file pathtype $target] ne "relative") || [lcontains $d $::ARCH]} {
	return $target
    }

    # insert PATH at the beginning (?)
    return [eval file join \{$::ARCH\} $d]
}

# if USE_ARCH is on, and first path item is $ARCH, remove it
proc targetname_short {target} {

    normalize_filevar target

    if {!$::USE_ARCH} {return $target}
    if {[file pathtype $target] ne "relative"} {return $target}
    set d [file split $target]
    if {[lindex $d 0] ne $::ARCH} {return $target}
    return [eval file join [lrange $d 1 end]]
}


# ========================================================================
# tmk command line argument parsing
# ========================================================================

proc __ExitWithSyntax {} {

    global ::tmk::dir_src __txt
    read_file [file join $::tmk::dir_src help.msg] __txt
    uplevel \#0 {puts stderr [subst -nocommands $__txt]}
    exit 1
}

# parse command line and set some global variables accordingly
proc __ParseCommandLine {argv0 argv} {

    global ::__rest ::__args ::__opt ::ARGS ::__OPT_ACTION 
    global ::__mark_updated ::__mark_untouched

    dbg_msg "called $argv0 $argv" 2
    set ARGS $argv
    set opt_loaded 0
    set __mark_updated {}
    set __mark_untouched {}

    # targets specified at command line
    global ::__CmdLineTargets 
    set __CmdLineTargets {}
    
    # parse options (starting with -)
    set __rest $argv
    set __args [llength $__rest]
    
    while {$__args > 0 && [string range $__rest 0 0] eq "-"} {

	# this is supposed to be an option, so load option scripts
	if {!$opt_loaded} {
	    uplevel \#0 {__source [file join $::tmk::dir_src cmdline.tmk]}
	}
	set __opt [lindex $__rest 0]
	set __rest [lrange $__rest 1 end]
	set __args [llength $__rest]
	
	# explicit end of options
	if {"$__opt" eq "--"} {
	    break
	}
	if [info exists __OPT_ACTION($__opt)] {
	    uplevel \#0 $__OPT_ACTION($__opt)
	} else {
	    __ExitWithSyntax
	}
    }

    # the remaining command line arguments are supposed to be targets
    if [llength $__rest] {
	set __CmdLineTargets $__rest
    }

}

# execute "before building" procedures registered in the modules
proc __doEvalLaterCommands {} {
    global ::__BBProcs
    for {set i 0} {$i  < [llength $__BBProcs]} {incr i} {
	uplevel \#0 [lindex $__BBProcs $i]
    }
}
    

# ========================================================================
# T-expression handling
# ========================================================================

# Expand a T-expression. Make sure all special and user-defined vars are set
# - level denotes the uplevel on which the expression should be evaluated
# - mainname e.g. can be TARGET or ITEM
# - prefix is prepended to the variable names like ROOT, BASE, etc.
proc __T_Expr {T_pat T Ts cmd level mainname prefix} {
    # special variables within rule commands
    upvar $level $mainname     item 
    upvar $level ${prefix}ROOT root 
    upvar $level ${prefix}TAIL tail
    upvar $level ${prefix}DIR  dir
    upvar $level ${prefix}EXT  ext
    upvar $level ${prefix}BASE base
    set item $T
    set root [file rootname $T]
    set tail [file tail $T]
    set dir  [file dirname $T]
    set ext  [file extension $T]
    set base [file rootname [file tail $T]]

    # more special variables, matching the wildcard characters
    set wildvars [__MakeWildcardVars $T_pat $Ts $prefix]
    foreach v $wildvars {uplevel $level [list set [lindex $v 0] [lindex $v 1]]}

    # now evaluate expression in global context and return expanded expression
    set result [uplevel $level [list subst $cmd]]

    # remove special variables from global context
    unset item root tail dir ext base
    foreach v $wildvars {uplevel $level [list unset [lindex $v 0]]}

    # ... and that's it

    return $result
}

# perform a command containing T-expressions. make sure all special
# and user-defined vars are set; handle exceptions
proc __T_Command {T_pat T Ts cmd sources} {

    global __DisplayCommandsOnly

    # special variables within rule commands
    set level \#0
    upvar $level TARGET target
    upvar $level ROOT   root
    upvar $level TAIL   tail
    upvar $level DIR    dir
    upvar $level EXT    ext
    upvar $level BASE   base
    upvar $level SRC    src
    set target $T
    set root   [file rootname $T]
    set tail   [file tail $T]
    set dir    [file dirname $T]
    set ext    [file extension $T]
    set base   [file rootname [file tail $T]]
    set src    $sources

    # more special variables, matching the wildcard characters
    set wildvars [__MakeWildcardVars $T_pat $Ts {}]
    foreach v $wildvars {uplevel $level [list set [lindex $v 0] [lindex $v 1]]}

    # since the expression will be evaluated in global context, we must
    # export the expression (and import an error message)
    upvar $level __cmd__ret ret
    set ret {}

    # if there is an exception for this target, 
    #    store/restore specified variables
    global __ExceptionVars __ExceptionScript __ex_skip
    upvar \#0 __ExPattern __ExPattern
    set ShortT [targetname_short $T]
    assert {[llength [array names __SavedVars]] == 0}
    assert {[llength [array names __UnsetVars]] == 0}
    set __ex 0
    set __ex_skip 0
    foreach __ExPattern [array names __ExceptionScript] {
	if {![string match $__ExPattern $ShortT]} {
	    continue
	}
	set __ex 1
	uplevel \#0 {
	    set __Vars $__ExceptionVars($__ExPattern)
	    ### should check if already saved/unset -> error!!! ###
	    dbg_msg "${__ExPattern}: saving \[$__Vars\] for exception" 2
	    set __UnsetVars {}
	    foreach __x $__Vars {
		if [info exists $__x] {
		    eval set __SavedVars($__x) \$$__x
		} else {
		    lappend __UnsetVars $__x
		}
	    }
	    
	    dbg_msg "executing exception for $__ExPattern" 1
	    eval $__ExceptionScript($__ExPattern)
	}
    }

    # exceptional skip of the usual rule?
    if {$__ex_skip} {

	dbg_msg "exception: skipping usual rule for $ShortT" 1

    } else {
	# only pretend to do it?
	if {$__DisplayCommandsOnly} {
	    upvar $level __TSubst subst
	    set subst $cmd
	    if {[uplevel $level {
		set __try {[subst -nocommands $__TSubst]}
		catch {set __TSubst $__try} __TMsg
	    }]} {
		# subst did not work - so try simpler method
		upvar $level __TMsg msg
		dbg_msg "pretend subst failed: $msg" 2
		set txt $cmd
		regsub -all {\$\{*TARGET\}*} $txt $target txt
		regsub -all {\$\{*ROOT\}*}   $txt $root   txt 
		regsub -all {\$\{*DIR\}*}    $txt $dir    txt 
		regsub -all {\$\{*EXT\}*}    $txt $ext    txt 
		regsub -all {\$\{*BASE\}*}   $txt $base   txt 
		regsub -all {\$\{*SRC\}*}    $txt $src    txt
		regsub -all {\$\{*TAIL\}*}   $txt $tail   txt
		foreach v $wildvars {
		    regsub -all "\$\{*[lindex $v 0]\}*" $txt [lindex $v 1] txt
		}
	    } else {
		# subst did not fail - show subst'ed result
		set txt $subst
	    }
	    puts stdout $txt
	} else {
	    # debugging output only if we first output the command...
	    dbg_msg "executing for target $T ($src): $cmd" 3
	    
	    # here it is actually executed
	    if {[catch {uplevel $level $cmd} __cmd_ret catch_opts]} {
		exit_msg $ret $catch_opts
	    }
	}
    }

    # restore specified globals as they were before the exception
    if $__ex {
	uplevel \#0 {
	    dbg_msg "restoring \[[array names __SavedVars]\] after exception" 2
	    foreach __x [array names __SavedVars] {
		set $__x $__SavedVars($__x)
		unset __SavedVars($__x)
	    }
	    dbg_msg "un-setting \[$__UnsetVars\] after exception" 2
	    foreach __x $__UnsetVars {
		if [info exists $__x] {unset $__x}
	    }
	}
    }

    # remove special variables from global context
    unset target root tail dir ext base ret src
    foreach v $wildvars {uplevel $level [list unset [lindex $v 0]]}
}

# execute the stored code for this target; 
# - maybe schedule / exec in parallel
# - handle exceptions
# - update target state
proc __ExecTargetCode {pattern target cmd short src} {

    global __TCACHE

    # delete old cache entry!
    if [info exists __TCACHE($short)] {
	unset __TCACHE($short)
    }

    __T_Command $pattern $target $short $cmd $src

    # mark as updated if the rule has not already marked the target
    if {![info exists __TCACHE($short)]} {
	target_updated $target now 2
    } 

}

# find wildcards in pattern and set corresponding wildcard variable values
# returns list of {varname value} pairs
proc __MakeWildcardVars {pattern value {varprefix {}}} {

    # properly terminate regexp pattern
    set saved $pattern
    set pattern {^$pattern$}
    # replace regexp special characters without special meaning (.+)
    foreach p {{\.} {\+} {\[} {\]} {\|} {\(} {\)}} {
	regsub -all $p $pattern $p pattern
    }
    # replace * and ? by their corresponding regexp sisters
    #  and count how many wildcards we've got
    set  count [regsub -all {\*} $pattern {(.*)} pattern]
    incr count [regsub -all {\?} $pattern {(.)}  pattern]

    # create corresponding regexp command
    if $count {
	set cmd "regexp \{$pattern\} \{$value\} dummy "
	for {set i 0} {$i < $count} {incr i} {append cmd "$varprefix$i "}
	eval set check \[$cmd\]
	if {!$check} {
	    exit_msg "regexp \{$pattern\} ($saved) does not match \{$value\}" 
	}
	assert {$check}
	for {set i 0} {$i < $count} {incr i} {
	    lappend result [eval list $i \"\$$varprefix$i\"]
	}
	return $result
	
    } else {
	return {}
    }
}


# ========================================================================
# L-expression handling
# ========================================================================

#TODO: the documentation says that [lmap "a b c" {$ITEM $ITEM}] returns
#a a b b c c
#this is no-longer true.  It now returns [list {a a} {b b} {c c}]

# map a function to all items in a list and return list of mapped items
proc lmap {list func} {
    set result [list] 
    foreach item $list {
	lappend result [__T_Expr {} $item $item $func 2 ITEM I]
    }
    return $result
}

# each item may only occur once. order is changed. 
# in future lsort -unique, so this is not user-visible
proc ::tmk::lunify {list} {
    set list [lsort $list]
    set result {}
    while {[llength $list]} {
	if {[lindex $list 0] != [lindex $list 1]} {
	    lappend result [lindex $list 0]
	}
	set list [lrange $list 1 end]
    }
    return $result
}

# returns all item that match any of the patterns
proc lmatch {list patterns} {

    set result {}
    foreach item $list {
	foreach pat $patterns {
	    if {[string match $pat $item]} {
		lappend result $item
		break
	    }
	}
    }
    return $result
}

# check if an item is contained in a list
proc lcontains {list item} {

    return [expr [lsearch -exact $list $item] != -1]
}

# return a list which contains only those items for which the function
#   becomes true
proc lfilter {list func} {
    set result {}
    foreach item $list {
	if [__T_Expr {} $item $item $func 2 ITEM I] {
	    lappend result $item
	}
    }
    return $result
}

# remove all items from A which are found in B
proc lminus {listA listB} {

    set result {}
    foreach item $listA {
	if {[lsearch -exact $listB $item] == -1} {
	    set result [lappend result $item]
	}
    }
    return $result
}

# remove all items from listName which match the given pattern
#   also remove <nargs> words following each matching argument
proc lremove {listName pattern {nargs 0}} {
    upvar $listName listA
    set rest $listA
    set listA {}
    while {[llength $rest]} {
	set item [lindex $rest 0]
	if [string match $pattern $item] {
	    set rest [lrange $rest [expr 1 + $nargs] end]
	} else {
	    lappend listA $item
	    set rest [lrange $rest 1 end]
	}
    }
    return $listA
}

# ========================================================================
# utility functions
# ========================================================================

proc tmk::arch_domain_unix {} {
    # get domainname 
    set ::DOMAIN localdomain
    if {[catch {set ::DOMAIN [exec domainname]}]} {
	catch {set ::DOMAIN [exec hostname -d]}
    }
    if {[string trim $::DOMAIN] eq {}} {
	set ::DOMAIN localdomain
    }

    # domainname may return an empty line...
    #set tmpDomain localdomain
    #if {[string trim $tmpDomain] eq {}} {
    #    # problem: hostname may hang!
    #    if [catch {set tmpDomain [exec hostname \-d]}] {
    #	set tmpDomain localdomain
    #    }
    #}
}

proc tmk::arch_unix {} {
}

proc tmk::os_cygwin {} {
    set ::OS $::STR_CYGWIN
    switch -glob [string tolower [exec uname -s]] {
	*_me-* {set ::OSVER ME}
	*_98-* {set ::OSVER 98}
	*_nt-5* {set ::OSVER 2K }
	*_nt-* {set ::OSVER NT}
	*_95-* {set ::OSVER 95}
	default {exit_msg "cannot determine system type ($__SystemUname)"}
    }
}

proc tmk::arch_cygwin {} {
	#a cygwin architecture has two flavours
	# 1. program invoked in cygwin environment, e.g., bash 
	# 2. progam invoked in windows environment, e.g., cmd.exe

    # =====================================
    # Cygwin GCC/G++ systems 
    # =====================================

    # try to figure out the name of this machine
    if {[catch {set ::HOST [exec hostname]}]} {
	if {[catch {set ::HOST $env(HOSTNAME)}]} {
	    if {[catch {set ::HOST $env(HOST)}]} {
		set ::HOST localhost
	    }
	}
    }
    # host name should be lower case
    set ::HOST [string tolower $::HOST]

    tmk::arch_domain_unix

    if {$::DOMAIN eq "localdomain"} {
	catch {file mkdir [::tmk::config_dir]}
	if [file exists [::tmk::config_dir]/$::HOST.domain] {
	    set inf [open [::tmk::config_dir]/$::HOST.domain r]
	    set ::DOMAIN [read -nonewline $inf]
	    close $inf
	} else {
	    set outf [open [::tmk::config_dir]/$::HOST.ipf w]
	    catch {exec ipconfig.exe /All >&@$outf}
	    close $outf
	    set inf [open [::tmk::config_dir]/$::HOST.ipf r]
	    foreach i [split [read $inf] \n] {
		if [regexp {Primary DNS Suffix.*: (.*)$} $i a b] {
		    set ::DOMAIN [string tolower [string trim $b]]
		    break
		} else {
		    if [regexp {: (.*)$} $i a b] {
			set b [string tolower $b]
			set dsplit [split $b .]
			if {[lindex $dsplit 0] eq $::HOST \
			    && [llength $dsplit] > 1} {

			    set ::DOMAIN [string range $b \
				[expr [string length $::HOST] + 1] end]
			    set dout [open [::tmk::config_dir]/$::HOST.domain w]
			    puts $dout $::DOMAIN
			    close $dout
			    break
			}	
		    }
		}
	    }
	    close $inf
	}
    }

    # convert domain to lower case
    set ::DOMAIN [string tolower $::DOMAIN]

    ::tmk::os_cygwin

    # get CPU info
    set __cpuName {}
    catch {set __cpuName [exec regtool get \
	/machine/hardware/description/system/centralprocessor/0/identifier]}
    
    set __cpu unknowncpu
    set __cpuName [string tolower $__cpuName]
    if {$__cpuName ne {}} {
	# no alpha's or ppc's here (does this work for AMDs ?)

	switch -regexp $__cpuName {
	    .*pentium.*iii .* {set ::CPU pentium3}
	    .*pentium.*ii .*  {set ::CPU pentium2}
	    .*pentium.*       {set ::CPU pentium}
	    .*amd.*athlon.*   {set ::CPU athlon}
	    default             {set ::CPU ix86}
	} 
    } else {
	set ::CPU unknowncpu
    }
    
    set ::VENDOR pc
}

proc tmk::osvers_posix {} {
    # cut os version down to only 2 segments (should we?)
    set ::OSVER [join [lrange [split $::OSVER .] 0 1] .] 
}

package provide tmk 0.1
