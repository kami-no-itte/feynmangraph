
proc FG_StartText {w} {
    global db diag
    FG_Cancel $w
    
    set db(linetype) Text
    set db(linecolor) $db(linecolor,Text)

    FG_BindSave $w

    bind $w <1>               {FG_CreateText %W %x %y}
    bind $w <2>               {FG_Cancel   %W noupdate}
    
    set db(mode) "Drawing Text"
}       

proc FG_CreateText {w x y} {
    global db

    set db(linetype) Text
    incr db(tagN)
    focus $w

    regexp {^\.([^.]*)} $w m ww    
    if { $db($ww,SnapToGrid) == "On" } { scan [GridXY $w $x $y] %f%f x y }

    set id [eval {$w create text} $x $y {-tags "text Text t$db(tagN) region editable" \
	    -text "" -fill red -font $db($ww,font)} -anchor sw]
    SetSel $w Text $id
    FG_TextEdit $w $x $y $id
    set db(mode) "Text Created"
}

proc FG_TextEdit {w x y id} {
    global db
    focus $w
    $w focus $id
    $w icursor $id @$x,$y
    $w select from $id @$x,$y
    $w dtag movable

    SetSel $w Text $id

    bind $w <1> {}
    $w bind $id <1> {
	%W focus editable
	%W icursor editable @%x,%y
	%W select from editable @%x,%y
    }
    $w bind $id <B1-Motion> {
	if { [%W find withtag editable] != {}} {
	    %W select to editable @%x,%y
	}
    }
#    $w bind $id <Key-A> {
#	if { [%W select item] != {} } {
#	    %W dchars [%W select item] sel.first sel.last
#	} elseif { [%W focus] != {} } {
#   	   %W dchars [%W focus] insert
#	}
#    }

    bind $w <Control-d> {
	if {[%W focus] != {}} {
	    %W dchars [%W focus] insert
	}
    }   
    bind $w <Return> {%W insert editable insert \n}
    bind $w <Delete> {
	if { [%W select item] != {} } {
	    %W dchars [%W select item] sel.first sel.last
	} elseif { [%W focus] != {} } {
	    set _t [%W focus]
	    %W icursor $_t [expr [%W index $_t insert]]
	    %W dchars $_t insert
	    unset _t
	}
    }
    bind $w <BackSpace> {
	if { [%W select item] != {} } {
	    %W dchars [%W select item] sel.first sel.last
	} elseif { [%W focus] != {} } {
	    set _t [%W focus]
	    %W icursor $_t [expr [%W index $_t insert]-1]
	    %W dchars $_t insert
	    unset _t
	}
    }
    bind $w <Escape> { FG_SaveText  %W }
    bind $w <Any-Key> {
	%W focus editable
	%W insert editable insert %A
    }
    bind $w <Key-Right> {
	%W icursor editable [expr [%W index editable insert]+1]
    }
    bind $w <Key-Left> {
	%W icursor editable [expr [%W index editable insert]-1]
    }
    $w bind $id <2> {
	if {[%W select item] != {}} {
	    %W dchars [%W select item] sel.first sel.last
	}
    }
	
    bind $w <3>               { FG_SaveText  %W }
	set db(mode) "Editing Text"
}

proc FG_SaveText {w} {
    global db

    set type "Text"
    set tt [$w itemconfigure editable -text]
    if { [lindex $tt [expr [llength $tt]-1]] == {}} {
	$w delete editable
	set cmd "noupdate"
    } else {
	set id [$w find withtag editable]
	$w select clear
	$w itemconfigure $id -fill $db(linecolor,$type)
	$w dtag region
	$w dtag movable
	$w dtag editable
	$w bind $id <1> "FieldEvent %W %x %y Text $id"
	$w bind $id <Double-1> {
	    SetSel %W Text "[%W find withtag current]" 
	    DoubleFieldEvent  %W %x %y Text $db(Selid)
	}
	$w bind $id <2>               {Remove_SelReg %W  }
	bind $w <3> {}
	set cmd ""
    }
    regexp {^\.([^.]*)} $w m ww 
    focus $m
    focus .
    UnsetSel
    set db(mode) "Text fixed"
    FG_StopRegDraw $w $cmd

}

proc DoubleFieldEvent {w x y Text id} {
    global db
    if { [$w find withtag rectangle] != "" } {
	return
    }

    set selid ""
     if [info exists db(Selid)] {
	set selid $db(Selid)
    }

    switch -glob $db(mode) {
	"Drawing $db(linetype)" {
	    FG_StopRegDraw $db(Selw)
	}
	"Editing Text" {
	    FG_SaveText $db(Selw)
	    Cancel_SelReg
	}
	Area {
	    return
	}
	* {
	    FG_Cancel $w
	}
    }

    $w itemconfigure $id -fill red
    FG_BindSave $w

    $w addtag editable withtag current
    SetSel $w Text $id

    FG_TextEdit $w $x $y $id
}








