#! /bin/env tclsh

variable myaliasdir [file dirname [info script]]
variable myrealdir [ \
	file dirname [file dirname [file join [info script] __dummy__]]]

proc findLibTclCfive {} {
	set allsuffixes [list .so .dylib]
	set suffixes [info sharedlibext]
	foreach suffix $allsuffixes {
		if {$suffix ni $suffixes} {
			lappend suffixes $suffix
		}
	}
	set libnames [list]
	foreach suffix $suffixes {
		lappend libnames libtclcfive$suffix
	}
	variable myrealdir
	variable myaliasdir
	set res [list]
	foreach mydir [list $myaliasdir $myrealdir] {
		foreach libname $libnames {
			set maybe [file join $mydir $libname]
			if {[file exists $maybe]} {
				lappend res $maybe
			}
		}
		foreach maybe [glob -directory $mydir -types d -nocomplain *] {
			foreach libname $libnames {
				set maybe [file join $maybe $libname]
				if {[file exists $maybe]} {
					lappend res $maybe
				}
			}
		}
	}
	if {[llength $res]} {
	    return $res
	}
	return -code error "Could not find libtclcfive ($suffixes)"
}

proc loadLibTclCfive {} {
	set libTclCfiveFnames [findLibTclCfive]
	foreach fname $libTclCfiveFnames {
		if {![catch {load $fname cfive}]} {
			return
		}
	}
}

package require vfs
source [file join [file dirname [info script]] inmemvfs.tcl]
vfs::inmem::Mount cfive:// cfive://
loadLibTclCfive


package provide cfive 0.1
