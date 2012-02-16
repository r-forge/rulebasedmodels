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

package require Tcl 8.5
package require tcltest 2.2
namespace import tcltest::*

set tcltestfailed 0
configure {*}$argv -testdir [file dir [info script]]
namespace eval tcltest {
	proc cleanupTestsHook {} {
		incr ::tcltestfailed $::tcltest::numTests(Failed)
	}
}
runAllTests
exit [expr $::tcltestfailed > 0]
