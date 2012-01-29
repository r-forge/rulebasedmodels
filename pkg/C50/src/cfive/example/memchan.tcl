namespace eval vfs {}

proc vfs::memchan {} {
	# Create the channel and obtain a generated channel identifier
	set fd [chan create {read write} [namespace origin memchan_handler]]
	# Initialize the data and seek position
	set ::vfs::_memchan_buf($fd) ""
	set ::vfs::_memchan_pos($fd) 0
	return $fd
}

proc vfs::memchan_handler {cmd chan args} {
	upvar 1 ::vfs::_memchan_buf($chan) buf
	upvar 1 ::vfs::_memchan_pos($chan) pos
	switch -exact -- $cmd {
		initialize {
			foreach {mode} $args break
			return [list initialize finalize watch read write seek]
		}
		finalize {
			unset buf pos
		}
		seek {
			foreach {offset base} $args break
			switch -exact -- $base {
				current { incr offset $pos }
				end     { incr offset [string length $buf] }
			}
			return [set pos $offset]
		}
		read {
			foreach {count} $args break
			set r [string range $buf $pos [expr {$pos + $count - 1}]]
			incr pos [string length $r]
			return $r
		}
		write {
			foreach {data} $args break
			set count [string length $data]
			if { $pos >= [string length $buf] } {
				append buf $data
			} else {
				set last [expr { $pos + $count - 1 }]
				set buf [string replace $buf $pos $last $data]
			}
			incr pos $count
			return $count
		}
		watch {
			# We are required to implement 'watch' but are doing nothing.
			foreach {eventspec} $args break
		}
	}
}
