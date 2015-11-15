global diag db
set dir /usr/share/FG/
set db(InstallDir) $dir
set db(cnf) feynmang.cnf
set db(FGversion) "4.02"


source $dir$db(cnf)
if { [file exists $db(cnf) ] }  {
    source $db(cnf)
}


scan "fg_win.tcl fg_edit.tcl fg_binding.tcl fg_drawl.tcl fg_drawa.tcl   \
      fg_events.tcl fg_dialog.tcl fg_regs.tcl fg_io.tcl fg_wtext.tcl    \
      fg_tools.tcl"   \
          %s%s%s%s%s%s%s%s%s%s%s  \
      win           edit        binding        drawl        drawa       \
      events        dialog        regs        io        wtext           \
      tools

source     $dir$win
source     $dir$edit
source     $dir$binding
source     $dir$drawl
source     $dir$drawa
source     $dir$events
source     $dir$dialog
source     $dir$regs
source     $dir$io
source     $dir$wtext
source     $dir$tools

wm withdraw .
FG_rc read
FG_StartBox
after $db(StartDelay)
destroy .logo

if { $argc != 0 } {
    set inFile [lindex $argv 0]
    if { [file exists $inFile] && [file size $inFile] !=0 && \
	    [file readable $inFile] } {
	source $inFile
	set db(DiagFN) $inFile
	FG_ListDiags {} update
    } else {
	FG_MainBox {} create
	set db(mode) "Error opening file $inFile"
    }
}  else {
    FG_MainBox {} create
}


