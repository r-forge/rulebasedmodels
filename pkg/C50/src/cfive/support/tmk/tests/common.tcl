#! /bin/env tclsh

# Copyright (C) 2011-2012, Nathan Coulter and others 

#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 2 of the License.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

package require tcltest

proc cat {fname} {
	set data [read [set fh [open $fname]]]
	close $fh
	return $data
}

proc setup1 {name} {
	global testout myroot testdata
	file delete -force [file join $testout $myroot $name]
	set myrootout [file join $testout $myroot $name]
	file mkdir $myrootout 
	file copy -force [file join $testdata $myroot $name] $myrootout
	set myprojout [file normalize [file join $myrootout $name]]
	cd $myprojout
	return $myprojout
}

interp alias {} f {} file

eval ::tcltest::configure $argv

set testdata [file normalize testdata]
if {[info exists env(ARCH)] && [file isdirectory $env(ARCH)]} {
	cd $env(ARCH)
}
set testout [file normalize testout]
file mkdir $testout
set proj1 proj1
#set baseout [uplevel info t] 
set myroot [file rootname [file tail [dict get [info frame 1] file]]]

variable mydir [file join [file dirname [info script]]]
variable maybe [file join [file dirname $mydir] pkgIndex.tcl]
if {[file exists $maybe]} {
	set auto_path [linsert $auto_path 0 [file dirname $maybe]]
}

namespace eval ::tmk::test {
		namespace import ::tcltest::*
}

