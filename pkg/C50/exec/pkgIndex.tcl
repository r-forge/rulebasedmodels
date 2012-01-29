#! /bin/env tclsh

package ifneeded RC50 1.0 [list source [file join $dir RC50.tcl]]

#this is not currently needed
#package ifneeded RC50 1.0 [list tclPkgSetup $dir RC50 1.0 {
#	{ RC50.tcl source RC50::init }
#	{ libC50.so load cfive }
#}]
