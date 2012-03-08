.onLoad <- function (libname ,pkgname) {
	addTclPath(system.file("exec" ,package="C50"))
	addTclPath(system.file("tclcfive" ,package="C50"))
	addTclPath(system.file("Memchan" ,package="C50"))
	addTclPath(system.file("tclvfs" ,package="C50"))
	tcl("package" ,"require" ,"vfs")
	tcl("package" ,"require" ,"RC50")
}

file.C5 <- function (name ,data) {
	fh <- tcl("open" ,name ,"w")
	tcl("puts" ,fh ,data)
	tcl("close" ,fh)
}
