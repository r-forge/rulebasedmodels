#! /bin/env tclsh

variable myaliasdir [file dirname [info script]]
variable myrealdir [ \
	file dirname [file dirname [file join [info script] __dummy__]]]

proc findLibTclCfive {} {
	set suffixes [list .so .dylib]
	if {[info sharedlibext] ni $suffixes} {
		lappend suffixes [info sharedlibext]
	}
	set libnames [list]
	foreach suffix $suffixes {
		lappend libnames libtclcfive$suffix
	}
	variable myrealdir
	variable myaliasdir
	foreach mydir [list $myaliasdir $myrealdir] {
		foreach libname $libnames {
			set maybe [file join $mydir $libname]
			if {[file exists $maybe]} {
				return $maybe
			}
		}
		foreach maybe [glob -directory $mydir -types d -nocomplain *] {
			foreach libname $libnames {
				set maybe [file join $maybe $libname]
				if {[file exists $maybe]} {
					return $maybe
				}
			}
		}
		return -code error "Could not find libtclcfive.so"
	}
}

proc loadLibTclCfive {} {
	set libTclCfiveFname [findLibTclCfive]
	load $libTclCfiveFname cfive
}

package require vfs
source [file join [file dirname [info script]] inmemvfs.tcl]
vfs::inmem::Mount cfive:// cfive://
loadLibTclCfive


package provide cfive 0.1
