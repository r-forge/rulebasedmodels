# Package vfs::inmem provides an in-memory file system; this is
# useful if you want a small file system on which you can
# mount other kinds of files and store small amounts of data.

package provide vfs::inmem 0.1

# We use dicts, so we need Tcl 8.5 or later.

package require Tcl 8.5
package require vfs 1.0

# The "fsdata" array contains dicts describing file systems. The dicts
# represents a file structure. The file structure uses the following keys:
#
#	data	the file's data; what this is depends on the "type"
#		attribute of the "stat" entry for the file. (See below.)
#		For type "directory", it is a dict whose keys are directory
#		names; the dict entries  will be file structures.
#
#	stat	file attributes: file type, access permissions, etc.
#		The data associated with this key is a dictionary
#		containing data in the form returned by the "file stat"
#		command. The only mandatory info is the file type.
#
#	meta	metadata associated with this file. This could be
#		anything.
#
# fsdata is indexed by an arbitrarily-selected key supplied by the
# "Mount" command.

namespace eval vfs::inmem {
    variable fsdata
    variable localmap
}


#################################
#				#
#	U T I L I T I E S	#
#				#
#################################

# _dictpath converts "relpath" to a list of keys that indexes
# into the nested file structures. "relpath" is assumed to be
# a list of pathname components. (Basicly, this consists of putting
# the word "data" before the list element names.) No checking
# is done to ensure that the path is valid.

proc vfs::inmem::_dictpath {relpath} {
    set keylist [list]
    foreach component $relpath {
	lappend keylist data $component
    }
    return $keylist
}

# _checkpath checks a relative path to make sure that all components
# except the last exist and are directories. It returns 1 on success,
# and throws an error otherwise.

proc vfs::inmem::_checkpath {fsname relpath} {
    variable fsdata

    if {![info exists fsdata($fsname)]} {
	return -code error "File system \"$fsname\" doesn't exist."
    }

    set dirdata $fsdata($fsname)
    set reldir [lrange $relpath 0 end-1]
    set file [lindex $relpath end]

    foreach component $reldir {
	if {![string equal [dict get $dirdata stat type] "directory"]} {
	    return -code error "Path component is not a directory"
	}

	set dirdata [dict get $dirdata data]
	set dirdata [dict get $dirdata $component]
    }

    return 1
}

# _getfiledict returns the dictionary associated with the file
# within file system "fsname" that is specified by "relpath".

proc vfs::inmem::_getfiledict {fsname relpath} {
    variable fsdata

    set dictpath [_dictpath $relpath]
    if {[llength $dictpath] == 0} {
	return $fsdata($fsname)
    }
    return [eval [list dict get $fsdata($fsname)] $dictpath]
}

# _newstatinfo creates a dictionary appropriate for use as the "stat"
# entry for a file of type "type".

proc vfs::inmem::_newstatinfo {type} {
    return [dict create \
	atime [clock seconds] \
	ctime [clock seconds] \
	dev -1 \
	gid -1 \
	ino -1 \
	mode 0777 \
	mtime [clock seconds] \
	nlink 1 \
	size 0 \
	type $type \
	uid -1 \
    ]
}

# _updatetime updates access/creation/modification times for
# the file given by "relpath". Which time to update is determined
# by the "timetype" argument, which should be one of "atime",
# "ctime", or "mtime". (This argument is NOT checked, so be careful!)

proc vfs::inmem::_updatetime {fsname relpath timetype} {
    variable fsdata

    set fpath [_dictpath $relpath]
    dict set fsdata($fsname) {*}$fpath stat $timetype [clock seconds]
}

#################################
#				#
#	V F S   P R O C S	#
#				#
#################################

# The procs that follow are the ones required by the Tcl vfs package.


# Mount mounts an in-memory file system named "fsname" on the
# local mount point "local". "fsname" is an arbitrary key;
# it must be unique among all inmem vfs file systems. It returns
# the mount point.

proc vfs::inmem::Mount {fsname local} {
    variable fsdata
    variable localmap

    # Make an empty directory.

    set fsdata($fsname) [dict create \
			data [dict create] \
			stat  [_newstatinfo directory] \
			meta "" \
		]

    vfs::filesystem mount $local [list vfs::inmem::handler $fsname]
    vfs::RegisterMount $local [list vfs::inmem::Unmount]
    set localmap($local) $fsname

    return $local
}

# Unmount unmounts file system "local".

proc vfs::inmem::Unmount {local} {
    variable fsdata
    variable localmap

    set fsname $localmap($local)
    catch [list unset fsdata(fsname)]
    vfs::filesystem unmount $local
}

# This is the generic handler for file system commands. It dispatches
# calls to other handler functions.

proc vfs::inmem::handler {fsname cmd root relative actualpath args} {
    variable fsdata

    set relative [file split $relative]

    if {$cmd == "matchindirectory"} {
	eval [list $cmd $fsname $relative $actualpath] $args
    } else {
	eval [list $cmd $fsname $relative] $args
    }
}

# "stat" implements the "file stat" command. It accepts the
# file system name and the path name as arguments, and
# returns the file's status info as a dict.

proc vfs::inmem::stat {fsname name} {
    _checkpath $fsname $name
    set fdict [_getfiledict $fsname $name]
    return [dict get $fdict stat]
}

proc vfs::inmem::access {fsname name mode} {
    variable fsdata

    _checkpath $fsname $name

    set fdict [_getfiledict $fsname $name]

    set statInfo [dict get $fdict stat]
    set fmode [dict get $statInfo mode]

    # We're assuming the file is owned by us and has our own
    # gid. (Since it's seen only within this app, that has
    # to be true.)

    return [expr {($mode & $fmode) != 0}]
}

# vfs::inmem::exists returns 1 if file "name" exists on file
# system "fsname"; it returns zero otherwise.

proc vfs::inmem::exists {fsname name} {
    set ecode [catch [list _getfiledict $fsname $name] fdict]

    if {$ecode} {
	return 0
    }
    return 1
}

# Open a file. This returns a list containing two elements:
#	1. the Tcl channel name which has been opened
#	2. (optional) a command to evaluate when the channel is closed.

proc vfs::inmem::open {fsname name mode permissions} {
    variable fsdata


    switch -- $mode {
	"" -
	"r" {
	    # The file was opened for read; we'll read the
	    # data out of the filesystem's dict and stuff
	    # it into a memchan file descriptor. We pass
	    # the memchan file descriptor back so that the
	    # data can be read from it.

	    set nfd [vfs::memchan]
	    fconfigure $nfd -translation binary
	    set fdict [_getfiledict $fsname $name]
	    puts -nonewline $nfd [dict get $fdict data]
	    _updatetime $fsname $name atime
	    fconfigure $nfd -translation auto
	    seek $nfd 0
	    return [list $nfd]
	}
	"w" {
	    # Open for write; we pass back an empty memchan,
	    # and on close we read the data out of it and put
	    # it into the file.

	    set dictpath [_dictpath $name]
	    if {![exists $fsname $name]} {
		set emptydata [dict create data {} \
			stat [_newstatinfo file] \
			meta {}]
		dict set fsdata($fsname) {*}$dictpath $emptydata
		_updatetime $fsname $name ctime
		_updatetime $fsname $name atime
	    }
	    _updatetime $fsname $name mtime
	    dict set fsdata($fsname) {*}$dictpath stat size 0
	    set nfd [vfs::memchan]
	    return [list $nfd [list ::vfs::inmem::_close $fsname $name $nfd]]
	}
	"a" {
	    # Open for append; this is pretty much like write, except
            # that we put the data in it initially.

	    set dictpath [_dictpath $name]
	    if {![exists $fsname $name]} {
		set emptydata [dict create data {} \
			stat [_newstatinfo file] \
			meta {}]
		dict set fsdata($fsname) {*}$dictpath $emptydata
		set initData ""
		_updatetime $fsname $name ctime
		_updatetime $fsname $name atime
	    } else {
		set initData [dict get $fsdata($fsname) {*}$dictpath data]
	    }
	    _updatetime $fsname $name mtime
	    dict set fsdata($fsname) {*}$dictpath stat size \
					[string bytelength $initData]
	    set nfd [vfs::memchan]
	    fconfigure $nfd -translation binary
	    puts -nonewline $nfd $initData
	    _updatetime $fsname $name atime
	    fconfigure $nfd -translation auto
	    return [list $nfd [list ::vfs::inmem::_close $fsname $name $nfd]]
	}
	default {
	    return -code error "illegal or unimplemented access mode \"$mode\""
	}
    }
}


# _close is called when we close a file we're writing to. It reads
# the data out of the memchan it was written to and puts it into
# the filesystem's dict.

proc vfs::inmem::_close {fsname name nfd} {
    variable fsdata

    set fpath [_dictpath $name]
    seek $nfd 0
    set filedata [read $nfd]
    dict set fsdata($fsname) {*}$fpath data $filedata
    dict set fsdata($fsname) {*}$fpath stat size \
				[string bytelength $filedata]
    _updatetime $fsname $name mtime

    close $nfd
}


# vfs::inmem::matchindirectory does a glob-style match on a single
# directory in an inmem filesystem.

proc vfs::inmem::matchindirectory {fsname path actualpath pattern type} {
    set dirdict [_getfiledict $fsname $path]

    # "res" will contain the matched directory.

    set res [list]
    set filelist [dict get $dirdict data]
    foreach f [dict keys $filelist] {
	if {[string length $pattern] == 0 || [string match $pattern f]} {
	    set ftype [dict get $filelist $f stat type]
	    switch $ftype {
		directory {
		    if {[::vfs::matchDirectories $type]} {
			lappend res $f
		    }
		}
		file {
		    if {[::vfs::matchFiles $type]} {
			lappend res $f
		    }
		}
		link {
		    #@@@ NOT YET IMPLEMENTED @@@#
		}
	    }
	}
    }

    # Prepend the directory name onto every name in the list.

    set realres [list]
    foreach r $res {
	set rr [file join $actualpath $r]
	lappend realres $rr
    }
    
    return $realres
}


# vfs::inmem::createdirectory creates a directory entry for
# an inmem filesystem. It creates an entry in the filesystem's
# dict.

proc vfs::inmem::createdirectory {fsname name} {
    variable fsdata

    if {[string equal "" $name]} {
	return
    }

    if {[exists $fsname $name]} {
	return
    }

    set parent [lrange $name 0 end-1]
    set dirname [lindex $name end]
    set dictpath [_dictpath $parent]
    lappend dictpath data
    set newdir [dict create \
			data {} \
			stat [_newstatinfo directory] \
		]
    
    dict set fsdata($fsname) {*}$dictpath $dirname $newdir
    _updatetime $fsname $parent mtime
}


# Remove a directory.

proc vfs::inmem::removedirectory {fsname name recursive} {
    variable fsdata

    set parent [lrange $name 0 end-1]
    set dictpath [_dictpath $name]
    dict unset fsdata($fsname) {*}$dictpath
    _updatetime $fsname $parent mtime
}


# Delete a file.

proc vfs::inmem::deletefile {fsname name} {
    variable fsdata

    set parent [lrange $name 0 end-1]
    set dictpath [_dictpath $name]
    dict unset fsdata($fsname) {*}$dictpath
    _updatetime $fsname $parent mtime
}


# fileattributes returns or sets filesystem-dependent file attributes.

proc vfs::inmem::fileattributes {fsname name args} {
    switch -- [llength $args] {
	0 {
	    # list strings
	    return [list "Unimplemented"]
	}
	1 {
	    # get value
	}
	2 {
	    # set value
	}
    }
}


#@@@ I don't know if this is necessary... @@@#

proc vfs::inmem::utime {what name actime mtime} {
    error ""
}
