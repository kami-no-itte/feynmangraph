proc FG_LoadOrigConfig { } {
    global db diag
    set config $db(InstallDir)$db(cnf)
    source $config
    if [info exists db(FGconfigVersion)] {
	if [ expr $db(FGconfigVersion) == $db(FGversion) ] {
	    set configVer "ok"
	}
    }
    if ![info exists configVer] {
	ConfigVersionWarning
    }
    set db(mode) "Original Configuration Loaded"
}

proc FG_LoadConfig { } {
    global db diag

    if { [info exists db(ConfigFN)] } {
	set config [file tail $db(ConfigFN)]
	set indir [file dirname $db(ConfigFN)]
    } else {
	set config $db(cnf)
	set indir [pwd]
    }
    set db(mode) "Browsing Files for Config ..."

    set filetypes {{{Config} {.cnf}} {{All Files} *}}
    set file [tk_getOpenFile -title " Load Diagram " \
	    -initialfile $config -initialdir $indir\
	    -filetypes $filetypes -defaultextension ".dia"]
    if { $file == "" } {
	set db(mode) "Load Cancelled"
	return
    }
    source $file
    set db(ConfigFN) $file

    set db(mode) "Configuration Loaded"
}

proc FG_rc { cmd } {
    global db
    
    set fn [file nativename ~/$db(FGrc)]

    switch "$cmd" {
	read {
	    if { [file readable $fn] } {
		source $fn
	    }
	}
	write {
	    catch "set f [open $fn w]"
	    if { [file writable $fn] } {
		foreach type "$db(ObjectList)"  {
		    puts $f "set db(linecolor,$type) \"$db(linecolor,$type)\""
		}	
		close $f
	    }
	}
    }
}

proc FG_CreateDiagConfig {w} {

    global db diag Diag
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)
    set d $diagN

    if { [info exists diag($d,Comment)]} {
	set Diag($d,Comment) $diag($d,Comment)
    } else {
	set Diag($d,Comment) ""
    }
    set db($d,Status) "*"
    set Diag($d,Time) "[clock format [clock seconds] -format {%b %d %y  %T}]"
    scan "[winfo height $w.c] [winfo width $w.c]" %d%d Diag($d,HScreenH) Diag($d,HScreenW)
    foreach type "$db(ObjectList)" {
	set Diag($d,$type) ""
	switch -glob $type {
	    *Fermion {
		foreach id "[$w.c find withtag $type]" {
		    set coords "[$w.c coords $id]"
		    set conf "[$w.c itemconfigure $id]"
                    set i [lsearch $conf {-smooth {*} {*} * bezier}]
                    if {$i >= 0} {
                        set conf [lreplace $conf $i $i {-smooth {} {} 0 true}]
                    }
		    set tplace "[lsearch $conf {-tags {*} {*} {*} {*}}]"
		    set o "[lindex [lindex [lindex $conf $tplace] 4] 0]"
		    set n "[lindex [lindex [lindex $conf $tplace] 4] 2]"
		    set t "[lindex [lindex [lindex $conf $tplace] 4] 3]"
#puts "o $o   n $n   t $t"
		    set mconf  [lreplace  $conf $tplace $tplace]
		    set fconf ""
		    foreach confitem "$mconf" {
			append fconf "[lindex $confitem 0] [list [lindex $confitem 4]]"
			append fconf " "
		    }
		    set tmp($n,$t) "$o [$w.c coords $id] $fconf"
		    set listn($n) ""
		}
		foreach n "[array names listn]"  {
		    lappend Diag($d,$type) "[list $tmp($n,a) $tmp($n,b)]"
		    unset listn($n)
		}
	    }
	    * {
		foreach id "[$w.c find withtag $type]" {
		    set coords "[$w.c coords $id]"
		    set conf "[$w.c itemconfigure $id]"
                    set i [lsearch $conf {-smooth {*} {*} * bezier}]
                    if {$i >= 0} {
                        set conf [lreplace $conf $i $i {-smooth {} {} 0 true}]
                    }
		    set tplace "[lsearch $conf {-tags {*} {*} {*} {*}}]"
		    set o "[lindex [lindex [lindex $conf $tplace] 4] 0]"
		    set n "[lindex [lindex [lindex $conf $tplace] 4] 2]"
		    set mconf  [lreplace  $conf $tplace $tplace]
		    set fconf ""
		    foreach confitem "$mconf" {
			set l0 [lindex $confitem 0]
			if { [scan "[lindex $confitem 4]" "@%s" stipplefile] > 0 } {
			    scan  $l0 "-%s" stippleconfitem
			    set l4 "@\$db(InstallDir)\$db($stippleconfitem,$type)"
			} else {
			    set l4 [list [lindex $confitem 4]]
			}
			append fconf "$l0 $l4"
			append fconf " "
		    }
		    lappend tmp($n) "$o $coords $fconf" 
		    set listn($n) ""
		}
		foreach n "[array names listn]"  {
		    lappend Diag($d,$type) "$tmp($n)"
		    unset listn($n)
		}
            }
	}
    }
    if { [winfo exists .l] } "FG_ListDiags $w update"
#    set db(mode) "Current Diagram Updated"
}

proc ShowDiag {w} {

    global db diag Diag
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)
    set d $diagN

    FG_StopRegDraw $w.c noupdate
    FG_Cancel $w.c

    catch {eval $w.c delete [$w.c find all]} 

    if { [info exists Diag($d,Comment)]} {
	set diag($d,Comment) $Diag($d,Comment)
	set db($ww,Comment) $Diag($d,Comment)
    } else {
	set diag($d,Comment) ""
	set db($ww,Comment) ""
    }
    set db($d,Status) "-"
    if { $db($ww,Comment) != "" } {
	wm title $w "FG: $db($ww,Comment)"
    }
    if { ![info exists Diag($d,HScreenH)] } { set Diag($d,HScreenH) $diag(HScreenH) }
    if { ![info exists Diag($d,HScreenW)] } { set Diag($d,HScreenW) $diag(HScreenW) }

    $w.c configure -height $Diag($d,HScreenH) -width $Diag($d,HScreenW)


    foreach type "$db(ObjectList)" {
	if { [info exists Diag($d,$type)] } {
	    if { $Diag($d,$type) != "" } {
		switch -glob $type {
		    *Fermion {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set o1 [lindex [lindex $obj 0] 0]
			    set o2 [lindex [lindex $obj 1] 0]
			    set id1 [eval  {$w.c create} [lindex $obj 0] {-tags "$o1 $tag a"} ]
			    set id2 [eval  {$w.c create} [lindex $obj 1] {-tags "$o2 $tag b"} ]
			    set id "[list $id1 $id2]"	
			    $w.c bind $id1 <1> "FieldEvent %W %x %y $type {$id}"
			    $w.c bind $id2 <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		    Cross {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set id1 [eval  {$w.c create} [lindex $obj 0] {-tags "line $tag"} ]			
			    set id2 [eval  {$w.c create} [lindex $obj 1] {-tags "line $tag"} ]	
			    set id "[list $id1 $id2]"	
			    $w.c bind $id1 <1> "FieldEvent %W %x %y $type {$id}"
			    $w.c bind $id2 <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		    Meson {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set listid ""
			    foreach part "$obj" {
				set id [eval  {$w.c create} $part {-tags "line $tag"} ]
				lappend listid $id
			    }
			    foreach id "$listid" {	
				$w.c bind $id <1> "FieldEvent %W %x %y $type {$listid}"
			    }
			}
		    }
		    Oval {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set id [eval  {$w.c create} [lindex $obj 0] {-tags "oval $tag"} ]
			    $w.c bind $id <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		    blob {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set conf [lindex $obj 0]
			    set stplace [lsearch $conf "-stipple"]
			    if {[scan [lindex $conf [expr $stplace+1]] "@%s" stfile]>0} {
				if { ![file exists $stfile] } {
				    set conf [lreplace $conf \
					    [expr $stplace+1] [expr $stplace+1] \
					    @$db(InstallDir)$db(stipple,blob)]
				}
			    }
			    set id [eval  {$w.c create} $conf {-tags "oval $tag"} ]
			    $w.c bind $id <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		    Vertex {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set id [eval  {$w.c create} [lindex $obj 0] {-tags "oval $tag"} ]			
			    $w.c bind $id <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		    Text {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set id [eval {$w.c create}  [lindex $obj 0] {-tags "text $tag"}]
			    $w.c bind $id <1> "FieldEvent %W %x %y Text $id"
			    $w.c bind $id <Double-1> {
				SetSel %W Text "[%W find withtag current]" 
				DoubleFieldEvent  %W %x %y Text $db(Selid)
			    }
			}
			focus .
		    }
		    * {
			foreach obj  $Diag($d,$type) {
			    set tag "$type t[incr db(tagN)]"
			    set o [lindex [lindex $obj 0] 0]
			    set id [eval  {$w.c create}   [lindex $obj 0] {-tags "$o $tag"}]
			    $w.c bind $id <1> "FieldEvent %W %x %y $type {$id}"
			}
		    }
		}
	    }
	}
    }
    if { [winfo exists .l] } "FG_ListDiags $w update"
    Grid $w.c Draw
#    set db(mode) "Diagram Shown"
}

proc FG_SaveDiag {w {cmd {}}} {                     
    global db Diag

    if { $w != {} } {
	FG_Cancel $w.c
	regexp {^\.([^.]*)} $w m ww 
	set diagN $db($ww,diag)

#	FG_CreateDiagConfig $w
    }
#    if { $cmd == "current" } return

    if { ![info exists db(DiagFN)] } {
	set db(DiagFN) $db(DiagDefaultFN)
    }

    if { $cmd == "as" } {
	set db(mode) "Browsing Files for Saving Diagrams ..."
	set infile [file tail $db(DiagFN)]
	set indir  [file dirname $db(DiagFN)]
	if { $indir == "" || $indir == "."} { set indir [pwd] }
	set filetypes {{{Feynman Diagram} {.dia}} {{All Files} *}}
	set file [tk_getSaveFile -title "Save Diagrams" \
		-initialfile $infile -initialdir $indir \
		-filetypes $filetypes -defaultextension ".dia"]
	if { $file == "" } {
	    set db(mode) "File Saving Cancelled"
	    return
	} 
    } else {
	set file $db(DiagFN)
    }

    set f [open $file w]
    if { $f == "" } {
	set db(mode) "File Saving FAILED !"
	return
    } 
    
    set db(DiagFN) $file

    switch -exact $cmd {
	single {
	    foreach var "[lsort [array names Diag {[0-9]*,*} ]]"  {
		regexp {^([^,]*)} $var n
		if { $n == $diagN } {
		    puts $f "set Diag($var) \"$Diag($var)\""
#		    puts "set Diag($var) \"$Diag($var)\""
		}
	    }
	    set db(mode) "Diag $diagN Saved, File: $file"
	}
	default {
	    foreach var "[lsort [array names Diag {[0-9]*,*} ]]"  {
		puts $f "set Diag($var) \"$Diag($var)\""
#		puts "set Diag($var) \"$Diag($var)\""
		regexp {([0-9]*),} $var m d
                if { [info exists d] } { set db($d,Status) "" }
	    }
	    if { [winfo exists .l] } "FG_ListDiags $w update"
	    set db(mode) "Diagrams Saved, File: [ file tail $file ]"
	}
    }
    close $f
}                                                                  
                                                   
proc FG_SaveCfg {w} {                      
    global db diag
    FG_Cancel $w.c
    
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)
    #	FG_CreateDiagConfig $w            
    set hl $diagN
    if { [file exists feynmang.cfg] } {
	exec mv feynmang.cnf feynmang.cnf.BAK
    }
    set f [open feynmang.cfg w]
    foreach var "[lsort "[array names db ]"]"  {
	puts $f "set db($var) \"$db($var)\""
    }	
    foreach var "[lsort "[array names diag {[0]*,*} ]"]"  {
	puts $f "set Diag($var) \"$Diag($var)\""
    }
    close $f
    
    set db(mode) "Configuration Saved"
}

proc FG_LoadDiag {w} {
    global db diag Diag
    FG_Cancel $w.c
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)


    if { ![info exists db(DiagFN)] } {
	set db(DiagFN) $db(DiagDefaultFN)
    }
    set db(mode) "Browsing Files for Diagrams ..."

    set infile [file tail $db(DiagFN)]
    set indir  [file dirname $db(DiagFN)]
    if { $indir == "" || $indir == "." } { set indir [pwd] }
    set filetypes {{{Feynman Diagram} {.dia}} {{All Files} *}}
    set file [tk_getOpenFile -title " Load Diagram " \
	    -initialfile $infile -initialdir $indir\
	    -filetypes $filetypes -defaultextension ".dia"]
    if { $file == "" } {
	set db(mode) "Load Cancelled"
	return
    }
    source $file
    set db(DiagFN) $file

    FG_ListDiags {} update    
    set db(mode) "File $db(DiagFN) Loaded"
    ShowDiag $w
} 

proc FG_LoadDiagList {} {
    global db diag Diag

    if { ![info exists db(DiagFN)] } {
	set db(DiagFN) $db(DiagDefaultFN)
    }
    set db(mode) "Browsing Files for Diagrams ..."
    set dfile "$db(DiagFN)"
    set infile [file tail $db(DiagFN)]
    set indir  [file dirname $db(DiagFN)]
    if { $indir == "" || $indir == "." } { set indir [pwd] }
    set filetypes {{{Feynman Diagram} {.dia}} {{All Files} *}}
    set file [tk_getOpenFile -title "Load Diagram" \
	    -initialfile $infile -initialdir $indir \
	    -filetypes $filetypes -defaultextension ".dia"]
    if { $file == "" } {
	set db(mode) "Load Cancelled"
	return
    }
    source $file
    set db(DiagFN) $file
#    set db(mode) "File $db(DiagFN) Loaded"
    FG_ListDiags {} update        
} 

proc FG_LoadImage {w} {
    global db diag
    FG_Cancel $w.c
    regexp {^\.([^.]*)} $w m ww 
    set diagN $db($ww,diag)
#puts "Load Image"
    if {![catch {format %d $diagN}]} {
	set h $diagN
#	catch {eval $w.c delete [$w.c find all]}
	if { [info exists diag($h,ImageFN)] } {
	    set db(id,Image) [image create photo pict -file $diag($h,ImageFN)]
	    $w.c create image 0 0 -image $db(id,Image) -tags pict -anchor nw
	}
	if { [info exists diag($h,Par)] } {
	    set db(par) $diag($h,Par)
	}
    } 
    set db(mode) "Image Loaded"
} 
                                                                 
proc FG_OpenFile {w p} {
    global db diag
    FG_Cancel $w.c
       

    set db(mode) "Browsing Files for Image ..."

    if { ![info exists db(imageFN)] } {
	set db(imageFN) ""
	set infile ""
	set indir [pwd]
    } else {
	set dfile "$db(imageFN)"
	set infile [file tail $db(imageFN)]
	set indir  [file dirname $db(imageFN)]
    }
    
    set filetypes {{{GIF Image} {.gif}} {{PPM image} {.ppm}} {{All Files} *}}
    set file [tk_getOpenFile -title " Image " \
	    -initialdir $indir -initialfile $infile\
	    -filetypes $filetypes -defaultextension ".gif"]
    if { $file != "" } {
#   puts "FG_OpenFile"
	incr db(tagN)
	set db(imageFN) $file
	set tag "Image t$db(tagN)"
#	catch {eval $w.c delete [$w.c find all]}
	set db(id,Image) [image create photo pict$db(tagN) -file $file]
	set id [eval {$w.c create image} 0 0 -image $db(id,Image) {-tags "image $tag" -anchor nw}]
	$w.c lower Image
	$w.c bind $id <1> "FieldEvent %W %x %y Image {$id}"	
	set db(mode) "$file"
    } else {
	set db(mode) "Load Cancelled"
    }
}


proc FG_RemoveDiag {w} {

    global db Diag
    regexp {^\.([^.]*)} $w m ww 
    foreach var "[array names Diag]" {
	regexp {^([^,]*)} $var n
	if { $n == $db($ww,diag) } {
	    unset Diag($var)
	}
    }
    foreach var  "[winfo children .]" {
	set winid ""
	regexp {^.[0-9][0-9]*$}  $var winid
	if { $winid != "" } { lappend winlist $winid }
    }
    if { [winfo exists .l] || [llength $winlist] == 1 } "FG_ListDiags $w update"
    FG_MainBox $w destroy
    set db(mode) "Diagram # $db($ww,diag) Removed from the List"
}

proc FG_Print {w} {
    global db 
    regexp {^\.([^.]*)} $w m ww

    if { [info exists db(DiagFN)] } {
	regexp {(.+).dia}  $db(DiagFN) m FN
	if { ![info exists FN] }  {set FN $db(DiagFN)}
    } else {
	regexp {(.+).dia}  $db(DiagDefaultFN) m FN
	if { ![info exists FN] }  {set FN $db(DiagDefaultFN)}
    }
	
    append psfile "$FN" "_$db($ww,diag)" ".ps"
    set db(mode) "Browsing Files for PostScript ..."
    set infile [file tail $psfile]

    if { [info exists db(PostScriptDir)] } {
	set indir $db(PostScriptDir)
    } else {
	set indir [file dirname $psfile]
    }

    if { $indir == "" || $indir == "."} { set indir [pwd] }

    set filetypes {{{PostScript} {.ps}} {{All Files} *}}
    set file [tk_getSaveFile -title " Export PostScript to File ... " \
	    -initialfile $infile -initialdir $indir \
	    -filetypes $filetypes -defaultextension ".ps"]
    if { $file == "" } {
	set db(mode) "Generating PostScript Cancelled"
	return
    }
    Grid $w Remove
    $w postscript -colormode color -file $file -pageanchor nw \
	    -pagex 0.i -pagey 11.i
    set db(PostScriptDir) [file dirname $file]
    Grid $w Draw
    set db(mode) "PS-file [ file tail $file ] Generated !"
}


















