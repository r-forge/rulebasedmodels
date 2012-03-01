#! /bin/env tclsh

namespace eval tmk {}

# ========================================================================
# T-expression handling
# ========================================================================

# Expand a T-expression. Make sure all special and user-defined vars are set
# - level denotes the uplevel on which the expression should be evaluated
# - mainname e.g. can be TARGET or ITEM
# - prefix is prepended to the variable names like ROOT, BASE, etc.
proc __T_Expr { T_pat T Ts cmd level mainname prefix } {

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
    foreach v $wildvars {uplevel $level "unset [lindex $v 0]"}

    # ... and that's it
    return $result
}

# perform a command containing T-expressions. make sure all special
# and user-defined vars are set; handle exceptions
proc __T_Command { T_pat T Ts cmd sources } {

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
    set wildvars [__MakeWildcardVars $T_pat $Ts ""]
    foreach v $wildvars {uplevel $level "set [lindex $v 0] [lindex $v 1]"}

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

    # now evaluate and execute script in global context
    set todo "catch \{while 1 \{$cmd; break\}\} __cmd__ret"

    # exceptional skip of the usual rule?
    if $__ex_skip {

	dbg_msg "exception: skipping usual rule for $ShortT" 1

    } else {
	# only pretend to do it?
	if $__DisplayCommandsOnly {
	    upvar $level __TSubst subst
	    set subst $cmd
	    if {[uplevel $level {
		set __try {[subst -nocommands $__TSubst]}
		catch "set __TSubst $__try " __TMsg
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
	    if [uplevel $level $todo] {
		exit_msg $ret
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
    foreach v $wildvars {uplevel $level "unset [lindex $v 0]"}
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
proc __MakeWildcardVars {pattern value {varprefix ""}} {

    # properly terminate regexp pattern
    set saved $pattern
    set pattern "^$pattern\$"
    # replace regexp special characters without special meaning (.+)
    foreach p { {\.} {\+} {\[} {\]} {\|} {\(} {\)} } {
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
proc lmap { list func } {
    set result [list] 
    foreach item $list {
	lappend result [__T_Expr "" $item $item $func 2 ITEM I]
    }
    return $result
}

# each item may only occur once. order is changed. 
# in future lsort -unique, so this is not user-visible
proc ::tmk::lunify { list } {
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
proc lmatch { list patterns } {

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
proc lcontains { list item } {

    return [expr [lsearch -exact $list $item] != -1]
}

# return a list which contains only those items for which the function
#   becomes true
proc lfilter { list func } {
    set result ""
    foreach item $list {
	if [__T_Expr "" $item $item $func 2 ITEM I] {
	    lappend result $item
	}
    }
    return $result
}

# remove all items from A which are found in B
proc lminus { listA listB } {

    set result {}
    foreach item $listA {
	if { [lsearch -exact $listB $item] == -1 } {
	    set result [lappend result $item]
	}
    }
    return $result
}

# remove all items from listName which match the given pattern
#   also remove <nargs> words following each matching argument
proc lremove { listName pattern {nargs 0}} {
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
    set ::DOMAIN "localdomain"
    if [catch { set ::DOMAIN [exec domainname] }] {
	catch { set ::DOMAIN [exec hostname -d] }
    }
    if {[string trim $::DOMAIN] == ""} {
	set ::DOMAIN "localdomain"
    }

    # domainname may return an empty line...
    #set tmpDomain "localdomain"
    #if {[string trim $tmpDomain] == ""} {
    #    # problem: hostname may hang!
    #    if [catch {set tmpDomain [exec hostname \-d]}] {
    #	set tmpDomain "localdomain"
    #    }
    #}
}

proc tmk::arch_unix {} {
}

proc tmk::os_cygwin {} {
    set ::OS $::STR_CYGWIN
    switch -glob [string tolower [exec uname -s]] {
	"*_me-*" {set ::OSVER "ME"}
        "*_98-*" {set ::OSVER "98"}
	"*_nt-5*" {set ::OSVER "2K" }
	"*_nt-*" {set ::OSVER "NT"}
	"*_95-*" {set ::OSVER "95"}
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
    if [catch { set ::HOST [exec hostname] } ] {
	if [catch { set ::HOST $env(HOSTNAME) } ] {
	    if [catch { set ::HOST $env(HOST) } ] {
		set ::HOST "localhost"
	    }
	}
    }
    # host name should be lower case
    set ::HOST   [string tolower $::HOST]

    tmk::arch_domain_unix

    if { $::DOMAIN == "localdomain" } {
	catch { file mkdir [::tmk::config_dir] }
	if [file exists "[::tmk::config_dir]/$::HOST.domain"] {
	    set inf [open "[::tmk::config_dir]/$::HOST.domain" "r"]
	    set ::DOMAIN [ read -nonewline $inf]
	    close $inf
	} else {
	    set outf [open "[::tmk::config_dir]/$::HOST.ipf" "w"]
	    catch { exec ipconfig.exe /All >&@$outf }
	    close $outf
	    set inf [open "[::tmk::config_dir]/$::HOST.ipf" "r"]
	    foreach i [split [read $inf] "\n"] {
		if [regexp "Primary DNS Suffix.*\: \(.*\)\$" $i a b] {
		    set ::DOMAIN [string tolower [string trim $b]]
		    break
		} else {
		    if [regexp "\: \(.*\)\$" $i a b] {
			set b [string tolower $b]
			set dsplit [split $b "."]
			if { [lindex $dsplit 0] == $::HOST && [llength $dsplit] > 1 } {
			    set ::DOMAIN [string range $b [expr [string length $::HOST] + 1] end]
			    set dout [open "[::tmk::config_dir]/$::HOST.domain" "w"]
			    puts $dout "$::DOMAIN"
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
    set __cpuName ""
    catch { set __cpuName [exec regtool get \
			       /machine/hardware/description/system/centralprocessor/0/identifier ] }
    
    set __cpu "unknowncpu"
    set __cpuName [string tolower $__cpuName]
    if { $__cpuName != "" } {
	# no alpha's or ppc's here (does this work for AMDs ?)

	switch -regexp $__cpuName {
	    ".*pentium.*iii .*" { set ::CPU "pentium3" }
	    ".*pentium.*ii .*"  { set ::CPU "pentium2" }
	    ".*pentium.*"       { set ::CPU "pentium"  }
	    ".*amd.*athlon.*"   { set ::CPU "athlon" }
	    default             { set ::CPU "ix86" }
	} 
    } else {
	set ::CPU "unknowncpu"
    }
    
    set ::VENDOR "pc"
}

proc tmk::osvers_posix {} {
    # cut os version down to only 2 segments (should we?)
    set ::OSVER [join [lrange [split $::OSVER "."] 0 1] "."] 
}

package provide tmk 0.1
