proc FG_RemoveAll {w} {
       catch {eval $w.c delete [$w.c find all]} 
}

proc Create_Zoom {w} {
    global db diag  
    FG_Cancel $w.c
    set coords ""
    foreach id "[$w.c find withtag Zoom]" {
	lappend coords "[$w.c coords $id]"
    }
    if { $coords == ""} return
#   puts "$coords"
    foreach line "$coords" {
	lappend xx "[lindex $line 0]" "[lindex $line 2]" 
	lappend yy "[lindex $line 1]" "[lindex $line 3]"
    }
    set xy "[expr int([lindex [lsort -real $xx] 0])] \
	    [expr int([lindex [lsort -real $yy] 0])] \
	    [expr int([lindex [lsort -real $xx] 7])] \
	    [expr int([lindex [lsort -real $yy] 7])]"
    set dx  [expr [lindex $xy 2]-[lindex $xy 0]]
    set dy  [expr [lindex $xy 3]-[lindex $xy 1]]
    set db(zoomscale) "[expr double($dx)/double($diag(HScreenW))]"
    set i_scale [expr int(1.0/$db(zoomscale)+0.01)]
    
    if { $i_scale < 2 } {
	set i_scale 2
    }
    
    set id  [image create photo z \
			-width  [expr $dx*$i_scale ] \
			-height [expr $dy*$i_scale ]]
    set db(zoomid) $id
    eval {$id copy pict -from} $xy -to 0 0 -zoom $i_scale
    $w.c create image 0 0 -image $id -tags z -anchor nw
    set db(id,Image) $id
    set db(zoom) 2
    set db(mode) "Zoom Created"
}


proc Cancel_Zoom {w} {
    global db
    FG_Cancel $w
    if { $db(zoom) != 2 } return
#   FG_RemoveReg $w.c Zoom
    $w.c delete z
    set db(zoom) 0
    set db(mode) "Zoom Cancelled"
}
