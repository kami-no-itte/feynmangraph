
proc Draw_ZoomBox {w points tag} {

	global db diag
	scan $points %i%i%i%i x1 y1 x y
	set ratio "[expr double($diag(HScreenH))/double($diag(HScreenW))]"
	if { [expr abs($x-$x1) * $ratio] > [expr abs($y-$y1)] } {
		set x2 $x
		set y2 [expr $y1 + ($x-$x1)*$ratio]
	} else {
		set y2 $y
		set x2 [expr $x1 + ($y-$y1)/$ratio]
	}
	if { $tag != "Zoom" } {
		set dcolor red
		set color  darkred
	} else {
		set dcolor yellow
		set color  orange
	}
	set dx [expr abs($x2-$x1)]
	set s  [expr round(double($diag(HScreenW))/double($dx))]
	set db(zoomscale)  [expr double($dx)/double($diag(HScreenW))]
	if { [expr abs($diag(HScreenW)-$dx*$s)] < 4 && $s < 6 } {
	    set c $dcolor
	} else {
	    set c $color
	}
	$w create line $x1 $y1 $x1 $y2 \
		-tag $tag -width 2 -fill $c -arrow none
	$w create line $x1 $y1 $x2 $y1 \
		-tag $tag -width 2 -fill $c -arrow none
	$w create line $x2 $y1 $x2 $y2 \
		-tag $tag -width 2 -fill $c -arrow none
	$w create line $x1 $y2 $x2 $y2 \
		-tag $tag -width 2 -fill $c -arrow none
}


proc draw_reg {w} {
    global db diag
    FG_Cancel $w
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)

    if { !$db(zoom) } {
	foreach type "Fermion Meson Curve Photon Gluon Cross Scalar" {
	    FG_ClearReg $w $type
	    if { [info exists diag($diagN,$type,coords)] } {
			foreach coords "$diag($diagN,$type,coords)" {
				set id [eval $w create poly $coords \
			    -tag $type -smooth true  -splinesteps 5\
			    -fill red -outline $db(linecolor,$type) -stipple @transparent.m.pm]
		    lappend db(id,$type) $id
		    $w bind $id <1> "FieldEvent $w %x %y $type $id"
		}
	    }
	}
	foreach type "Wboson"  {
	    FG_ClearReg $w $type
	    if { [info exists diag($diagN,$type,coords)] } {
			foreach coords "$diag($diagN,$type,coords)" {
				set id [eval $w create poly $coords \
			    -tag $type -smooth false \
			    -fill red -outline $db(linecolor,$type) -stipple @transparent.m.pm]
		    lappend db(id,$type) $id
		    $w bind $id <1> "FieldEvent $w %x %y $type $id"
		}
	    }
	}
	if { [info exists diag($diagN,Vertex,coords)] } {
	    if { $diag($diagN,Vertex,coords) != "" } {
		set id [eval $w create oval [lindex $diag($diagN,Vertex,coords) 0] \
			-tag Vertex  -width 1 -fill red -outline red]
		lappend db(id,Vertex) $id
	    }
	}
	set db(mode) "Everything Shown"    
    }    
}


proc del_reg {w} {
	global db
	FG_Cancel $w

	foreach type "Fermion Meson HFermion Curve Photon Scalar Gluon Cross Wboson" {
		if { [info exists db(id,$type)] } {
			foreach id "$db(id,$type)" {
				$w delete $id
			}
	    }
	    set db(id,$type) ""
	}
	$w delete Vertex 
	set db(id,Vertex) ""
	set db(mode) "Everything Removed."
}

proc draw_all {w} {
    global db diag
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)
    FG_Cancel $w

    foreach type "Fermion Meson Gluon Curve Photon Cross Scalar" {
	FG_ClearReg $w $type
	if { [info exists diag($diagN,$type,coords)] } {
	    foreach coords "$diag($diagN,$type,coords)" {
		set id [eval $w create poly $coords \
			-tag $type -smooth true  -splinesteps 5\
			-fill red -outline $db(linecolor,$type) -stipple @transparent.m.pm]
		lappend  db(id,$type) $id
		$w bind $id <1> "FieldEvent $w %x %y $type $id"
	    }
	}
    }
    if { [info exists diag($diagN,Line,coords)] } {
	FG_ClearReg $w Line
	foreach coords "$diag($diagN,Line,coords)" {
	    set id [eval {$w create line} $coords \
		    {-tag Line  -width 2 -fill white -arrow none }]
	    lappend  db(id,Line) $id
	    $w bind $id <1> "FieldEvent $w %x %y Line $id"
	}
    }
    if { [info exists diag($diagN,Wboson,coords)] } {
	FG_ClearReg $w Wboson
	foreach coords "$diag($diagN,Wboson,coords)" {
	    set id [eval {$w create line} $coords \
		    {-tag Wboson  -width 2 -fill white -arrow none }]
	    lappend  db(id,Wboson) $id
	    $w bind $id <1> "FieldEvent $w %x %y Wboson $id"
	}
    }
    if { [info exists diag($diagN,Arrow,coords)] } {
	FG_ClearReg $w Arrow
	foreach coords "$diag($diagN,Arrow,coords)" {
	    set id [eval {$w create line} $coords \
		    {-tag Arrow  -width 2 -fill white -arrow last }]
	    lappend  db(id,Arrow) $id
	    $w bind $id <1> "FieldEvent $w %x %y Arrow $id"
	}
    }
    if { [info exists diag($diagN,Vertex,coords)] } {
	if { $diag($diagN,Vertex,coords) != "" } {
	    set id [eval $w create oval [lindex $diag($diagN,Vertex,coords) 0] \
		    -tag Vertex  -width 1 -fill red -outline black]
	    lappend  db(id,Vertex) $id
	}
    }
    set db(mode) "Full Configuration Shown (Ready to Save)"    
}


proc del_all {w} {
	global db
	FG_Cancel $w

	foreach type "Meson Gluon Curve Scalar Photon Line Arrow Cross Wboson" {
	    $w delete $type
	    set db(id,$type) ""
	}
	$w delete Vertex
	set db(id,Vertex) ""
	set db(mode) "Full Configuration Removed."
}


