
proc FG_StartArcDraw {w type} {
        global db diag

	FG_Cancel $w

	set db(linetype) "$type"
	set db(linecolor) "$db(linecolor,$type)"

	FG_BindSave $w
	bind $w <1>               {FG_StrokeArcBegin %W %x %y}
	bind $w <2>               {FG_Cancel      %W noupdate}
	bind $w <3>               {FG_StrokeArcSave  %W }
	bind $w <B1-Motion>       {FG_StrokeArc      %W %x %y}
	bind $w <ButtonRelease-1> {FG_StrokeArcEnd   %W %x %y}
        
	set db(mode) "Drawing $db(linetype)"
}

proc FG_StrokeArcBegin {w x y} {
    global db stroke
    regexp {^\.([^.]*)} $w m ww    
    
    catch {unset stroke}
    catch {$w delete region}
    set stroke(N) 0
    if { $db($ww,SnapToGrid) == "On" } { scan [GridXY $w $x $y] %f%f x y }
    set stroke(0) [list $x $y]
}      

proc FG_StrokeArc {w x y} {
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

proc FG_StrokeArcEnd {w x y} {
    global db stroke 
    if { $stroke(N) < 1 } return
    set points "$stroke(0) $stroke(1)"
    $w delete region
    if {[expr hypot(([lindex $stroke(1) 0]-[lindex $stroke(0) 0]), \
	    ([lindex $stroke(1) 1]-[lindex $stroke(0) 1]))] > 5} {
	set id [eval {$w create line} $points \
		{-tag region  -width 2 -fill red -arrow none }]
	SetSel $w line $id
#	set db(mode) "$db(linetype) Created"
    }
}

proc FG_StrokeArcSave {w} {
    global db diag stroke
    if { [info exists stroke(N)] } {
	if { $stroke(N) < 1 } return
	catch {$w delete region}
	if {[expr hypot(([lindex $stroke(1) 0]-[lindex $stroke(0) 0]), \
		([lindex $stroke(1) 1]-[lindex $stroke(0) 1]))] > 5} {
	    set points "$stroke(0) $stroke(1)"
	    scan $points %f%f%f%f x1 y1 x2 y2
	    set xc [expr ($x1+$x2)/2.]
	    set yc [expr ($y1+$y2)/2.]
	    set dx [expr ($x2-$x1)]
	    set dy [expr ($y2-$y1)]
	    set l  [expr hypot($dx,$dy)]
	    set Nx [expr $dy/$l]
	    set Ny [expr -$dx/$l]
	    set idl1  [eval {$w create line} $points \
		     -width 1  -fill red {-tags "region"} ]
	    set idl2  [eval {$w create line} [expr $xc+$Nx*$l/2.]  [expr $yc+$Ny*$l/2.] \
		     [expr $xc-$Nx*$l/2.]  [expr $yc-$Ny*$l/2.] \
		     -width 1  -fill red {-tags "region"} ]
	    set idc1 [eval {$w create oval} [expr $x1+2]  [expr $y1+2] \
		     [expr $x1-2]  [expr $y1-2] \
		     -width 1  -outline red {-tags "region"} ]
	    set idc2 [eval {$w create oval} [expr $x2+2]  [expr $y2+2] \
		     [expr $x2-2]  [expr $y2-2] \
		     -width 1 -outline red {-tags "region"} ]
	    set idc3 [eval {$w create oval} [expr $xc+1]  [expr $yc+1] \
		     [expr $xc-1]  [expr $yc-1] \
		     -width 1  -outline red {-tags "aux region"} ]
	    set idc4 [eval {$w create oval} [expr $xc+3]  [expr $yc+3] \
		     [expr $xc-3]  [expr $yc-3] \
		     -width 1  -outline red {-tags "aux region"} ]
	    set stroke(arc,ends) $points
	    set stroke(arc,middle) "$xc $yc"
	    set stroke(arc,l) $l
	    set stroke(arc,normal) "$Nx $Ny"
	    FG_BindRestore $w
	    FG_BindSave $w
	    bind $w <2>               {FG_Cancel      %W noupdate}
	    bind $w <3>               {FG_ArcSave  %W }
	    $w bind aux <1>           {FG_ArcHeigtBegin %W %x %y}
	    $w bind aux <ButtonRelease-1> {FG_ArcHeightEnd   %W %x %y}
	}
    }
}

proc FG_ArcHeigtBegin {w x y} {
    global stroke
    bind $w <B1-Motion>       {FG_ArcHeight      %W %x %y}
    set stroke(x) $x
    set stroke(y) $y
#puts "BeginArcH"
}

proc FG_ArcHeight {w x y} {
    global db stroke
    if { ![info exists stroke(x)] } return
    set dx [expr $x - $stroke(x)]
    set dy [expr $y - $stroke(y)]
    set l $stroke(arc,l)
    scan $stroke(arc,middle) %f%f xm ym
    scan $stroke(arc,normal) %f%f Nx Ny
    set oldh  [expr ($stroke(x)-$xm)*$Nx+($stroke(y)-$ym)*$Ny]
    set h [expr ($x-$xm)*$Nx+($y-$ym)*$Ny]
    set dh [expr $h-$oldh]
    $w move aux [expr $dh*$Nx] [expr $dh*$Ny]
    set stroke(x) $x
    set stroke(y) $y
    if { [expr abs($h*24)] < $l } {
	if { [info exists stroke(arc,R)] } {
	    unset stroke(arc,R)
	}
	$w delete ring
	return
    }
    set h1 [expr $l*$l/(4*$h)]
    set R  [expr ($h+$h1)/2.]
    set xc [expr $xm-($R-$h)*$Nx]
    set yc [expr $ym-($R-$h)*$Ny]
    set stroke(arc,R) [expr abs($R)]
    set stroke(arc,center) "$xc $yc"
    $w delete ring
    if { [expr hypot( ($xm-$xc),($ym-$yc) )] <1 } {
	set color purple
    } else {
	set color red
    }
    set R $stroke(arc,R)
    set idr [eval {$w create oval} [expr $xc-$R] [expr $yc-$R] [expr $xc+$R] [expr $yc+$R] \
	    { -tags "ring region" -width 1 -outline $color }]
}

proc FG_ArcHeightEnd {w x y} {
#    $w dtag movable
#    FG_BindRestore $w
}

proc FG_ArcSave {w} {
    global db stroke
    if { ![info exists stroke(arc,R)] } return
    catch {$w delete region}
    set points $stroke(arc,ends)
    scan $stroke(arc,center) %f%f xc yx
    set R $stroke(arc,R)
    set aux "$stroke(x) $stroke(y)"
    Draw_Arc $w $points $xc $yx $R $aux $db(linetype) $db(linecolor)
    set db(mode) "Arc $db(linetype) Fixed"
    #puts "line save"
    UnsetSel 
    FG_StopRegDraw $w
}

proc Draw_Arc {w endpoints xc yc R aux type color} {
    global db diag stroke

    incr db(tagN)
    set tag "$type t$db(tagN)"

    scan $endpoints %f%f%f%f  x1 y1 x2 y2

    scan "[expr $x1-$xc] [expr $y1-$yc] [expr $x2-$xc] [expr $y2-$yc]" \
	    %f%f%f%f rx1 ry1 rx2 ry2
    scan $aux %f%f xa ya
#    puts "endpoints $endpoints"
#    puts "center $xc $yc"
#    puts "r1,r2 $rx1 $ry1 $rx2 $ry2"
    set phi1 [expr atan2($ry1,$rx1)]
    set phi2 [expr atan2($ry2,$rx2)]
    set auxphi [expr atan2(($ya-$yc),($xa-$xc))]

    if { ($auxphi > $phi1 && $auxphi < $phi2) || \
	    ($auxphi > $phi2 && $auxphi < $phi1) } {
	set A1 $phi1
	set A2 $phi2
    } else {
	if { $phi2 > $phi1 } {
	    if { $auxphi > $phi2 } {
		set A1 [expr $phi1 + 2*3.14159266]
		set A2 $phi2
	    } else {
		set A1 $phi1
		set A2 [expr $phi2 - 2*3.14159266]
	    }
	} else {
	    if { $auxphi > $phi1 } {
		set A1 [expr $phi1 - 2*3.14159266]
		set A2 $phi2
	    } else {
		set A1 $phi1
		set A2 [expr $phi2 + 2*3.14159266]
	    }
	}
    }

    set dA [expr $A2-$A1]
    
    switch -exact $type {
	"Line"  {
	    set n [expr round(abs(6*$dA/3.14159266))]
	    if { $n < 12 } {set n 12}
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag" -width 2 -fill $color -arrow none} ]
	}
	"line1"  {
	    set n [expr round(abs(6*$dA/3.14159266))]
	    if { $n < 12 } {set n 12}
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag" -width 1 -fill $color -arrow none} ]
	}
	"Arrow" {
	    set n [expr round(abs(6*$dA/3.14159266))]
	    if { $n < 12 } {set n 12}
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag" -width 2 -fill $color -arrow last \
		    -arrowshape {8 12 4} }]
	}
	"arrow1" {
	    set n [expr round(abs(6*$dA/3.14159266))]
	    if { $n < 12 } {set n 12}
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag" -width 1 -fill $color -arrow last \
		    -arrowshape {8 12 4} }]
	}
	"Scalar" {
	    set n [expr round(abs(6*$dA/3.14159266))]
	    if { $n < 12 } {set n 12}
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag" -width 2 -fill $color -arrow none }]
	}
	"Fermion" {
	    scan $aux %f%f xm ym
	    set phim [expr ($A1+$A2)/2.]
	    set phia [expr $phim+$dA/abs($dA)*6./$R]
	    set dAa  [expr $phia-$A1]
	    set n [expr round(abs(6*$dAa/3.14159266))]
	    if { $n < 6 } {set n 6}
	    set dAi [expr $dAa/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id1 [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		    {-tags "line $tag a" -width 2 -fill $color  -arrow last \
		    -arrowshape {8 12 4} }]
	    set points ""
	    set A1 $phim
	    set dAb [expr $A2-$phim]
	    set n [expr round(abs(6*$dAb/3.14159266))]
	    if { $n < 6 } {set n 6}
	    set dAi [expr $dAb/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id2 [eval {$w create line} $points \
		    -smooth true  -joinstyle round -splinesteps 12 \
		   {-tags "line $tag b" -width 2 -fill $color  -arrow none \
		   -arrowshape {8 12 4} }]
	    set id "[list $id1 $id2]"
	}
	"HFermion" {
	    scan $aux %f%f xm ym
	    set phim [expr ($A1+$A2)/2.]
	    set phia [expr $phim+$dA/abs($dA)*8./$R]
	    set dAa  [expr $phia-$A1]
	    set n [expr round(abs(6*$dAa/3.14159266))]
	    if { $n < 6 } {set n 6}
	    set dAi [expr $dAa/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id1 [eval {$w create line} $points \
	       -smooth true  -joinstyle round -splinesteps 12 \
		   {-tags "line $tag a" -width 4 -fill $color  -arrow last \
		    -arrowshape {12 18 6} }]
	    set points ""
	    set A1 $phim
	    set dAb [expr $A2-$phim]
	    set n [expr round(abs(6*$dAb/3.14159266))]
	    if { $n < 6 } {set n 6}
	    set dAi [expr $dAb/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ $R*$CosA]
		set ryi [expr $yc+ $R*$SinA]
		lappend points $rxi $ryi
	    }
	    set id2 [eval {$w create line} $points \
	       -smooth true  -joinstyle round -splinesteps 12 \
		   {-tags "line $tag b" -width 4 -fill $color  -arrow none \
		    -arrowshape {12 18 6} }]
	    set id "[list $id1 $id2]"
	}
	"Meson" {
	    set dashl $db(DashL)
	    set l  [expr abs($R*$dA)]
	    set n  [expr round( ($l/$dashl)-0.5)]
	    if { $n < 5 } {
		set n 5
	    }
	    set dAi [expr $dA/($n+0.5)]
	    set nk 3
	    set dAk [expr $dAi/($nk*2)]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set points ""
		for {set k 0} {$k<=$nk} {incr k} {
		    set Ak [expr $Ai+$k*$dAk]
		    set SinA [expr sin($Ak)]
		    set CosA [expr cos($Ak)]
		    set rxi [expr $xc+ $R*$CosA]
		    set ryi [expr $yc+ $R*$SinA]
		    lappend points $rxi $ryi
		}
		set idd [eval {$w create line} $points \
			{-tags "line $tag" -width 2 -fill $color -arrow none}]
		lappend id $idd
	    }
	}
	"Photon" {
	    set dpl $db(ArcPhotonL)
	    set h   $db(ArcPhotonH)
	    set l  [expr abs($dA*$R)]
	    set n  [expr 4*round($l/$dpl/4.)+2]
	    if { $n < 5 } {
		set n 5
	    }
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set k [expr $i%2* pow(-1,int($i/2))]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ ($R+$h*$k)*$CosA]
		set ryi [expr $yc+ ($R+$h*$k)*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [ eval {$w create line} $points  \
		    {-tags "line $tag" \
		    -smooth true  -joinstyle round -width 2 -splinesteps 2 \
		    -fill $db(linecolor,$db(linetype))  } ]
	}
	"Gluon" {
	    set dpl $db(ArcGluonL)
	    set h   $db(ArcGluonH)
	    set s   $db(ArcGluonS)
	    set ph  $db(ArcGluonP)   
	    set l  [expr abs($dA*$R)]
	    set n  [expr 6*round(($l/$dpl)/6.)-4]
	    if { $n < 10 } {
		set n 10
	    }
	    set dAi [expr $dA/($n+5.)]
	    for {set i 0} {$i<6} {incr i} {
		set constc [expr cos(3.14159266*($ph)/3.)]
		set consts [expr sin(3.14159266*($ph)/3.)]
		set cs($i) [expr $s*(cos(3.14159266*($i+$ph)/3.)-$constc)]
		set ch($i) [expr $h*(sin(3.14159266*($i+$ph)/3.)-$consts)]
#puts "cs,ch($i)  $cs($i)   $ch($i)"
	    }
 	    for {set i 0} {$i<=$n} {incr i} { 
		set k [expr $i%6]
 		set Ai  [expr $A1+$dAi*($i+$cs($k))]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ ($R-$ch($k))*$CosA]
		set ryi [expr $yc+ ($R-$ch($k))*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [ eval {$w create line} $points  \
		    {-tags "line $tag" \
		    -smooth true -joinstyle round -width 2 -splinesteps 5 \
		    -fill $db(linecolor,$db(linetype))  } ]

	}
	"Wboson" {
	    set dpl $db(ArcWbosonL)
	    set h   $db(ArcWbosonH)
	    set l  [expr abs($dA*$R)]
	    set n  [expr 4*round($l/$dpl/4.)+2]
	    if { $n < 5 } {
		set n 5
	    }
	    set dAi [expr $dA/$n]
	    for {set i 0} {$i<=$n} {incr i} {
		set Ai  [expr $A1+$dAi*$i]
		set k [expr $i%2* pow(-1,int($i/2))]
		set SinA [expr sin($Ai)]
		set CosA [expr cos($Ai)]
		set rxi [expr $xc+ ($R+$h*$k)*$CosA]
		set ryi [expr $yc+ ($R+$h*$k)*$SinA]
		lappend points $rxi $ryi
	    }
	    set id [ eval {$w create line} $points  \
		    {-tags "line $tag" -width 2 \
		    -fill $db(linecolor,$db(linetype))  } ]
	}
	"Cross" {
	    set Size $db(CrossSize)
	    scan "$points" %i%i x y
	    set xb [expr $x - $Size/2]
	    set yb [expr $y - $Size/2]
	    set xe [expr $x + $Size/2]
	    set ye [expr $y + $Size/2]
	    set id1 [eval {$w create line $xb $yb $xe $ye -fill $db(linecolor) \
		    -width 3 -tags "line $tag"}]
	    set xb [expr $x - $Size/2]
	    set yb [expr $y + $Size/2]
	    set xe [expr $x + $Size/2]
	    set ye [expr $y - $Size/2]
	    set id2 [eval {$w create line $xb $yb $xe $ye -fill $db(linecolor) \
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
	"Vertex" {
	scan "$points" %i%i x y
	set r $db(VertexR)
	set id [eval {$w create oval} [expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r]  \
		{-tags "oval $tag"  -width 1 -fill $db(linecolor) -outline $db(linecolor) }]
	}
    }
 #   puts "DL: $type, $id"
    foreach idd "$id" {
	$w bind $idd <1> "FieldEvent %W %x %y $type {$id}"	
    }
    set db(mode) "$db(linetype) Created"
}





