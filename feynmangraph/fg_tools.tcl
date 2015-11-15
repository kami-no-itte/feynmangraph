proc Grid {w cmd {par 10}} {

    global db diag
    regexp {^\.([^.]*)} $w m ww    
    switch -exact $cmd {
	init   {
	    set db($ww,Grid) "Off"
	    set db($ww,SnapToGrid) "Off"
	    set db($ww,GridColor) $db(GridColor)
	    set db($ww,GridColor5) $db(GridColor5)
	    set db($ww,XGridStep) $db(XGridStep)
	    set db($ww,YGridStep) $db(YGridStep)
	    return
	}
	toggle {
	    if { $db($ww,Grid) == "On" } { Grid $w Off } else { Grid $w On }    
	}
	Snap {
	    if { $db($ww,SnapToGrid) == "On" } { Grid $w SnapOff } \
		    else { Grid $w SnapOn }    
	}
	On  {
	    if { $db($ww,Grid) != "On" } {
		set db($ww,Grid) "On"
		Grid $w Draw
	    }
	    set db(mode) "Grid is On"
	}
	Off {
	    if { $db($ww,Grid) == "On" } {
		Grid $w Remove
		set db($ww,Grid) "Off"
	    }
	    set db(mode) "Grid is Off"
	}
	SnapOn {
	    if { $db($ww,SnapToGrid) != "On" } {
		set db($ww,SnapToGrid) "On"
	    }
	    set db(mode) "Snap to Grid is On"
	}
	SnapOff {
	    if { $db($ww,SnapToGrid) == "On" } {
		set db($ww,SnapToGrid) "Off"
	    }
	    set db(mode) "Snap to Grid is Off"
	}
	Resize {
	    if { $db($ww,Grid) == "On" } {
		Grid $w Remove
		Grid $w Draw
	    }   
	}
	Draw {

	    if { $db($ww,Grid) != "On" } { return }

	    set d $db($ww,diag)
	    scan "[winfo height $w] [winfo width $w]" %d%d ys xs
	    set xstep $db($ww,XGridStep)
	    set ystep $db($ww,YGridStep)
	    scan "$xstep $ystep" %d%d x y
	    while { $x<$xs } {
		if { [expr int($x/$xstep)%5] == 0} { 
		    set gc $db(GridColor5)
		} else {
		    set gc $db(GridColor)
		}
		$w create line $x 0 $x $ys -tag Grid -width 1 \
			-fill "#$gc" -stipple @$db(InstallDir)$db(GridStipple)
		incr x $xstep
	    }
	    while { $y<$ys } {
		if { [expr int($y/$ystep)%5] == 0} { 
		    set gc $db(GridColor5)
		} else {
		    set gc $db(GridColor)
		}
		$w create line 0 $y $xs $y -tag Grid -width 1 \
			-fill "#$gc" -stipple @$db(InstallDir)$db(GridStipple)
		incr y $ystep
	    }
	    $w lower Grid
	}
	Remove {
	    $w delete withtag Grid
	}
	SetStep {
	    set db($ww,XGridStep) $par
	    set db($ww,YGridStep) $par
	    Grid $w Resize
	}
    }
    set db($ww,StatusLineTxt) "[eval $db($ww,StatusLineFmt)]"
}

proc GridXY {w x y} {
    global db
    regexp {^\.([^.]*)} $w m ww
    return "[list [expr int(($x+0.5*$db($ww,XGridStep))/$db($ww,XGridStep))*$db($ww,XGridStep)] \
                  [expr int(($y+0.5*$db($ww,YGridStep))/$db($ww,YGridStep))*$db($ww,YGridStep)]]"
}

proc SetTextFont {w font} {
    global db

    regexp {^\.([^.]*)} $w m ww
    set db($ww,TextFont) $font
    set db($ww,font) $db($font)
    set db($ww,StatusLineTxt) "[eval $db($ww,StatusLineFmt)]"
}   