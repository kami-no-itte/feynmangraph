proc FG_StartBox {} {
    global db
    set rlf flat
    set bd 0
    toplevel .logo -relief $rlf -bd $bd  -height 1 -width 1
    wm title .logo "Feynman Graph"
    wm minsize .logo 480 320
    wm iconify .logo

    canvas .logo.c  -width  480  -height  320
    set dir ""
    if [info exists db(InstallDir)] { set dir $db(InstallDir) }
    set file $dir$db(LogoFN)
    set id [image create photo pict -file $file]
    .logo.c create image 0 0 -image $id -tag "Logo" -anchor nw
    pack .logo.c -in .logo -expand yes -fill both
    wm deiconify .logo
    tkwait visibility .logo.c
    focus .logo
}

proc FG_MainBox {w {cmd create} args} {

    global db Diag
    set wf $w
    
    switch -exact $cmd {
	show   { 
	    if {[winfo exists "$wf"]}  "wm deiconify $wf"
	}
	hide   { 
	    if {![winfo exists "$wf"]} { 
		return
	    } else {
		wm withdraw $wf
	    } 
	}
	destroy {
	    destroy "$wf"
	}
	New    {
	    set l 0
	    foreach var "[lsort [array names Diag]]" {
		regexp {^[^,]*,Comment} $var v
		if { [info exists v] } {
		    regexp {^([^,]*)} $v n
		    lappend l $n
		    unset v
		}
	    }
	    if { [llength $l] > 1 } {
		set db(diag) "[expr [format %d [lindex $l [expr [llength $l]-1]]]+1]" 
	    }
	    FG_MainBox $w create     
	}
	create {
	    
	    set wf .$db(winN)
	    regexp {^\.([^.]*)} $wf m ww
	    if { $w != {} } {
		regexp {^\.([^.]*)} $w m wwl
		set db($ww,diag) $db($wwl,diag)
		Cancel_SelReg
		FG_Cancel $w
	    } else {
		set db($ww,diag) $db(diag)
	    }
	    FG_CreateMainBox $wf
	    wm deiconify $wf
	    focus $wf		    
	    bind $wf <Destroy> {
		FG_Cancel %W.c
		set winlist {}
# puts "winfo children . : [winfo children .]"
		foreach var  "[winfo children .]" {
		    set winid ""
		    regexp {^.[0-9][0-9]*$}  $var winid
		    if { $winid != "" } { lappend winlist $winid }
		}
		if { [llength $winlist] == 1 } "FG_ListDiags {} update"
	    }
	    incr db(winN)
	}
    }
}

proc Quit { } {
    global db
    FG_rc write
    if { [info exists db(quit)] } exit
    set db(quit) ""
    exit
}

proc FG_SetMainBoxParams {wf} {
        global db diag

	regexp {^\.([^.]*)} $wf m ww

	set diag($ww,Comment) ""
	set db($ww,Comment) ""
        set db($db($ww,diag),Status) ""
        set db($ww,TextFont) $db(TextFont)
        set db($ww,font) $db($db($ww,TextFont))

	Grid $wf.c init
}

proc FG_CreateMainBox {wf} {
    global db diag
    if [winfo exists "$wf"] { return }
    regexp {^\.([^.]*)} $wf m ww
#puts "MainBox: wf  $wf,   ww  $ww"
    
    set rlf flat
    set bd 0
    toplevel $wf -relief $rlf -bd $bd  -height 1 -width 1
    wm title $wf "Feynman Graph"
    wm iconify $wf

    FG_SetMainBoxParams $wf
    
    set rlf raised
    set bd 2
    frame $wf.menu -relief $rlf -bd $bd  
    frame $wf.0 -relief sunken -bd $bd
    frame $wf.1 -relief $rlf -bd $bd  
    frame $wf.2 -relief $rlf -bd $bd  
    frame $wf.3 -relief $rlf -bd $bd  
    frame $wf.4 -relief $rlf -bd $bd  
    frame $wf.5 -relief $rlf -bd $bd
    pack  $wf.menu  -expand no -fill x
    pack  $wf.3 $wf.5 $wf.2 $wf.1 -expand no -side bottom -fill x
    pack  $wf.0 -expand yes -fill both -padx 10 -pady 10
    
    menubutton $wf.menu.file -text "File" -menu $wf.menu.file.m -underline 0
    menu $wf.menu.file.m 
    $wf.menu.file.m add command -label "Load Diagram" -underline 5 \
	    -command "FG_LoadDiag $wf" 
    $wf.menu.file.m add command -label "Load Picture" -underline 5 \
	    -command "FG_OpenFile $wf 0" 
#    $wf.menu.file.m add command -label "Load Config" -underline 7 \
#	    -command "FG_LoadConfig" 
#    $wf.menu.file.m add command -label "Reset Config" -underline 7 \
#	    -command "FG_LoadOrigConfig" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "List Diagrams" -underline 0 \
	    -command "FG_ListDiags $wf" 
    $wf.menu.file.m add command -label "Remove Current" -underline 0 \
	    -command "FG_RemoveDiag $wf" 
    $wf.menu.file.m add separator
    
    $wf.menu.file.m add command -label "Clear" -underline 0 \
	    -command "FG_RemoveAll $wf" 
    $wf.menu.file.m add command -label "New Window" -underline 0 \
	    -command "FG_MainBox {} New ; set db(mode) {New Window Opened} " 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "Show Loaded" -underline 0 \
	    -command "ShowDiag $wf"
    
    #        $wf.menu.file.m add command -label "Update Current" -underline 0 \
	    #				-command "FG_SaveDiag $wf current" 
    $wf.menu.file.m add command -label "Save" -underline 0 \
	    -command "FG_SaveDiag $wf all" 
    $wf.menu.file.m add command -label "Save as ..." -underline 5 \
	    -command "FG_SaveDiag $wf as" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "Create PS" -underline 0 \
	    -command "FG_Print $wf.c" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "Close" -underline 3 \
	    -command "FG_MainBox $wf destroy" 
    $wf.menu.file.m add command -label "Exit" -underline 1 \
	    -command "Quit" 
    
    
    menubutton $wf.menu.reg -text "Line" -menu $wf.menu.reg.m -underline 0
    menu $wf.menu.reg.m
    $wf.menu.reg.m add command -label "Draw Scalar" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Scalar" 
    $wf.menu.reg.m add command -label "Draw Fermion" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Fermion" 
    $wf.menu.reg.m add command -label "Draw H-Fermion" -underline 5 -command \
	    "FG_StartLineDraw $wf.c HFermion"
    $wf.menu.reg.m add command -label "Draw Meson" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Meson" 
    $wf.menu.reg.m add command -label "Draw Photon" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Photon" 
    $wf.menu.reg.m add command -label "Draw Gluon" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Gluon" 
    $wf.menu.reg.m add command -label "Draw W-boson" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Wboson" 
    $wf.menu.reg.m add command -label "Draw Line" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Line" 
    $wf.menu.reg.m add command -label "Draw Arrow" -underline 5 -command \
	    "FG_StartLineDraw $wf.c Arrow" 
    $wf.menu.reg.m add command -label "Draw Curve" -underline 5 -command \
	    "FG_StartRegDraw $wf.c Curve" 
    $wf.menu.reg.m add sep
    $wf.menu.reg.m add command -label "Draw Oval" -underline 5 -command \
	    "FG_StartOvalDraw $wf.c Oval" 
    $wf.menu.reg.m add command -label "Draw Vertex" -underline 5 -command \
	    "FG_StartVertexDraw $wf.c Vertex" 
    $wf.menu.reg.m add command -label "Draw X" -underline 5 -command \
	    "FG_StartCrossDraw $wf.c Cross"
    $wf.menu.reg.m add command -label "Draw line 1" -underline 6 -command \
	    "FG_StartLineDraw $wf.c line1" 
    $wf.menu.reg.m add command -label "Draw arrow 1" -underline 6 -command \
	    "FG_StartLineDraw $wf.c arrow1" 
    $wf.menu.reg.m add command -label "Draw blob" -underline 5 -command \
	    "FG_StartOvalDraw $wf.c blob" 
    
    
    menubutton $wf.menu.arc -text "Arc" -menu $wf.menu.arc.m -underline 0
    menu $wf.menu.arc.m
    $wf.menu.arc.m add command -label "Draw Scalar" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Scalar" 
    $wf.menu.arc.m add command -label "Draw Fermion" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Fermion" 
    $wf.menu.arc.m add command -label "Draw H-Fermion" -underline 5 -command \
	    "FG_StartArcDraw $wf.c HFermion" 
    $wf.menu.arc.m add command -label "Draw Meson" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Meson" 
    $wf.menu.arc.m add command -label "Draw Photon" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Photon" 
    $wf.menu.arc.m add command -label "Draw Gluon" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Gluon" 
    $wf.menu.arc.m add command -label "Draw W-boson" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Wboson" 
    $wf.menu.arc.m add command -label "Draw Line" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Line" 
    $wf.menu.arc.m add command -label "Draw Arrow" -underline 5 -command \
	    "FG_StartArcDraw $wf.c Arrow" 
    $wf.menu.arc.m add sep
    $wf.menu.arc.m add command -label "Draw line 1" -underline 6 -command \
	    "FG_StartArcDraw $wf.c line1" 
    $wf.menu.arc.m add command -label "Draw arrow 1" -underline 6 -command \
	    "FG_StartArcDraw $wf.c arrow1" 
    
    
    
    menubutton $wf.menu.text -text "Text" -menu $wf.menu.text.m -underline 0
    menu $wf.menu.text.m 
    $wf.menu.text.m add command -label "Create Text" -underline 7 -command \
	    "FG_StartText $wf.c" 
    $wf.menu.text.m add separator
    $wf.menu.text.m add cascade -label "Set Font" -underline 4 -menu \
	    "$wf.menu.text.m.setfont" 
    
    menu $wf.menu.text.m.setfont
    $wf.menu.text.m.setfont add cascade -label "Roman"  -underline 0 -menu \
	    "$wf.menu.text.m.setfont.roman"
    $wf.menu.text.m.setfont add cascade -label "Italic" -underline 0 -menu \
	    "$wf.menu.text.m.setfont.italic"
    $wf.menu.text.m.setfont add cascade -label "Greek"  -underline 0 -menu \
	    "$wf.menu.text.m.setfont.greek"
    
    menu $wf.menu.text.m.setfont.roman
    $wf.menu.text.m.setfont.roman add command -label "Medium 34" -underline 7 -command \
	    "SetTextFont $wf roman-medium-34"
    $wf.menu.text.m.setfont.roman add command -label "Medium 24" -underline 7 -command \
	    "SetTextFont $wf roman-medium-24"
    $wf.menu.text.m.setfont.roman add command -label "Medium 18" -underline 7 -command \
	    "SetTextFont $wf roman-medium-18"
    $wf.menu.text.m.setfont.roman add command -label "Medium 12" -underline 7 -command \
	    "SetTextFont $wf roman-medium-12"
    
    menu $wf.menu.text.m.setfont.italic
    $wf.menu.text.m.setfont.italic add command -label "Bold 34" -underline 5 -command \
	    "SetTextFont $wf italic-bold-34"
    $wf.menu.text.m.setfont.italic add command -label "Bold 24" -underline 5 -command \
	    "SetTextFont $wf italic-bold-24"
    $wf.menu.text.m.setfont.italic add command -label "Bold 18" -underline 5 -command \
	    "SetTextFont $wf italic-bold-18"
    $wf.menu.text.m.setfont.italic add command -label "Bold 12" -underline 5 -command \
	    "SetTextFont $wf italic-bold-12"
    $wf.menu.text.m.setfont.italic add command -label "Medium 34" -underline 7 -command \
	    "SetTextFont $wf italic-medium-34"
    $wf.menu.text.m.setfont.italic add command -label "Medium 24" -underline 7 -command \
	    "SetTextFont $wf italic-medium-24"
    $wf.menu.text.m.setfont.italic add command -label "Medium 18" -underline 7 -command \
	    "SetTextFont $wf italic-medium-18"
    $wf.menu.text.m.setfont.italic add command -label "Medium 12" -underline 7 -command \
	    "SetTextFont $wf italic-medium-12"
    
    menu $wf.menu.text.m.setfont.greek
    $wf.menu.text.m.setfont.greek add command -label "Medium 34" -underline 7 -command \
	    "SetTextFont $wf greek-medium-34"
    $wf.menu.text.m.setfont.greek add command -label "Medium 24" -underline 7 -command \
	    "SetTextFont $wf greek-medium-24"
    $wf.menu.text.m.setfont.greek add command -label "Medium 18" -underline 7 -command \
	    "SetTextFont $wf greek-medium-18"
    $wf.menu.text.m.setfont.greek add command -label "Medium 12" -underline 7 -command \
	    "SetTextFont $wf greek-medium-12"
    
    
    
    menubutton $wf.menu.tools -text "Tools" -menu $wf.menu.tools.m -underline 0
    menu $wf.menu.tools.m
    $wf.menu.tools.m add cascade -label "Grid" -underline 0 -menu \
	    "$wf.menu.tools.m.greed" 
    
    menu $wf.menu.tools.m.greed
    $wf.menu.tools.m.greed add command -label "Grid On/Off"  -underline 0 -command \
	    "Grid $wf.c toggle"
    $wf.menu.tools.m.greed add command -label "Snap to Grid On/Off"  -underline 0 -command \
	    "Grid $wf.c Snap"
    $wf.menu.tools.m.greed add cascade -label "Grid Step" -underline 0 -menu \
	    "$wf.menu.tools.m.greed.setsize"
    menu $wf.menu.tools.m.greed.setsize
    $wf.menu.tools.m.greed.setsize add command -label "8" -command \
	    "Grid $wf.c SetStep 8"
    $wf.menu.tools.m.greed.setsize add command -label "10" -command \
	    "Grid $wf.c SetStep 10"
    $wf.menu.tools.m.greed.setsize add command -label "12" -command \
	    "Grid $wf.c SetStep 12"
    $wf.menu.tools.m.greed.setsize add command -label "15" -command \
	    "Grid $wf.c SetStep 15"
    
    $wf.menu.tools.m add command -label "Select Line Color" -command \
	    "ChooseColor $wf {} {} {} {} start"
    
    menubutton $wf.menu.help -text "Help" -menu $wf.menu.help.m -underline 0
    menu $wf.menu.help.m 
    $wf.menu.help.m add command -label "About FG" -underline 0 -command "Help About"
    $wf.menu.help.m add sep
    $wf.menu.help.m add command -label "Help on File" -underline 8 -command "Help File"
    $wf.menu.help.m add command -label "Help on Draw" -underline 8 -command "Help Draw"
    $wf.menu.help.m add command -label "Help on Text" -underline 8 -command "Help Text"
    $wf.menu.help.m add command -label "Help on Edit" -underline 8 -command "Help Edit"
#        $wf.menu.help.m add command -label "Help on Window" -underline 8 -command "Help Window"
    $wf.menu.help.m add command -label "Help on Tools" -underline 8 -command "Help Tools"
    $wf.menu.help.m add command -label "Help on #"    -underline 8 -command "Help Number"
    $wf.menu.help.m add separator
    $wf.menu.help.m add command -label "Advanced..." -underline 9 -command "Help Advanced"
    
    
    
#        tk_menuBar $wf.menu $wf.menu.file $wf.menu.reg $wf.menu.window \
#		$wf.menu.help $wf.menu.exit $wf.menu.arc $wf.menu.show $wf.menu.tools

    tk_menuBar $wf.menu $wf.menu.file $wf.menu.reg \
	    $wf.menu.help $wf.menu.exit $wf.menu.arc $wf.menu.show $wf.menu.tools
    tk_bindForTraversal $wf $wf.menu $wf.menu.file $wf.menu.reg $wf.menu.window \
	    $wf.menu.help $wf.menu.arc $wf.menu.show $wf.menu.tools
    
    pack $wf.menu.file $wf.menu.reg $wf.menu.arc $wf.menu.tools $wf.menu.text -side left -padx 1m
    #        pack $wf.menu.help $wf.menu.window -side right -padx 1m
    pack $wf.menu.help -side right -padx 1m
    
    canvas $wf.c  -width $diag(HScreenW) -height $diag(HScreenH) -background white
    set db($ww,DiagNumFmt)     { set _q "Diagram # $db($ww,diag)" }
    set db($ww,DiagNumTxt) "[eval $db($ww,DiagNumFmt)]"	    
    button $wf.lh -textvariable db($ww,DiagNumTxt) -width 10
    bind $wf.lh <1>  "change_DiagPar $wf create"
    label $wf.lg -textvariable db($ww,Comment) -width 30 -anchor w
#	bind $wf.lg <1> "change_GlobalPar $wf"
    
    set db($ww,StatusLineFmt)     { set _q \
	    "Grid Step: $db($ww,XGridStep)  Snap To Grid: $db($ww,SnapToGrid)  Font: $db($ww,TextFont)" }
    set db($ww,StatusLineTxt) "[eval $db($ww,StatusLineFmt)]"	    
    label $wf.st -textvariable db($ww,StatusLineTxt)  -width 50 -anchor w
    
    label $wf.lc -relief groove -bd 4
    label $wf.lr -textvariable db(mode)  -width 30
    
    bind $wf.c <Motion> "$wf.lc configure -text \" Coordinates =  x:%x  y:%y \""
    bind $wf.c <Shift-1> {FG_PasteFromBuf %W %x %y}
    bind $wf.c <Control-1> {FG_PasteFromBuf %W %x %y "-1 1"}
    bind $wf.c <Control-Shift-1> {FG_PasteFromBuf %W %x %y "1 -1"}
    bind $wf.c <Shift-3> {FG_StartBboxDraw %W %x %y}
    bind $wf.c <Configure>  { FG_ResizeMainBox %W }
    
    FG_BindSave $wf.c
    
    pack $wf.lc -in $wf.1 -expand no -fill x
    pack $wf.lh  $wf.lg -in $wf.2 -side left  -expand no -fill x -padx 3
    pack $wf.lr -in $wf.3 -side right  -expand no -fill x
    pack $wf.st -in $wf.5 -side left -expand no -fill x
    pack $wf.c -in $wf.0 -expand yes -fill both
}

proc Help {topic} {
    
    global db
    set rlf flat
    set bd 0
    
    set wh .helpOn$topic
    if { [winfo exists $wh] } {destroy $wh}
    toplevel $wh -relief $rlf -bd $bd  -height 1 -width 1
    if { $topic == "About" } {
	wm title $wh "$topic FeynmanGraph"
    } else {
	wm title $wh "Help on:  $topic"
    }
    wm iconify $wh
    
    frame $wh.f
    pack  $wh.f -side top -fill both -expand true
    set HelpText $db(help,$topic)
#    set HelpText $topic
    set t [text $wh.f.t -wrap word -width 70 -height 24 \
	    -yscrollcommand "$wh.f.ty set"]
    scrollbar $wh.f.ty -orient vert -command "$wh.f.t yview"
    pack $wh.f.ty -side right -fill y
    pack $wh.f.t  -side left -fill both -expand true 
    $t insert end $HelpText
    wm deiconify $wh
    
}

