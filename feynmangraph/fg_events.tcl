
proc FG_Cancel {w {cmd {}}} {

    global db stroke
    catch {unset stroke}
    if { [info exists db(Selw)] } {
	set w $db(Selw)
    }
    if { $db(mode) == "Editing Text"} {
	FG_SaveText $w
	Cancel_SelReg noupdate
	set db(mode) "Editing $db(linetype) Cancelled"
	return
    }
    catch {$w delete region}
    catch {$w delete Bbox}
    if { $db(mode) == "Drawing $db(linetype)" || \
	    $db(mode) == "$db(linetype) Created"} {
	FG_StopRegDraw $w noupdate
	set db(mode) "Drawing $db(linetype) Cancelled"
    } else {
	Cancel_SelReg $cmd
    }
    focus .
}


proc FG_StopRegDraw {w {cmd ""}} {

    regexp {(.+)\.[^.]$} $w m ww
    FG_BindRestore $w
    if { "$cmd" != "noupdate" } { FG_CreateDiagConfig $ww }
}



proc FieldEvent {w x y type id} {
    global diag db buffer
    if { [$w find withtag Bbox] != "" } {
	AreaEvent $w $x $y
	return
    }
    if { [info exists db(Selw)] } {
	if { ($db(Selw) == $w && \
	      ( $db(mode) == "Drawing $db(linetype)" || \
                $db(mode) == "$db(linetype) Created")) || \
		$db(mode) == "Area Marked" } return
	if { $db(mode) == "Editing Text" } {FG_SaveText $db(Selw)}
    } else {
	if { $db(mode) == "Drawing $db(linetype)" } return
    }
    FG_BindRestore $w
    Cancel_SelReg
    regexp {^\.([^.]*)} $w m ww 
    focus $m
    focus .
 
    set db(linetype) $type
    foreach idd "$id" {
	switch -glob $type {
	    Oval {
		$w itemconfigure $idd -outline  red
	    }
	    blob {
		$w itemconfigure $idd  -fill red -outline red
	    }
	    Image {
		foreach ID "[$w find all]" {
		    $w raise $ID Image
		}
	    }
	    * {
		$w itemconfigure $idd -fill red
	    }
	}
    }
    FG_BindSave $w
    SetSel $w $type $id
    foreach idd "$id" {
	$w addtag movable withtag $idd
    }
    foreach var "[array names buffer]" {
	unset buffer($var)
    }
    FG_CopyToBuf $w $x $y $type $id
    FG_MoveBegin $w $x $y
    $w bind movable <B1-Motion> { FG_Move %W %x %y }
    $w bind movable <ButtonRelease-1> {FG_MoveEnd   %W %x %y}
    bind $w       <2> {Remove_SelReg %W}
    bind $w       <3> {Cancel_SelReg}

        set db(mode) "Object $type Selected"
}

proc FG_MoveBegin {w x y} {
    global stroke
    set stroke(x) $x
    set stroke(y) $y
}

proc FG_Move {w x y} {
    global db stroke
    regexp {(.+)\.[^.]$} $w m ww 
    $ww.lc configure -text " Coordinates =  x:$x  y:$y "
    if { ![info exists stroke(x)] } return
    set dx [expr $x - $stroke(x)]
    set dy [expr $y - $stroke(y)]
    $w move movable $dx $dy
    set stroke(x) $x
    set stroke(y) $y
}

proc FG_MoveEnd {w x y} {
#    $w dtag movable
#    FG_BindRestore $w
}

proc Remove_SelReg {w} {
    global db
    if { ![info exists db(Selw)] } return
    if { $db(Selw) == $w } {
	$w delete region
	$w delete movable
	foreach id $db(Selid) {
	    $w delete $id
	}
	UnsetSel
	focus .
	FG_BindRestore $w
	set db(mode) "Selection Removed"
	regexp {(.+)\.[^.]$} $w m ww
	FG_CreateDiagConfig $ww
    }
}

proc Cancel_SelReg {{cmd {}}} {
    global db
    if { ![info exists db(Selw)] } return
    set w $db(Selw)
    $w delete region
    $w delete Bbox
    set idd "[$w find withtag movable]"
    $w dtag movable
    foreach id "$idd" {
#puts "id: $id   tags: [$w gettags $id]"
}

    foreach id "$idd" {
	set type [lindex [$w gettags $id] 1]
	set ImageId "[$w find withtag "Image"]"
	if { $ImageId == ""} {
	    $w lower $id
	} else {
	    if { $ImageId != $id } {
		$w raise $id Image
	    }
	}
	switch -regexp $type {
	    Oval {
		$w itemconfigure $id -outline $db(linecolor,$type)
	    }
	    "blob|Vertex" {
		$w itemconfigure $id -outline $db(linecolor,$type) -fill $db(linecolor,$type)
	    }
	    Image {
		$w lower $id
	    }
	    default {
		$w itemconfigure $id -fill $db(linecolor,$type)
	    }
	}
    }
    $w lower Grid
    FG_BindRestore $w
    regexp {^\.([^.]*)} $w m ww
    focus $m
    focus .
    UnsetSel
    set db(mode) "Selection Cancelled"
    regexp {(.+)\.[^.]$} $w m ww
    if { "$cmd" != "noupdate" } { FG_CreateDiagConfig $ww }
}

proc FG_CopyToBuf {w x y Type Id} {

    global db buffer

    foreach id "[$w find withtag movable]" {
	set conf($id) "[$w itemconfigure $id]"
        set i [lsearch $conf($id) {-smooth {*} {*} * bezier}]
        if {$i >= 0} {
            set conf($id) [lreplace $conf($id) $i $i {-smooth {} {} 0 true}]
        }
#puts $conf($id)
	set tplace "[lsearch $conf($id) {-tags {*} {*} {*} {*}}]"
	set n "[lindex [lindex [lindex $conf($id) $tplace] 4] 2]"
	set types($n) "[lindex [lindex [lindex $conf($id) $tplace] 4] 1]"
	set cs "[$w coords $id]"
	set xy "$x $y"
	set i 0 ; set coords($id) ""
	foreach XY "$cs" {
	    lappend coords($id) [expr [lindex $cs $i]-[lindex $xy [expr $i%2]]]
	    incr i
	} 
    }

    foreach n "[array names types]" {
	set type $types($n)
	switch -glob $type {
	    *Fermion {
		foreach id "[$w find withtag $n]" {
		    set tplace "[lsearch $conf($id) {-tags {*} {*} {*} {*}}]"
		    set o "[lindex [lindex [lindex $conf($id) $tplace] 4] 0]"
		    set t "[lindex [lindex [lindex $conf($id) $tplace] 4] 3]"
		    set mconf  [lreplace  $conf($id) $tplace $tplace]
		    set fconf ""
		    foreach confitem "$mconf" {
			append fconf "[lindex $confitem 0] [list [lindex $confitem 4]]"
			append fconf " "
		    }
		    lappend tmp($n,$t) $o $coords($id) $fconf
		}
		lappend buffer($type) "[list $tmp($n,a) $tmp($n,b)]"
	    }
	    * {
		foreach id "[$w find withtag $n]" {
		    set tplace "[lsearch $conf($id) {-tags {*} {*} {*} {*}}]"
		    set o "[lindex [lindex [lindex $conf($id) $tplace] 4] 0]"
		    set mconf  [lreplace  $conf($id) $tplace $tplace]
		    set fconf ""
		    foreach confitem "$mconf" {
			append fconf "[lindex $confitem 0] [list [lindex $confitem 4]]"
			append fconf " "
		    }
		    lappend tmp($n) [list $o $coords($id) $fconf]
		}
		lappend buffer($type) "$tmp($n)"
	    }
	}
    }
#    foreach var "[array names buffer]" {
#	puts "buffer($var) $buffer($var)"
#    }
}



proc FG_PasteFromBuf {w x y { mirror "1 1" } } {
    global db buffer 
    FG_Cancel $w
    FG_BindSave $w
#    puts "FG_PasteFromBuf"
    foreach type "[array names buffer]" {
#	puts "buffer($type)  $buffer($type)"
	foreach obj  "$buffer($type)" {
	    set tag "$type t[incr db(tagN)]"
	    set addtltag ""
	    set np 0
	    set idd ""
	    foreach part "$obj" {
		set object  "[lindex [lindex $obj $np] 0]"
		set cs  [lindex [lindex $obj $np] 1]
		set conf  [lindex [lindex $obj $np] 2]
		incr np
		set xy "$x $y"
		set i 0 ; set coords ""
		foreach XY "$cs" {
		    lappend coords [expr [lindex $cs $i]*[lindex $mirror [expr $i%2]]+\
                         [lindex $xy [expr $i%2]]]
		    incr i
		}
		if [string match *Fermion $type] {
		    if { $np == 1 } {
			set addtltag " a"
		    } else {
			set addtltag " b"
		    }
		}
		set id [eval  {$w} create $object $coords $conf { -tags "$object $tag $addtltag"} ]
		if { $object == "text" } {
		    $w bind $id <1> "FieldEvent %W %x %y Text $id"
		    $w bind $id <Double-1> {
			SetSel %W Text "[%W find withtag current]" 
			DoubleFieldEvent  %W %x %y Text "[%W find withtag current]"
		    }
		    focus .
		}
		if { $object == "image" } {
		    $w lower $id
		}
		lappend idd $id
	    }
	    foreach id "$idd" {
		$w bind $id <1> "FieldEvent %W %x %y $type {$idd}"
		$w addtag movable withtag $id
	    }
	}
    }
    SetSel $w Area "[$w find withtag movable]"
#    foreach id "[$w find withtag movable]" {
#	puts "tags: [$w gettags $id]"
#    }
    $w bind movable <B1-Motion> { FG_Move %W %x %y }
    $w bind movable <ButtonRelease-1> {FG_MoveEnd   %W %x %y}
    bind $w <2>  {Remove_SelReg %W}
    bind $w <3>  {Cancel_SelReg}

    set db(mode) "Copied from Buffer"
}

proc MarkArea {w points} {
    global db buffer
    
    set xx [lsort [list [lindex $points 0]  [lindex $points 2] ] ]
    set yy [lsort [list [lindex $points 1]  [lindex $points 3] ] ]
    set x [lindex $xx 1]
    set y [lindex $yy 1]

    
    $w addtag area enclosed $x $y [lindex $xx 0] [lindex $yy 0]
    
    set id ""
    foreach idd "[$w find withtag area]" {
	set n "[lindex [$w gettags $idd] 2]"
	set InArea($n) "" 
	lappend id $idd
    }
    foreach n "[array names InArea]" {
	$w addtag movable withtag $n
    }
    $w dtag area    

    foreach idd "[$w find withtag movable]" {
	set type "[lindex [$w gettags $idd] 1]"
	switch -regexp $type {
	    Oval {
		$w itemconfigure $idd -outline  red
	    }
	    "blob|Vertex" {
		$w itemconfigure $idd  -fill red -outline red
	    }
	    Image {
	    }
	    default {
		$w itemconfigure $idd -fill red
	    }
	}
    }
    
    $w addtag movable withtag "[$w find withtag Bbox]"
    lappend id "[$w find withtag Bbox]"
    
    SetSel $w Bbox $id
    
    FG_BindRestore $w
    
    $w bind movable <B1-Motion> { FG_Move %W %x %y }
    $w bind movable <ButtonRelease-1> {FG_MoveEnd   %W %x %y}
    bind $w       <2> {Remove_SelReg %W}
    bind $w       <3> {Cancel_SelReg}
    
    FG_BindSave $w
    
    foreach var "[array names buffer]" {
	unset buffer($var)
    }
    FG_CopyToBuf $w $x $y Bbox $id
    set db(mode) "Area Marked"
}  

proc AreaEvent {w x y} {

    FG_MoveBegin $w $x $y

#    $w bind movable <B1-Motion> { FG_Move %W %x %y }
#    $w bind movable <ButtonRelease-1> {FG_MoveEnd   %W %x %y}
#    bind $w       <2> {Remove_SelReg %W}
#    bind $w       <3> {Cancel_SelReg}
    
}

proc RemoveBbox {w} {
    $w delete Bbox
}



proc FG_ResizeMainBox {w} {

    global db Diag
    regexp {^\.([^.]*)} $w m ww 
    set d $db($ww,diag)
    scan "[winfo height $w] [winfo width $w]" %d%d Diag($d,HScreenH) Diag($d,HScreenW)
    Grid $w Resize
}



proc SetSel {w type id} {
    global db
#puts "SetSel: $w"
    set db(Selw) $w
    set db(Seltype) $type
    set db(Selid) $id
}

proc UnsetSel {} {
#puts "UnsetSel: "
    global db
    unset db(Selw)
    unset db(Seltype)
    unset db(Selid)
}

