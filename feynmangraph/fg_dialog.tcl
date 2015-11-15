
proc FG_DiagParDialog {w} {

    global db diag var_h

# puts "w: $w"
    set wf $w.hpd
    toplevel $wf
    wm title $wf "Set Diagram Parameters"
    wm minsize $wf 300 200
    wm iconify $wf
   
    set rlf sunken
    set txtwidth 18
    set varwidth 6
    set errwidth 10
    set diagN $var_h(diag)
    set BadDiagNumMsg "Bad number"
    set bd 0
    frame $wf.0 -relief $rlf -bd $bd  
    frame $wf.1 -relief $rlf -bd $bd  
    frame $wf.2 -relief $rlf -bd $bd  
    frame $wf.3 -relief $rlf -bd $bd  
    frame $wf.4 -relief $rlf -bd $bd  
    frame $wf.5 -relief $rlf -bd $bd
    frame $wf.6 -relief $rlf -bd $bd  
    frame $wf.7 -relief $rlf -bd $bd  
    frame $wf.8 -relief $rlf -bd $bd  
    frame $wf.9 -relief $rlf -bd $bd  
    frame $wf.a -relief $rlf -bd $bd  
    frame $wf.b -relief $rlf -bd $bd


    label $wf.hnl -text "Diagram Number" -width $txtwidth -anchor nw
    entry $wf.hne -textvariable var_h(diag)  -width $varwidth
#    bind  $wf.hne <Return> "change_DiagPar $w SetDiagNum"
    bind  $wf.hne <Return> "change_DiagPar $w CheckDiagNum $wf.ygse $wf.hne"
    bind  $wf.hne <Down> "focus $wf.ygse"

    set db($wf,BadDiagNum) ""
    label $wf.err -textvariable db($wf,BadDiagNum) -width $errwidth -anchor nw

    label $wf.ygsl -text "Comment"  -width  $txtwidth -anchor nw
    entry $wf.ygse -textvariable var_h(Comment) -width 30
    bind  $wf.ygse <Return> "focus $wf.okb"
    bind  $wf.ygse <Up> "focus $wf.hne"
    bind  $wf.ygse <Down> "focus $wf.okb"

    button $wf.okb -text "Ok"   -relief raised -width 10 -command "change_DiagPar $w ok"
    bind   $wf.okb <Return> "change_DiagPar $w ok $wf.ygse $wf.hne"
    bind   $wf.okb <Up> "focus $wf.ygse"
    bind   $wf.okb <Right> "focus $wf.clrb"

    button $wf.clrb -text "Clear"   -relief raised -width 10 -command "change_DiagPar $w clear"
    bind   $wf.clrb <Return> "change_DiagPar $w clear"
    bind   $wf.clrb <Up> "focus $wf.ygse"
    bind   $wf.clrb <Right> "focus $wf.cnlb"
    bind   $wf.clrb <Left> "focus $wf.okb"

    button $wf.cnlb -text "Cancel"   -relief raised -width 10 -command "change_DiagPar $w cancel"
    bind   $wf.cnlb <Return> "change_DiagPar $w cancel"
    bind   $wf.cnlb <Up> "focus $wf.ygse"
    bind   $wf.cnlb <Left> "focus $wf.clrb"
    
    pack $wf.0 -expand yes -fill both -anchor nw -padx 3 -pady 3
    pack $wf.1 $wf.2  $wf.3 $wf.4  $wf.5 $wf.6  $wf.7 $wf.8 -in $wf.0 -side top -expand no \
	    -padx 3 -pady 1
    pack $wf.hnl $wf.hne $wf.err -in $wf.1 -side left -expand no -padx 3 -pady 1
#    pack $wf.parl $wf.pare -in $wf.2 -side left -expand no -padx 3 -pady 1
#    pack $wf.ptl $wf.pte -in $wf.3 -side left -expand no -padx 3 -pady 1
#    pack $wf.xsl $wf.xse -in $wf.4 -side left -expand no -padx 3 -pady 1
#    pack $wf.ysl $wf.yse -in $wf.5 -side left -expand no -padx 3 -pady 1
#    pack $wf.xgsl $wf.xgse -in $wf.6 -side left -expand no -padx 3 -pady 1
    pack $wf.ygsl $wf.ygse -in $wf.7 -side left -expand no -padx 3 -pady 1
    pack $wf.a -in $wf.0 -side bottom -expand no -padx 3 -pady 1
    

    pack $wf.okb $wf.clrb $wf.cnlb -in $wf.a -side left -expand yes -padx 8 -pady 8

    wm deiconify $wf
}

proc change_DiagPar {w {cmd create} {focus1 ""} {focus2 ""} } {

    global db diag var_h
#   puts "$cmd" 
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)

    switch -exact $cmd {
	create {
	    set wf $w.hpd
	    if { [winfo exists $wf] } return
	    set h $diagN
	    set var_h(diag) $h
	    foreach index "Comment" {
		if { [info exists diag($h,$index)] } {
		    set  var_h($index) $diag($h,$index)
		} else {
		    set  var_h($index) $diag(0,$index)
		}
	    }
	    FG_DiagParDialog $w
	    tkwait visibility $wf
	    focus $wf.hne
	    grab $wf
	    set db(mode) "Setting Diagram Parameters"
	}
	clear {   
	    foreach var "[array names var_h]"  {#
		set var_h($var) ""
	    }
	    focus $w.hpd.hne
	    set db(mode) "Setting Diagram Parameters"
	}
	cancel {
	    grab release $w.hpd
	    destroy $w.hpd
	    foreach var "[array names var_h]"  {
		unset var_h($var)
	    }
	    set db(mode) "Setting Diagram Parameters Cancelled"
	}
	ok {
	    if { [scan [lindex $var_h(diag) 0] %d h] == 1 && $h == $var_h(diag) \
		    && $h>0 && $h<1000} {
		set db($ww,diag) $h
		set db(diag) $h
		set diagN $h
		grab release $w.hpd
		destroy $w.hpd
		if { $h != "0" } {
		    foreach var "[array names diag {0,*} ]"  {
			regexp  {0,(.+)} $var m v
			set diag($h,$v) $diag($var)
		    }
		}
		foreach var "[array names var_h]"  {
		    if { $var != "diag" } {
			set diag($h,$var) $var_h($var)
			unset var_h($var)
		    }
		}
		set db($ww,Comment) $diag($h,Comment)
		wm title $w $db($ww,Comment)
		set db(mode) "Setting Diagram Parameters Completed"
		#	    ShowDiag $w
		set db($ww,DiagNumTxt) "[eval $db($ww,DiagNumFmt)]"
		FG_CreateDiagConfig $w
	    } else {
		set wf $w.hpd
		set db($wf,BadDiagNum) "Bad Number!"
		focus $focus2
	    }
	}	    
	SetDiagNum {
	    set h $var_h(diag)
	    foreach var "[array names var_h]"  {
		if { [info exists diag($h,$var)] } {
		    set var_h($var) $diag($h,$var)
		} else {
		    if { $var != "diag" } {
			set var_h($var) $diag(0,$var)
		    }
		}
	    }
	    ShowDiag $w
	    set db(mode)  "Setting Diagram Parameters"
	}
	CheckDiagNum {
	    set wf $w.hpd
	    scan [lindex $var_h(diag) 0] %d h
	    if { [scan [lindex $var_h(diag) 0] %d h] == 1 && $h == $var_h(diag) \
		    && $h>0 && $h<1000} {
                set db($wf,BadDiagNum) ""
		focus $focus1
		change_DiagPar $w SetDiagNum	
	    } else {
                set db($wf,BadDiagNum) "Bad Number!"
		focus $focus2
	    }    
	}
    }
}

proc FG_GlobalParDialog {w} {

    global db diag var_g

    set wf $w.gpd
    toplevel $wf
    wm title $wf "Set Global Parameters"
    wm minsize $wf 300 200
    wm iconify $wf
   
    set rlf sunken
    set txtwidth 25
    set varwidth 4
    set bd 0
    frame $wf.0 -relief $rlf -bd $bd  
    frame $wf.1 -relief $rlf -bd $bd  
    frame $wf.2 -relief $rlf -bd $bd  
    frame $wf.3 -relief $rlf -bd $bd  
    frame $wf.4 -relief $rlf -bd $bd  
    frame $wf.5 -relief $rlf -bd $bd
    frame $wf.6 -relief $rlf -bd $bd  
    frame $wf.7 -relief $rlf -bd $bd  
    frame $wf.8 -relief $rlf -bd $bd  
    frame $wf.9 -relief $rlf -bd $bd  
    frame $wf.a -relief $rlf -bd $bd  
    frame $wf.b -relief $rlf -bd $bd

    label $wf.nhl -text "Number of Diagrams" -width $txtwidth -anchor nw
    entry $wf.nhe -textvariable var_g(NumDiags) -width $varwidth
    bind  $wf.nhe <Return> "focus $wf.sse"
    bind  $wf.nhe <Down> "focus $wf.sse"

    label $wf.ssl -text "Screen Server Delay (sec)"  -width $txtwidth -anchor nw
    entry $wf.sse -textvariable var_g(idleTimeOut) -width $varwidth
    bind $wf.sse <Return> "focus $wf.hmb"
    bind  $wf.sse <Up> "focus $wf.nhe"
    bind  $wf.sse <Down> "focus $wf.hmb"

    button $wf.hmb -text "Caption"   -relief raised -width 20 -command "Edit_txt $wf create Caption"
    bind   $wf.hmb <Return> "Edit_txt $wf create Caption"
    bind   $wf.hmb <Up> "focus $wf.sse"
    bind   $wf.hmb <Right> "focus $wf.udb"
    bind   $wf.hmb <Down> "focus $wf.okb"

    button $wf.udb -text "`Help' text"   -relief raised -width 20 -command "Edit_txt $wf create Help"
    bind   $wf.udb <Return> "Edit_txt $wf create UserDir"
    bind   $wf.udb <Up> "focus $wf.sse"
    bind   $wf.udb <Left> "focus $wf.hmb"
    bind   $wf.udb <Down> "focus $wf.okb"

    button $wf.okb -text "OK"   -relief raised -width 10 -command "change_GlobalPar $w ok"
    bind   $wf.okb <Return> "change_GlobalPar $w ok"
    bind   $wf.okb <Up> "focus $wf.hmb"
    bind   $wf.okb <Right> "focus $wf.clrb"

    button $wf.clrb -text "Clear"   -relief raised -width 10 -command "change_GlobalPar $w clear"
    bind   $wf.clrb <Return> "change_GlobalPar $w clear"
    bind   $wf.clrb <Up> "focus $wf.hmb"
    bind   $wf.clrb <Right> "focus $wf.cnlb"
    bind   $wf.clrb <Left> "focus $wf.okb"

    button $wf.cnlb -text "Cancel"   -relief raised -width 10 -command "change_GlobalPar $w cancel"
    bind   $wf.cnlb <Return> "change_GlobalPar $w cancel"
    bind   $wf.cnlb <Up> "focus $wf.hmb"
    bind   $wf.cnlb <Left> "focus $wf.clrb"

    
    pack $wf.0 -expand yes -fill both -anchor nw -padx 3 -pady 3
    pack $wf.1 $wf.2 -in $wf.0 -side top -expand no \
	    -padx 3 -pady 1
    pack $wf.nhl $wf.nhe -in $wf.1 -side left -expand no -padx 3 -pady 1
    pack $wf.ssl $wf.sse -in $wf.2 -side left -expand no -padx 3 -pady 1

    pack $wf.a $wf.b -in $wf.0 -side bottom -expand no -padx 3 -pady 1
    pack $wf.hmb $wf.udb -in $wf.b -side left -expand yes -padx 8 -pady 8
  
    pack $wf.okb $wf.clrb $wf.cnlb -in $wf.a -side left -expand yes -padx 8 -pady 8

    wm deiconify $wf
}

proc change_GlobalPar {w {cmd create}} {

    global db diag var_g
#   puts "$cmd" 
    switch -exact $cmd {
	create {
	    set wf $w.gpd
	    if { [winfo exists $wf] } return
	    set var_g(NumDiags) $diag(NumDiags)
	    set var_g(idleTimeOut) $diag(idleTimeOut)
	    FG_GlobalParDialog $w
	    tkwait visibility $wf
	    focus $wf.nhe
	    grab $wf
	    set db(mode) "Setting Global Parameters"
	}
	clear {   
	    foreach var "NumDiags idleTimeOut"  {
		set var_g($var) ""
	    }
	    focus $w.gpd.nhe
	    set db(mode) "Setting Global Parameters"
	}
	cancel {
	    grab release $w.gpd
	    destroy $w.gpd
	    foreach var "[array names var_g]"  {
		unset var_g($var)
	    }
	    set db(mode) "Setting Global Parameters Cancelled"
	}
	ok {
	    set h $var_g(NumDiags)
	    if { $h<0 || $h>100 } {
		set db(mode) "Cannot be SO MANY Diagrams !"
		return
	    }
	    grab release $w.gpd
	    destroy $w.gpd
	    foreach var "[array names var_g]"  {
		    set diag($var) $var_g($var)
	    }
	    set db(mode) "Setting Global Parameters Completed"
	}	    
    }
}

proc Edit_txt {w cmd page} {
    global db diag

    set wf $w.caption
    switch -exact $cmd {
	create {
	    if { [winfo exists $wf] } return
	    toplevel $wf
	    wm title $wf "$page Text Edit"
	    wm iconify $wf
	    set Txt [text $wf.t -width 50 -height 15]

	    frame $wf.0 -relief sunken -bd  0
	    button $wf.b -text "Done" -width 6 -relief raised -command "Edit_txt $w done $page"
	    button $wf.c -text "Cancel" -width 6 -relief raised -command "Edit_txt $w cancel $page"	    
	    button $wf.d -text "Clear" -width 6 -relief raised -command "Edit_txt $w clear $page"	    
	    pack $wf.t $wf.0 -side top -expand no -padx 3 -pady 1
	    pack $wf.b $wf.d $wf.c -in $wf.0  -side left -expand no -padx 3 -pady 1
	    switch -exact $page {
		Caption {
		    set text "$diag(CaptionTxt)"
		}
		Help {
		    set text "$diag(HelpTxt)"
		}
	    }
	    $wf.t insert end "$text"
	    wm deiconify $wf
	    tkwait visibility $wf
	    focus $wf.t
	    grab $wf
	    set db(mode) "$page Text Edit"
	}
	cancel {
	    grab release $w.caption
	    destroy $w.caption
	    set db(mode) "$page Text Edit Cancelled"
	    grab $w
	}
	clear {
	    $wf.t delete 0.0 end
	    focus $wf.t
	    set db(mode) "$page Text Edit"
	}
	done {
	    set text "[$wf.t get 0.0 end]" 
	    switch -exact $page {
		Caption {
		    set diag(CaptionTxt) "$text"
		}
		Help {
		    set diag(HelpTxt) "$text"
		}
	    }
	    grab release $w.caption
	    destroy $w.caption
	    set db(mode) "$page Text Edit Completed"	    
	}
    }
}

proc FG_ListDiags {w {cmd update}} {
    global db Diag
    
    switch -exact $cmd {
	update {
	    if { $w != {} } {
		Cancel_SelReg noupdate
		FG_Cancel $w.c noupdate
	    }
	    if { ![winfo exists .l] } {
		FG_ListDiags $w create    
	    }
#	    puts "            List of Existing Diagrams: "
#	    puts " "
	    set ListOfDiags ""
	    foreach var "[lsort [array names Diag]]" {
		regexp {^[^,]*,Comment} $var v
		if { [info exists v] } {
		    regexp {^([^,]*)} $v n
		    lappend ListOfDiags $n
		    unset v
		}
	    }
	    set l .l.lb.list
	    $l delete 0 end
	    $l insert end "*****        New Diagram       "
	    foreach n "[nsort $ListOfDiags]" {
		if { [info exists db($n,Status)] } { set s $db($n,Status) } else { set s "" }
		set str "[format %4i $n] \[ $Diag($n,Time) \] $Diag($n,Comment)"
		if { $s == "" } {
		    $l insert end "  $str"
		} else {
		    $l insert end "$s$str"
		}
	    }
	    wm deiconify .l
	}
	create {
	    FG_CreateListBox
	}
    }
    if { $cmd != "update" } { set db(mode) "List of Existing Diagrams Printed" }
}

proc FG_CreateListBox {} {

    toplevel .l
    wm title .l "List of Existing Diagrams"
    wm iconify .l
    
    frame .l.lb
    set ll .l.lb.list
    eval { listbox $ll \
	    -xscrollcommand [list .l.lb.sx set]   \
	    -yscrollcommand [list .l.lb.sy set] } \
	    -width 80 -height 15 -setgrid true -selectmode multiple
    scrollbar .l.lb.sx -orient horizontal \
	    -command [list $ll xview]
    scrollbar .l.lb.sy -orient vertical \
	    -command [list $ll yview]
    pack .l.lb.sx -side bottom -fill x
    pack .l.lb.sy -side left   -fill y
    pack $ll -in .l.lb -side left -fill both -expand true

    set wf .l
    set rlf sunken
    set bd 2
    frame $wf.menu -relief $rlf -bd $bd  
    frame $wf.0 -relief $rlf -bd $bd  
    frame $wf.1 -relief $rlf -bd $bd  
    frame $wf.2 -relief $rlf -bd $bd  
    frame $wf.3 -relief $rlf -bd $bd  
    frame $wf.4 -relief $rlf -bd $bd  
    frame $wf.5 -relief $rlf -bd $bd
    pack  $wf.menu  -expand no -fill x
    pack $wf.0 -expand yes -side bottom -fill both -anchor nw -padx 3 -pady 3
    pack $wf.1 -in $wf.0 -expand yes -padx 1 -pady 1 -fill both
    
    
    menubutton $wf.menu.file -text "File" -menu $wf.menu.file.m -underline 0
    menu $wf.menu.file.m 
    $wf.menu.file.m add command -label "Open File" -underline 5 \
	    -command "FG_LoadDiagList" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "List Diagrams" -underline 0 \
	    -command "FG_ListDiags $wf" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "Save" -underline 0 \
	    -command "FG_SaveDiag {} all" 
    $wf.menu.file.m add command -label "Save as ..." -underline 1 \
	    -command "FG_SaveDiag {} as" 
    $wf.menu.file.m add separator
    $wf.menu.file.m add command -label "Close" -underline 0 \
		                -command "destroy .l" 
    $wf.menu.file.m add command -label "Exit" -underline 0 \
		                -command "Quit" 
        
    
    menubutton $wf.menu.help -text "Help" -menu $wf.menu.help.m -underline 0
    menu $wf.menu.help.m 
    $wf.menu.help.m add command -label "About" -underline 0 -command "Help About"
    
    menubutton $wf.menu.exit -text "Exit" -menu $wf.menu.exit.m -underline 0
    menu $wf.menu.exit.m 
    #        $wf.menu.exit.m add command -label "Exit" -underline 0 -command "TT_MainBox $wf exit"
#    $wf.menu.exit.m add command -label "Quit" -underline 0 -command "Quit"
    
    
    
    tk_menuBar $wf.menu $wf.menu.file \
	    $wf.menu.help $wf.menu.exit
    tk_bindForTraversal $wf $wf.menu $wf.menu.file \
	    $wf.menu.help
    pack $wf.menu.file -side left -padx 1m
    pack $wf.menu.help -side right -padx 1m
    
    button $wf.o -text Open -width 8 -relief raised \
	    -command "FG_OpenSelected $ll"
    button $wf.u -text UnSelect -width 8 -relief raised \
	    -command "Unselect_ListDiags $ll"
    button $wf.d -text Done -width 8 -relief raised \
	    -command "destroy .l"
    button $wf.r -text Remove -width 8 -relief raised \
	    -command "FG_RemoveDiagList $ll"

    pack $wf.o $wf.u $wf.r $wf.d -in $wf.1 -side left -expand yes -padx 8 -pady 8
    pack .l.lb -in $wf -expand yes -fill both

    bind .l <Destroy> {
	set winlist {}
	foreach var  "[winfo children .]" {
	    set winid ""
	    regexp {^.[0-9][0-9]*$}  $var winid
	    if { $winid != "" } { lappend winlist $winid }
	}
	if { [llength $winlist] == 0 } Quit
    }
}

proc FG_OpenSelected {l} {
    global db

    foreach n "[$l curselection]" {
	if { $n != 0 } {
	    set db(diag) "[FG_GetDiagNum [$l get $n]]"
	} else {
	    if { [$l index end] > 1 } {
		set db(diag) "[expr [FG_GetDiagNum [$l get end]]+1]" 
	    } else {
		set db(diag) 1
	    }
	}
	set ww $db(winN)
	set db(ww,diag) $db(diag)
	FG_MainBox {} create
	ShowDiag .$ww
    }
    set db(mode) "Selected Diagrams Opened"
    Unselect_ListDiags $l
}

proc FG_GetDiagNum { s } {
    if { [scan $s %d n] == 0} {
	scan $s %s%d Status n
    }
    return $n
}

proc FG_RemoveDiagList {l} {

    global db Diag
    set rlist "[$l curselection]"
    if { "$rlist" == "" } return
    foreach var "[array names Diag]" {
	regexp {^([^,]*)} $var n
	foreach N "[$l curselection]" {
	    if { $N != 0 } {
		if { "$n" == "[FG_GetDiagNum [$l get $N]]" } {
		    unset Diag($var)
		}
	    }
	}
    }
    FG_ListDiags {} update
    set db(mode) "Selected Diagrams Removed from the List"
}


proc Unselect_ListDiags {l} {
    foreach active "[$l curselection]" {
	$l selection clear $active
    }
}

proc nsort {L} {
    set finished "No"
    while { $finished != "Yes" } {
	set finished "Yes"
	for {set i 1} {$i < [llength $L]} {incr i} {
	    if { [lindex $L [expr $i-1]] > [lindex $L $i] } {
		set L "[lreplace $L [expr $i-1] $i [lindex $L $i] [lindex $L [expr $i-1]]]"
		set finished "No"
	    }
	}
    }
    return $L
}



proc ChooseColor { {w {}} {X ""} {Y ""} {type ""} {id {}} {cmd update}} {
    global db Db

    switch -exact $cmd {
	start {
	    if { $w != {} && $w != ".clr.b.c" } {
		Cancel_SelReg noupdate
		FG_Cancel $w.c noupdate
	    }
	    if { ![winfo exists .clr] } {
		ChooseColor {} "" "" "" {} create
	    } else {
		focus .clr
		wm deiconify .clr
	    }
	}
	update {
	    set icolor $db(linecolor,$type)
	    set db(mode) "Select Color for $type"
	    set newcolor [ tk_chooseColor -initialcolor "$icolor" -title "$type Color" -parent .clr ]
	    if { $newcolor != {} } {
		set Db(linecolor,$type) "$icolor"
		set db(linecolor,$type) "$newcolor"
		ChooseColor .clr.b.c "" "" $type {} Display
		set db(mode) "New Color for $type Selected"
	    } else {
		set db(mode) "Changing Color Cancelled"
	    }
	}
	Reset {
	    foreach var "[array names Db {linecolor,*} ]" {
		set db($var) $Db($var)
		unset Db($var)
		regexp {^linecolor,(.+)} "$var" nn n
		ChooseColor .clr.b.c "" "" $n {} Display
	    }
	    set db(mode) "Old Colors"
	}
	DefaultColors {
	    foreach var "[array names Db {linecolor,*} ]" { unset Db($var) }
	    foreach n "$db(ObjectList)" {
		set db(linecolor,$n) "$db(defaultLineColor)"
		ChooseColor .clr.b.c "" "" $n {} Display
	    }
	    set db(mode) "Default Colors"
	}
	Display {
	    set color $db(linecolor,$type)
	    switch -regexp $type {
		Oval {
		    $w itemconfigure $type -outline "$color"
		}
		"blob|Vertex" {
		    $w itemconfigure $type -outline "$color" -fill $color
		}
		default {
		    $w itemconfigure $type -fill "$color"
		}
	    }
	    
	}
	Done {    
	    foreach n "$db(ObjectList)" {
		foreach var "[array names Db {linecolor,*} ]" { unset Db($var) }
	    }
	    destroy .clr
	    set db(mode) "Colors Selected"
	}
	create {
	    FG_CreateColorListBox
	}
    }
}

proc FG_CreateColorListBox {} {
    global db

    set nObj [llength $db(ObjectList)]
    set bh $db(EditLnClrButtonH)
    set bw $db(EditLnClrButtonW)
    set LnClrH [ expr $bh*$nObj ]
    set LnClrW $db(EditLnColorW)
    set ScrollReg [list 0 0 $LnClrW $LnClrH]
    set ClrLnLngth $db(ClrLnLngth)

    toplevel .clr
    wm title .clr "Edit Line Colors"
    wm iconify .clr

    frame .clr.b
    set cc .clr.b.c
    eval { canvas $cc \
	    -yscrollcommand [list .clr.b.sy set] \
	    -width $db(EditLnColorW) -height $LnClrH -scrollregion $ScrollReg } \
	    -background white -bd 3
    scrollbar .clr.b.sy -orient vertical \
	    -command [list $cc yview]

    set xc [expr ($LnClrW+$bw)/2]
    set xl [expr $xc- ($ClrLnLngth/2)]
    set xr [expr $xc+ ($ClrLnLngth/2)]
    set N 0

    foreach n "$db(ObjectList)" {
	set by [ expr $bh*$N ]
	button .clr.b.$N -text "$n" -padx 3 -pady 3 -command "ChooseColor $cc {} {} $n {} update"
	$cc create window 0 $by -height $bh -width $bw -window .clr.b.$N -anchor nw
	set N [expr $N+1]

	set yc [expr $by+$bh/2]

	switch -regexp $n {
	    "Line|Arrow|Scalar|Fermion|HFermion|Photon|Gluon|Meson|Wboson|line1|arrow1" {
		Draw_Line $cc "$xl $yc $xr $yc" $n $db(linecolor,$n) "ChooseColor"
	    }
	    "Cross|Vertex" {
		Draw_Line $cc "$xc $yc" $n "$db(linecolor,$n)" "ChooseColor"
	    }
	    "Oval|blob" {
		set xo [expr $xc+ ($ClrLnLngth/3)]
		set yo [expr $by+$bh*5/6]
		Draw_Line $cc "$xc $yc $xo $yo" $n "$db(linecolor,$n)" "ChooseColor"
	    }
	    "Text" {
		set id [$cc create text $xl [expr $by+$bh*5/6] -text "ABCD... abcd..." -font "$db(italic-bold-18)" -anchor sw -tag Text -fill $db(linecolor,$n)]
		$cc bind $id <ButtonRelease-1> "ChooseColor $cc {} {} $n {} update"
	    }
	    "Curve" {
		for {set i 0} {$i<=6} {incr i} {
		    lappend points "[expr ($xl*(6-$i)+$xr*$i)/6]" "[expr rand()*$bh+$by]"
		}
		Draw_Line $cc "$points" $n $db(linecolor,$n) "ChooseColor"
	    }
	}
    }


    pack .clr.b.sy -side left   -fill y
    pack $cc -in .clr.b -side left -fill both -expand true

    set wf .clr
    set rlf sunken
    set bd 2
    frame $wf.menu -relief $rlf -bd $bd
    frame $wf.0 -relief $rlf -bd $bd
    frame $wf.1 -relief $rlf -bd $bd
    frame $wf.2 -relief $rlf -bd $bd
    frame $wf.3 -relief $rlf -bd $bd
    frame $wf.4 -relief $rlf -bd $bd
    frame $wf.5 -relief $rlf -bd $bd
    pack  $wf.menu  -expand no -fill x
    pack $wf.0 -expand yes -side bottom -fill both -anchor nw -padx 3 -pady 3
    pack $wf.1 -in $wf.0 -expand yes -padx 1 -pady 1 -fill both


#    menubutton $wf.menu.file -text "File" -menu $wf.menu.file.m -underline 0
#    menu $wf.menu.file.m 
#    $wf.menu.file.m add command -label "Close" -underline 0 \
#		                -command "destroy .clr" 
#    $wf.menu.file.m add command -label "Exit" -underline 0 \
#		                -command "Quit" 


#    menubutton $wf.menu.help -text "Help" -menu $wf.menu.help.m -underline 0
#    menu $wf.menu.help.m 

#    menubutton $wf.menu.exit -text "Exit" -menu $wf.menu.exit.m -underline 0
#    menu $wf.menu.exit.m 
#        $wf.menu.exit.m add command -label "Exit" -underline 0 -command "TT_MainBox $wf exit"
#    $wf.menu.exit.m add command -label "Quit" -underline 0 -command "Quit"


    
#    tk_menuBar $wf.menu $wf.menu.file \
#	    $wf.menu.help $wf.menu.exit
#    tk_bindForTraversal $wf $wf.menu $wf.menu.file \
#	    $wf.menu.help
#    pack $wf.menu.file -side left -padx 1m
#    pack $wf.menu.help -side right -padx 1m
    
#    button $wf.a -text Apply -width 8 -relief raised \
#	    -command "ChooseColor {} {} {} {} {} Apply"


    button $wf.d -text Done -width 8 -relief raised \
	    -command "ChooseColor {} {} {} {} {} Done"
    button $wf.r -text "Reset" -width 8 -relief raised \
	    -command "ChooseColor {} {} {} {} {} Reset"
    button $wf.t -text "Default" -width 8 -relief raised \
	    -command "ChooseColor {} {} {} {} {} DefaultColors"
 
    pack $wf.r  $wf.t $wf.d -in $wf.1 -side left -expand yes -padx 8 -pady 8
    pack .clr.b -in $wf -expand yes -fill both

    bind .clr <Destroy> {
	set db(mode) "Edit Line Colors Cancelled"
    }

    wm deiconify .clr
    set db(mode) "Edit Line Colors"

}
