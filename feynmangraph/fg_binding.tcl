
proc FG_BindSave {w} {
        global bindings
        foreach ev "[bind $w]" {
                set bindings($w,$ev) [list $ev [bind $w $ev]]
	}
#	bind $w <Shift-B1-Motion> {return}
#	bind $w <Shift-ButtonRelease-1> {return}
}

proc FG_BindPrint {w} {
        global bindings
        foreach ev "[bind $w]" {
                puts "$w : $ev [bind $w $ev]"
        }
}
proc FG_BindRestore {w} {
	global bindings
	foreach ev "[bind $w]" {
		if {![info exists bindings($ev)]} {bind $w $ev {}}
	}
	foreach ev "[array names bindings $w,*]" {
		bind $w [lindex $bindings($ev) 0] [lindex $bindings($ev) 1]
	}
#	bind $w <Shift-B1-Motion> {}
#	bind $w <Shift-ButtonRelease-1> {}
}






