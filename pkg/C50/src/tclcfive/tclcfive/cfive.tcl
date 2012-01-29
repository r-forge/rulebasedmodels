#! /bin/env tclsh

variable myaliasdir [file dirname [info script]]
variable myrealdir [ \
	file dirname [file dirname [file join [info script] __dummy__]]]

proc findLibTclCfive {} {
	set libname libtclcfive.so
	variable myrealdir
	variable myaliasdir
	foreach mydir [list $myaliasdir $myrealdir] {
		set maybe [file join $mydir $libname]
		if {[file exists $maybe]} {
			return $maybe
		}
		foreach maybe [glob -directory $mydir -types d -nocomplain *] {
			set maybe [file join $maybe $libname]
			if {[file exists $maybe]} {
				return $maybe
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
