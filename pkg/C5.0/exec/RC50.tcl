#! /bin/env tclsh

package require cfive

proc Rcfive {resname args} {
	upvar $resname myres
	vfs::inmem::Mount Rcfiveinternal:// Rcfiveinternal://
	set stdout_fname Rcfiveinternal://stdout
	set stderr_fname Rcfiveinternal://stderr
	set fh [open $stdout_fname w]
	cfive_stdio stdout $fh
	set fh2 [open $stderr_fname w]
	cfive_stdio stderr $fh
	cfive {*}$args
	seek $fh 0
	set myres(stdout) [read $fh]
	seek $fh2 0
	set myres(stderr) [read $fh2]
	cfive_stdio stdout stdout
	cfive_stdio stderr stderr
	close $fh
	close $fh2
	set found 0
	set stem cfive
	set suffixes [list tree rules out set]
	foreach suffix $suffixes {
		set fname "$stem.$suffix"
		set myres($suffix) {} 
		if {[file exists $fname]} {
			set fh [open $fname]
			set text [read $fh]
			close $fh
			set myres($suffix) $text 
			file delete -force $fname 
		}
	}
	return {} 
}

package provide RC50 1.0
