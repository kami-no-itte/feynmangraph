proc FG_StartRegDraw {w type} {
    global db diag
    FG_Cancel $w
    
    set db(linetype) "$type"
    set db(linecolor) "$db(linecolor,$type)"
    FG_BindSave $w
    bind $w <1>               {FG_StrokeBegin %W %x %y}
    bind $w <2>               {FG_Cancel      %W noupdate}
#	bind $w <3>               {FG_StrokeSave  %W }
#	bind $w <B1-Motion>       {FG_Stroke      %W %x %y}
        
    set db(mode) "Drawing $type"
}


proc FG_StartVertexDraw {w type } {
    global db diag
    FG_Cancel $w
    set db(linetype) "Vertex"
    set db(linecolor) "$db(linecolor,$type)"

    FG_BindSave $w
    bind $w <1>               {FG_StrokeVertex   %W %x %y}
    bind $w <2>               {FG_Cancel      %W noupdate}
    bind $w <3>               {FG_StrokeVertexSave  %W }
    
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeBegin {w x y} {
    global db stroke
    catch {$w delete region}
    set stroke(N) 0
    set stroke(0) [list $x $y]      
    bind $w <1>               {FG_StrokePoint %W %x %y}
    bind $w <Motion> {FG_StrokeRegPoint      %W %x %y}
    bind $w <3> {FG_StrokeEnd   %W %x %y}
    bind $w <B1-Motion> { FG_Stroke %W %x %y }
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeVertex {w x y} {
    global stroke db
    catch {unset stroke}
    catch {$w delete region}
    set stroke(N) 0
    set r $db(VertexR)
    set stroke(0) [list $x $y]
    set id [eval {$w create oval} [expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r]  \
	    {-tag region  -width 2 } -outline red]
    SetSel $w Vertex $id
    set db(mode) "$db(linetype) Created"
}      


proc FG_Stroke {w x y} {
    global db stroke
    
    regexp {(.+)\.[^.]$} $w m ww
    $ww.lc configure -text " Coordinates =  x:$x  y:$y "
    set last $stroke($stroke(N))
    if {[expr hypot(([lindex $last 0]-$x),([lindex $last 1]-$y))] > 3} {
	incr stroke(N)
	set stroke($stroke(N)) [list $x $y]
	eval {$w create line} $last {$x $y -tag region}
    }
}       

proc FG_StrokeReg {w x y} {
    global db stroke
    set last $stroke($stroke(N))
    if {[expr hypot(([lindex $last 0]-$x),([lindex $last 1]-$y))] > 3} {
	set stroke($stroke(N)) [list $x $y]
	eval {$w create line} $last {$x $y -tag region}
    }
}       

proc FG_StrokePoint {w x y} {
    global db stroke        
    set last $stroke($stroke(N))
    if {[expr hypot(([lindex $last 0]-$x),([lindex $last 1]-$y))] > 3} {
	incr stroke(N)
	set stroke($stroke(N)) [list $x $y]
	eval {$w create line} $last {$x $y -tag region}
    }
}       

proc FG_StrokeRegPoint {w x y} {
    global db stroke
    regexp {(.+)\.[^.]$} $w m ww 
    $ww.lc configure -text " Coordinates =  x:$x  y:$y "
    set last $stroke($stroke(N))
    $w delete temporary
    eval {$w create line} $last {$x $y -tags {region temporary} }
}       



proc FG_StartLineDraw {w type} {
    global db diag
    
    FG_Cancel $w
    
    set db(linetype) "$type"
    set db(linecolor) "$db(linecolor,$type)"
    
    FG_BindSave $w
    bind $w <1>               {FG_StrokeLineBegin %W %x %y}
    bind $w <2>               {FG_Cancel      %W noupdate}
    bind $w <3>               {FG_StrokeLineSave  %W }
    bind $w <B1-Motion>       {FG_StrokeLine      %W %x %y}
    bind $w <ButtonRelease-1> {FG_StrokeLineEnd   %W %x %y}
    
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeLineBegin {w x y} {
    global db stroke
    regexp {^\.([^.]*)} $w m ww    

    catch {unset stroke}
    catch {$w delete region}
    set stroke(N) 0
    if { $db($ww,SnapToGrid) == "On" } { scan [GridXY $w $x $y] %f%f x y }
    set stroke(0) [list $x $y]
    set db(mode) "Drawing $db(linetype)"

}      

proc FG_StrokeLine {w x y} {
    global db stroke

    regexp {(.+)\.[^.]$} $w m ww 
    regexp {^\.([^.]*)} $w m www

    $ww.lc configure -text " Coordinates =  x:$x  y:$y "
    set last $stroke(0)
    set stroke(N) 1
    if { $db($www,SnapToGrid) == "On" } { scan "[GridXY $w $x $y]" %f%f x y }
    set stroke(1) [list $x $y]
    $w delete region
    eval {$w create line} $last {$x $y -tag region}
}       

proc FG_StrokeLineEnd {w x y} {
    global db stroke 
    regexp {(.+)\.[^.]$} $w m ww
    if { $stroke(N) < 1 } return
    set points "$stroke(0) $stroke(1)"
    $w delete region
    if {[expr hypot(([lindex $stroke(1) 0]-[lindex $stroke(0) 0]), \
	    ([lindex $stroke(1) 1]-[lindex $stroke(0) 1]))] > 5} {
	set id [eval {$w create line} $points \
		{-tag region  -width 2 -fill red -arrow none }]
	SetSel $w line $id
	set db(mode) "$db(linetype) Created"
    }
}

proc FG_StrokeLineSave {w} {
    global db diag stroke
    if { [info exists stroke(N)] } {
	if { $stroke(N) < 1 } return
	catch {$w delete region}
	if {[expr hypot(([lindex $stroke(1) 0]-[lindex $stroke(0) 0]), \
		([lindex $stroke(1) 1]-[lindex $stroke(0) 1]))] > 5} {
	    set points "$stroke(0) $stroke(1)"
	    Draw_Line $w $points $db(linetype) $db(linecolor)
	    set db(mode) "Line $db(linetype) Fixed"
	    #puts "line save"
	    UnsetSel
	    FG_StopRegDraw $w
	}
    }
}

proc FG_StartOvalDraw {w type} {
    global db diag
    
    FG_Cancel $w
    
    set db(linetype) "$type"
    set db(linecolor) "$db(linecolor,$type)"

    FG_BindSave $w
    bind $w <1>               {FG_StrokeOvalBegin %W %x %y}
    bind $w <2>               {FG_Cancel      %W noupdate}
    bind $w <3>               {FG_StrokeOvalSave  %W }
    bind $w <B1-Motion>       {FG_StrokeOval      %W %x %y}
    bind $w <ButtonRelease-1> {FG_StrokeOvalEnd   %W %x %y}
    
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeOvalBegin {w x y} {
    global db stroke
    regexp {^\.([^.]*)} $w m ww
    catch {unset stroke}
    catch {$w delete region}
    set stroke(N) 0
    if { $db($ww,SnapToGrid) == "On" } { scan "[GridXY $w $x $y]" %f%f x y }
    set stroke(0) [list $x $y]
}      

proc FG_StrokeOval {w x y} {
    global db stroke        
    regexp {(.+)\.[^.]$} $w m ww
    regexp {^\.([^.]*)} $w m www
    $ww.lc configure -text " Coordinates =  x:$x  y:$y "
    if { $db($www,SnapToGrid) == "On" } { scan "[GridXY $w $x $y]" %f%f x y }
    set xc [lindex $stroke(0) 0]
    set yc [lindex $stroke(0) 1]
    set x0 [expr 2*$xc-$x]
    set y0 [expr 2*$yc-$y]
    set stroke(N) 1
    set stroke(1) [list $x $y]
    $w delete region
    if { [expr abs(abs($x-$x0)-abs($y-$y0))] < 2 } {
	set color purple
    } else {
	set color red
    }
    $w create oval [expr $xc-1] [expr $yc-1] [expr $xc+1] [expr $yc+1] -tag region -outline $color
#    $w create oval [expr $xc-3] [expr $yc-3] [expr $xc+3] [expr $yc+3] -tag region -outline $color
    eval {$w create oval} $x0 $y0 {$x $y -tag region} -outline $color
}

proc FG_StrokeOvalEnd {w x y} {
    global db stroke 
    if { $stroke(N) < 1 } return
    set points "$stroke(0) $stroke(1)"
    set xc [lindex $stroke(0) 0]
    set yc [lindex $stroke(0) 1]
    set x [lindex $stroke(1) 0]
    set y [lindex $stroke(1) 1]
    set x0 [expr 2*$xc-$x]
    set y0 [expr 2*$yc-$y]
    $w delete region
    if {[expr hypot(($xc-$x),($yc-$y))] > 5} {
	if { [expr abs(abs($x-$x0)-abs($y-$y0))] < 2 } {
	    set color purple
	} else {
	    set color red
	}
	$w create oval [expr $xc-1] [expr $yc-1] [expr $xc+1] [expr $yc+1] -tag region -outline $color
	set id [eval {$w create oval} $x0 $y0 {$x $y -tag region} -outline $color]
	SetSel $w Oval $id
	set db(mode) "$db(linetype) Created"
    }
}

proc FG_StrokeOvalSave {w} {
    global db diag stroke
    if { [info exists stroke(N)] } {
	if { $stroke(N) < 1 } return
	catch {$w delete region}
	set points "$stroke(0) $stroke(1)"
	if {[expr hypot(([lindex $stroke(1) 0]-[lindex $stroke(0) 0]), \
	    	([lindex $stroke(1) 1]-[lindex $stroke(0) 1]))] > 5} {
	    Draw_Line $w $points $db(linetype) $db(linecolor)
	    set db(mode) "Line $db(linetype) Fixed"
	    UnsetSel
	    set db(mode) "$db(linetype) Fixed"
	    FG_StopRegDraw $w
	} else {
	    set db(mode) "Cancelled"
	}
    }
}

	
proc FG_StartCrossDraw {w type} {
    global db diag

    FG_Cancel $w
    set db(linetype) "Cross"
    set db(linecolor) "$db(linecolor,$type)"
    
    FG_BindSave $w
    bind $w <1>               {FG_StrokeCross   %W %x %y}
    bind $w <2>               {FG_Cancel      %W noupdate}
    bind $w <3>               {FG_StrokeCrossSave  %W }
    
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeCross {w x y} {
    global stroke db
    catch {unset stroke}
    catch {$w delete region}
    set stroke(N) 0
    set stroke(0) [list $x $y]
    set Size $db(CrossSize)
    set xb [expr $x - $Size/2]
    set yb [expr $y - $Size/2]
    set xe [expr $x + $Size/2]
    set ye [expr $y + $Size/2]
    set id1 [eval {$w create line $xb $yb $xe $ye -fill red -width 3 -tags region}]
    set xb [expr $x - $Size/2]
    set yb [expr $y + $Size/2]
    set xe [expr $x + $Size/2]
    set ye [expr $y - $Size/2]
    set id2 [eval {$w create line $xb $yb $xe $ye -fill red -width 3 -tags region}]
    SetSel $w Cross "$id1 $id2"
    set db(mode) "$db(linetype) Created"
}      

proc FG_StrokeCrossSave {w} {
    global db diag stroke
    if { ![info exists stroke(0)] } return
    catch {$w delete region}
    set points "$stroke(0)"
    Draw_Line $w $points $db(linetype) $db(linecolor)
    set db(mode) "Line $db(linetype) Fixed"
    UnsetSel
    FG_StopRegDraw $w
}


proc Draw_Line {w points type color {BindEvent FieldEvent} } {
    global db diag
    
    incr db(tagN)
    set tag "$type t$db(tagN)"


    switch -exact $type {
	"Line"  {
	    set id [eval {$w create line} $points \
		    {-tags "line $tag" -width 2 -fill $color -arrow none}]
	}
	"line1"  {
	    set id [eval {$w create line} $points \
		    {-tags "line $tag" -width 1 -fill $color -arrow none}]
	}
	"Arrow" {
	    set id [eval {$w create line} $points \
		    {-tags "line $tag"  -width 2 -fill $color -arrow last \
		    -arrowshape {8 12 4} }]
	}
	"arrow1" {
	    set id [eval {$w create line} $points \
		    {-tags "line $tag"  -width 1 -fill $color -arrow last }]
	}
	"Scalar" {
	    set id [eval {$w create line} $points \
		    {-tags "line $tag" -width 2 -fill $color -arrow none }]
	}
	"Fermion" {
	    set x0 [lindex $points 0]
	    set y0 [lindex $points 1]
	    set x1 [lindex $points 2]
	    set y1 [lindex $points 3]
	    set dx [expr $x1-$x0]
	    set dy [expr $y1-$y0]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set xm [expr ($x0+$x1)/2]
	    set ym [expr ($y0+$y1)/2]
	    set xa [expr $xm + $dx/$l * 6]
	    set ya [expr $ym + $dy/$l * 6]
	    set id1 [eval {$w create line} "$x0 $y0 $xa $ya" \
		    {-tags "line $tag a"\
		    -width 2 -fill $color -arrow last \
		    -arrowshape {8 12 4} }]
	    set id2 [eval {$w create line} "$xm $ym $x1 $y1" \
		    {-tags "line $tag b" \
		    -width 2 -fill $color -arrow none }]
	    set id "[list $id1 $id2]"
	}
	"HFermion" {
	    set x0 [lindex $points 0]
	    set y0 [lindex $points 1]
	    set x1 [lindex $points 2]
	    set y1 [lindex $points 3]
	    set dx [expr $x1-$x0]
	    set dy [expr $y1-$y0]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set xm [expr ($x0+$x1)/2]
	    set ym [expr ($y0+$y1)/2]
	    set xa [expr $xm + $dx/$l * 9]
	    set ya [expr $ym + $dy/$l * 9]
	    set id1 [eval {$w create line} "$x0 $y0 $xa $ya" \
		    {-tags "line $tag a"\
		    -width 4 -fill $color -arrow last \
		    -arrowshape {12 18 6} }]
	    set id2 [eval {$w create line} "$xm $ym  $x1 $y1" \
		    {-tags "line $tag b" \
		    -width 4 -fill $color -arrow none }]
	    set id "[list $id1 $id2]"
	}
	"Curve" {
	    set id [ eval {$w create line} $points  \
		    {-tags "line $tag" \
		    -smooth true  -joinstyle round -width 2 -splinesteps 5 \
		    -fill $color  } ]
	}
	"Meson" {
	    set dashl $db(DashL)
	    set x  [lindex $points 0]
	    set y  [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set dx [expr $x2-$x]
	    set dy [expr $y2-$y]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set n  [expr round( ($l/$dashl)-1/2)]
	    if { $n < 1 } {
		set n 5
	    }
	    set dl [expr $l/($n+0.5)]
	    set dxl [expr $dl*$dx/$l]
	    set dyl [expr $dl*$dy/$l]
	    for {set i 0} {$i<=$n} {incr i} {
		set idd [eval {$w create line} \
			[expr $x+$dxl*$i] [expr $y+$dyl*$i] \
			[expr $x+$dxl*($i+0.5)] [expr $y+$dyl*($i+0.5)] \
			{-tags "line $tag" -width 2 -fill $color -arrow none}]
		lappend id $idd
	    }
	}
	"Photon" {
	    set dpl $db(PhotonL)
	    set h   $db(PhotonH)
	    set x  [lindex $points 0]
	    set y  [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set dx [expr $x2-$x]
	    set dy [expr $y2-$y]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set Nx [expr -$dy/$l]
	    set Ny [expr $dx/$l]
	    set n  [expr 2*round($l/$dpl/2)]
	    if { $n < 4 } {
		set n 4
	    }
	    set dl [expr $l/$n]
	    set dxl [expr $dl*$dx/$l]
	    set dyl [expr $dl*$dy/$l]
	    set dots {}
	    for {set i 0} {$i<=$n} {incr i} {
		set k [expr $i%2* pow(-1,int($i/2))]
		set dot [list [expr $x+$dxl*$i + $Nx*$h*$k] \
			[expr $y+$dyl*$i + $Ny*$h*$k] ]
		append dots $dot " "
	    }
	    set id [ eval {$w create line} $dots  \
		    {-tags "line $tag" \
		    -smooth true  -joinstyle round -width 2 -splinesteps 2 \
		    -fill $color } ]
	}
	"Gluon" {
	    set dpl $db(GluonL)
	    set h   $db(GluonH)
	    set s   $db(GluonS)
	    set ph  $db(GluonP)   
	    set x  [lindex $points 0]
	    set y  [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set dx [expr $x2-$x]
	    set dy [expr $y2-$y]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set Nx [expr -$dy/$l]
	    set Ny [expr $dx/$l]
	    set n  [expr 6*round(($l/$dpl)/6.)-2]
	    if { $n < 10 } {
		set n 10
	    }
	    set dl [expr $l/($n+5)]
	    set dxl [expr $dl*$dx/$l]
	    set dyl [expr $dl*$dy/$l]
	    set dots {}
	    set constc [expr cos(3.14159266*($ph)/3.)]
	    set consts [expr sin(3.14159266*($ph)/3.)]
	    for {set i 0} {$i<6} {incr i} {
		set cs($i) [expr $s*(cos(3.14159266*($i+$ph)/3.)-$constc)]
		set ch($i) [expr $h*(sin(3.14159266*($i+$ph)/3.)-$consts)]
	    }
 	    for {set i 0} {$i<=$n} {incr i} { 
		set k [expr $i%6]
		set dot [list [expr $x+$dxl*($i+$cs($k)) + $Nx*$ch($k)] \
			[expr $y+$dyl*($i+$cs($k)) + $Ny*$ch($k)] ]
		append dots $dot " "
	    }
	    set id [ eval {$w create line} $dots  \
		    {-tags "line $tag" \
		    -smooth true -joinstyle round -width 2 -splinesteps 5 \
		    -fill $color } ]
	    
	}
	"Wboson" {
	    set dpl $db(WbosonL)
	    set h   $db(WbosonH)
	    set x  [lindex $points 0]
	    set y  [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set dx [expr $x2-$x]
	    set dy [expr $y2-$y]
	    set l  [expr sqrt(double($dx*$dx+$dy*$dy))]
	    set Nx [expr -$dy/$l]
	    set Ny [expr $dx/$l]
	    set n  [expr 2*round($l/$dpl/2)]
	    if { $n < 4 } {
		set n 4
	    }
	    set dl [expr $l/$n]
	    set dxl [expr $dl*$dx/$l]
	    set dyl [expr $dl*$dy/$l]
	    set dots {}
	    for {set i 0} {$i<=$n} {incr i} {
		set k [expr $i%2* pow(-1,int($i/2))]
		set dot [list [expr $x+$dxl*$i + $Nx*$h*$k] \
			[expr $y+$dyl*$i + $Ny*$h*$k] ]
		append dots $dot " "
	    }
	    set id [ eval {$w create line} $dots  \
		    {-tags "line $tag" -width 2 \
		    -fill $color } ]
	}
	"Cross" {
	    set Size $db(CrossSize)
	    scan "$points" %i%i x y
	    set xb [expr $x - $Size/2]
	    set yb [expr $y - $Size/2]
	    set xe [expr $x + $Size/2]
	    set ye [expr $y + $Size/2]
	    set id1 [eval {$w create line $xb $yb $xe $ye -fill $color \
		    -width 3 -tags "line $tag"}]
	    set xb [expr $x - $Size/2]
	    set yb [expr $y + $Size/2]
	    set xe [expr $x + $Size/2]
	    set ye [expr $y - $Size/2]
	    set id2 [eval {$w create line $xb $yb $xe $ye -fill $color \
		    -width 3 -tags "line $tag"}]
	    set id "[list $id1 $id2]"
	}
	"Oval" {
	    set xc [lindex $points 0]
	    set yc [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set x1 [expr 2*$xc-$x2]
	    set y1 [expr 2*$yc-$y2]
	    set id [eval {$w create oval} $x1 $y1 $x2 $y2 \
		    { -tags "oval $tag" -width 2 -outline $color }]
	}
	"blob" {
	    set xc [lindex $points 0]
	    set yc [lindex $points 1]
	    set x2 [lindex $points 2]
	    set y2 [lindex $points 3]
	    set x1 [expr 2*$xc-$x2]
	    set y1 [expr 2*$yc-$y2]
	    set id [eval {$w create oval} $x1 $y1 $x2 $y2 \
		    { -tags "oval $tag" -width 2 -outline $color } \
		    -fill $color -stipple "@$db(InstallDir)$db(stipple,blob)" ]
	}
	"Vertex" {
	    scan "$points" %i%i x y
	    set r $db(VertexR)
	    set id [eval {$w create oval} [expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r]  \
		    {-tags "oval $tag"  -width 1 -fill $color -outline $color }]
	}
    }
    #    puts "DL: $type, $id"
    set  mouseEvent "<1>"
    if { "$BindEvent" == "ChooseColor" } { set mouseEvent "<ButtonRelease-1>" }
    foreach idd "$id" {
	$w bind $idd $mouseEvent "$BindEvent %W %x %y $type {$id}"	
    }
    set db(mode) "$db(linetype) Created"
}


proc FG_StrokeEnd {w x y} {
    global db stroke 
    
    set points {}
    for {set i 0} {$i<=$stroke(N)} {incr i} {
	append points $stroke($i) " "
    }
    $w delete region
    
    if {$stroke(N) >= 5} {
	set id [ eval {$w create line} $points  \
		{-tag region -smooth true  -width 2 -splinesteps 5 -fill red  }]
	SetSel $w line $id
	FG_BindRestore $w
	FG_BindSave    $w
	bind $w <1>               {FG_StrokeBegin %W %x %y}
	bind $w <2>               {FG_Cancel      %W noupdate}
	bind $w <3>               {FG_StrokeSave  %W }
	set db(mode) "$db(linetype) Created"
    }
}

proc FG_StrokeSave {w} {
    global db diag stroke
    if { [info exists stroke(N)] } {
	if { $stroke(N) < 3 } return
	catch {$w delete region}
	set points {}
	for {set i 0} {$i<=$stroke(N)} {incr i} {
	    append points $stroke($i) " "
	}
	Draw_Line $w $points $db(linetype) $db(linecolor)
	UnsetSel
	FG_StopRegDraw $w
	set db(mode) "$db(linetype) Fixed"
    }
}

proc FG_StrokeVertexSave {w} {
    global db diag stroke
    if { [info exists stroke(0)] } {
	catch {$w delete region}
	set points $stroke(0)
	Draw_Line $w $points $db(linetype) $db(linecolor)
	UnsetSel
	set db(mode) "Vertex Fixed"
    }
    FG_StopRegDraw $w
}


proc FG_StartBboxDraw {w x y} {
    global db diag stroke
    
    FG_Cancel $w
    #puts "start"
    set db(linetype) Area
    set db(linecolor) $db(linecolor,Bbox)
    FG_BindSave $w
    FG_StrokeBboxBegin $w $x $y
    bind $w <2>               {FG_Cancel      %W noupdate}
    bind $w <B3-Motion>       {FG_StrokeBbox      %W %x %y}
    bind $w <ButtonRelease-3> {FG_StrokeBboxEnd   %W %x %y}
    
    set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeBboxBegin {w x y} {
        global db stroke
        catch {unset stroke}
        catch {$w delete region}
        set stroke(N) 0
        set stroke(0) [list $x $y]
}      

proc FG_StrokeBbox {w x y} {
    global db stroke        
    set stroke(N) 1
    set stroke(1) [list $x $y]
    $w delete region
    eval {$w create rectangle} $stroke(0) {$x $y -tags "region rectangle"} -outline red
    bind $w <3>               {FG_StrokeBboxSave  %W }
}

proc FG_StrokeBboxEnd {w x y} {
    global db stroke 
    if { $stroke(N) < 1 } return
    bind $w <Motion-3> {}
    set points "$stroke(0) $stroke(1)"
    $w delete region
    set x1 [lindex $stroke(0) 0]
    set y1 [lindex $stroke(0) 1]
    set x2 [lindex $stroke(1) 0]
    set y2 [lindex $stroke(1) 1]
    if {[expr hypot(($x2-$x1),($y2-$y1))] > 5} {
	set id [eval {$w create rectangle} $points { -tags "region rectangle"} -outline red]
	SetSel $w Bbox $id
	set db(mode) "Area Created"
	bind $w <ButtonRelease-3> {}
    }
}

proc FG_StrokeBboxSave {w} {
    global db diag stroke
    if { [info exists stroke(N)] } {
	if { $stroke(N) < 1 } return
	catch {$w delete region}
	set points "$stroke(0) $stroke(1)"
	set x1 [lindex $stroke(0) 0]
	set y1 [lindex $stroke(0) 1]
	set x2 [lindex $stroke(1) 0]
	set y2 [lindex $stroke(1) 1]
	if {[expr hypot(($x2-$x1),($y2-$y1))] > 5} {
	    set id [eval {$w create rectangle} $points {-tags "rectangle Bbox region"} \
		    -outline $db(linecolor,Bbox) ]
	    SetSel $w Bbox $id
	    set db(mode) "Area Fixed"
	    $w bind $id <1> {FieldEvent %W %x %y Bbox {$id}}
	    $w bind $id <2> {Remove_SelReg %W}
	    MarkArea $w $points
	} else {
	    set db(mode) "Cancelled"
	}
    }
    FG_StopRegDraw $w noupdate
}

