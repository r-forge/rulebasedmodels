#! /bin/env tclsh

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
