#!/usr/bin/wish
# Copyright (c) 1997-1999 Miller Puckette.
# For information on usage and redistribution, and for a DISCLAIMER OF ALL
# WARRANTIES, see the file, "LICENSE.txt," in this distribution.

# changed by Thomas Musil 09.2001
# between "pdtk_graph_dialog -- dialog window for graphs"
# and "pdtk_array_dialog -- dialog window for arrays"
# a new dialogbox was inserted, named:
# "pdtk_iemgui_dialog -- dialog window for iem guis"
#
# all this changes are labeled with #######iemlib##########

# set pd_nt (bad name) 0 for unix, 1 for microsoft, and 2 for Mac OSX.
if { $tcl_platform(platform) == "windows" }  {
    set pd_nt 1
    set defaultFontFamily {Bitstream Vera Sans Mono}
    set defaultFontWeight normal
    font create menuFont -family Tahoma -size -11
} elseif { $tcl_platform(os) == "Darwin" } {  
    set pd_nt 2
    set defaultFontFamily Monaco
    set defaultFontWeight normal
} else { 
    set pd_nt 0
    set defaultFontFamily Courier
    set defaultFontWeight bold
}        

# start Pd-extended font hacks -----------------------------

# Pd-0.39.2-extended hacks to make font/box sizes the same across platform
# puts stderr "tk scaling is [tk scaling]"
# tk scaling 1

# this font is for the Pd Window console text
font create console_font -family $defaultFontFamily -size -12 \
    -weight $defaultFontWeight
# this font is for text in Pd windows
font create text_font -family {Times} -size -14 -weight normal
# for text in Properties Panels and other panes
font create highlight_font -family $defaultFontFamily -size -14 -weight bold

# end Pd-extended font hacks -----------------------------


# Tearoff is set to true by default:
set pd_tearoff 1

# jsarlo
set pd_array_listview_pagesize 1000
set pd_array_listview_id(0) 0
set pd_array_listview_entry(0) 0
set pd_array_listview_page(0) 0
# end jsarlo

if {$pd_nt == 1} {
    global pd_guidir
    global pd_tearoff
    set pd_gui2 [string range $argv0 0 [expr [string last \\ $argv0 ] - 1]]
    regsub -all \\\\ $pd_gui2 / pd_gui3
    set pd_guidir $pd_gui3/..
    load $pd_guidir/bin/pdtcl.dll
    set pd_tearoff 1
}

if {$pd_nt == 2} {
# turn on James Tittle II's fast drawing
    set tk::mac::useCGDrawing 1
# anti-alias all lines that need it
    set tk::mac::CGAntialiasLimit 2
    global pd_guidir
    global pd_tearoff
    set pd_gui2 [string range $argv0 0 [expr [string last / $argv0 ] - 1]]
    set pd_guidir $pd_gui2/..
    load $pd_guidir/bin/libPdTcl.dylib
    set pd_tearoff 0
    global pd_macready
    set pd_macready 0
    global pd_macdropped
    set pd_macdropped ""
    # tk::mac::OpenDocument is called with the filenames put into the 
    # var args whenever docs are either dropped on the Pd.app icon or 
    # opened from the Finder.
    # It uses menu_doc_open so it can handles numerous file types.
    proc tk::mac::OpenDocument {args} {
        global pd_macready pd_macdropped
        foreach file $args {
            if {$pd_macready != 0} {
                pd [concat pd open [pdtk_enquote [file tail $file]] \
                    [pdtk_enquote  [file dirname $file]] \;]
                    menu_doc_open [file dirname $file] [file tail $file]
            } else {
                set pd_macdropped $args
            }
        }
    }
}

# hack so you can easily test-run this script in linux... define pd_guidir
# (which is normally defined at startup in pd under linux...)

if {$pd_nt == 0} {
    if {! [info exists pd_guidir]} {
        global pd_guidir
        puts stderr {setting pd_guidir to '.'}
        set pd_guidir .
    }
}

set pd_deffont {courier 12 bold}

set help_top_directory $pd_guidir/doc

# it's unfortunate but we seem to have to turn off global bindings
# for Text objects to get control-s and control-t to do what we want for
# "text" dialogs below.  Also we have to get rid of tab's changing the focus.

bind all <Key-Tab> ""
bind all <<PrevWindow>> ""
bind Text <Control-t> {}
bind Text <Control-s> {}
# puts stderr [bind all]

################## set up main window #########################
# the menus are instantiated here for the main window
# for the patch windows, they are created by pdtk_canvas_new
menu .mbar

frame .controls
pack .controls -side top -fill x
menu .mbar.file -tearoff $pd_tearoff
.mbar add cascade -label "File" -menu .mbar.file
menu .mbar.find -tearoff $pd_tearoff
.mbar add cascade -label "Find" -menu .mbar.find
menu .mbar.windows -postcommand [concat pdtk_fixwindowmenu] -tearoff $pd_tearoff
menu .mbar.audio -tearoff $pd_tearoff
if {$pd_nt != 2} {
    .mbar add cascade -label "Windows" -menu .mbar.windows
    .mbar add cascade -label "Media" -menu .mbar.audio
    menu .mbar.help -tearoff $pd_tearoff
    .mbar add cascade -label "Help" -menu .mbar.help
} else {
    menu .mbar.apple -tearoff 0
    .mbar add cascade -label "Apple" -menu .mbar.apple 
# arrange menus according to Apple HIG
    .mbar add cascade -label "Media" -menu .mbar.audio
    .mbar add cascade -label "Window" -menu .mbar.windows
    menu .mbar.help -tearoff $pd_tearoff
    .mbar add cascade -label "Help" -menu .mbar.help
}

# fix menu font size on Windows with tk scaling = 1
if {$pd_nt == 1} {
    .mbar.file configure -font menuFont
    .mbar.find configure -font menuFont
    .mbar.windows configure -font menuFont
    .mbar.audio configure -font menuFont
    .mbar.help configure -font menuFont
}

set ctrls_audio_on 0
set ctrls_meter_on 0
set ctrls_inlevel 0
set ctrls_outlevel 0

frame .controls.switches
checkbutton .controls.switches.audiobutton -text {compute audio} \
    -variable ctrls_audio_on \
    -command {pd [concat pd dsp $ctrls_audio_on \;]}

checkbutton .controls.switches.meterbutton -text {peak meters} \
    -variable ctrls_meter_on \
    -command {pd [concat pd meters $ctrls_meter_on \;]}

pack .controls.switches.audiobutton .controls.switches.meterbutton \
     -side top -anchor w

frame .controls.inout
frame .controls.inout.in
label .controls.inout.in.label -text IN
entry .controls.inout.in.level -textvariable ctrls_inlevel -width 3
button .controls.inout.in.clip -text {CLIP} -state disabled
pack .controls.inout.in.label .controls.inout.in.level \
      .controls.inout.in.clip -side top -pady 2

frame .controls.inout.out
label .controls.inout.out.label -text OUT
entry .controls.inout.out.level -textvariable ctrls_outlevel -width 3
button .controls.inout.out.clip -text {CLIP} -state disabled
pack .controls.inout.out.label .controls.inout.out.level \
      .controls.inout.out.clip -side top -pady 2

button .controls.dio -text "DIO\nerrors" \
    -command {pd [concat pd audiostatus \;]}
button .controls.clear -text "clear\nprintout" \
    -command {.printout.text delete 0.0 end}

pack .controls.inout.in .controls.inout.out -side left -padx 6
pack .controls.inout -side left -padx 14
pack .controls.switches -side left
pack .controls.dio -side left -padx 20
pack .controls.clear -side right -padx 6

frame .printout
text .printout.text -relief raised -bd 2 -font console_font \
    -yscrollcommand ".printout.scroll set" -width 80
# .printout.text insert end "\n\n\n\n\n\n\n\n\n\n"
scrollbar .printout.scroll -command ".printout.text yview"
pack .printout.scroll -side right -fill y
pack .printout.text -side left -fill both -expand 1
pack .printout -side bottom -fill both -expand 1

proc pdtk_post {stuff} {
    .printout.text insert end $stuff
    .printout.text yview end-2char
}

proc pdtk_standardkeybindings {id} {
    global pd_nt
    bind $id <Control-Key> {pdtk_pd_ctrlkey %W %K 0}
    bind $id <Control-Shift-Key> {pdtk_pd_ctrlkey %W %K 1}
    if {$pd_nt == 2} {
        bind $id <Mod1-Key> {pdtk_canvas_ctrlkey %W %K 0}
        bind $id <Mod1-Shift-Key> {pdtk_canvas_ctrlkey %W %K 1}
    }
}

pdtk_standardkeybindings .

wm title . "Pd"
. configure -menu .mbar -width 200 -height 150

# Intercept closing the main pd window: MP 20060413:
wm protocol . WM_DELETE_WINDOW menu_quit

############### set up global variables ################################

set untitled_number 1
set untitled_directory [pwd]
set saveas_client doggy
set pd_opendir $untitled_directory
set pd_savedir $untitled_directory
set pd_undoaction no
set pd_redoaction no
set pd_undocanvas no

################ utility functions #########################

# enquote a string to send it to a tcl function
proc pdtk_enquote {x} {
    set foo [string map {"," "" ";" "" \" ""} $x]
    set foo2 [string map {" " "\\ "} $foo]
    concat $foo2
}

#enquote a string to send it to Pd.  Blow off semi and comma; alias spaces
#we also blow off "{", "}", "\" because they'll just cause bad trouble later.
proc pdtk_unspace {x} {
    set y [string map {" " "_" ";" "" "," "" "{" "" "}" "" "\\" ""} $x]
    if {$y == ""} {set y "empty"}
    concat $y
}

#enquote a string for preferences (command strings etc.)
proc pdtk_encodedialog {x} {
    concat +[string map {" " "+_" "$" "+d" ";" "+s" "," "+c" "+" "++"} $x]
}

proc pdtk_debug {x} {
    tk_messageBox -message $x -type ok
}

proc pdtk_watchdog {} {
    pd [concat pd watchdog \;]
    after 2000 {pdtk_watchdog}
}

proc pdtk_ping {} {
    pd [concat pd ping \;]
}

##### routine to ask user if OK and, if so, send a message on to Pd ######
proc pdtk_check {canvas x message default} {
    global pd_nt
    if {$pd_nt == 1} {
        set answer [tk_messageBox -message $x -type yesno -default $default \
            -icon question]
    } else {
        set answer [tk_messageBox -message $x -type yesno -default $default \
            -parent $canvas -icon question]
    }    
    if {! [string compare $answer yes]}  {pd $message}
}

set menu_windowlist {} 

proc pdtk_fixwindowmenu {} {
    global menu_windowlist
    .mbar.windows delete 0 end
    foreach i $menu_windowlist {
        .mbar.windows add command -label [lindex $i 0] \
            -command [concat menu_domenuwindow [lindex $i 1]]
        menu_fixwindowmenu [lindex $i 1]
    }
}

####### Odd little function to make better Mac accelerators #####

proc accel_munge {acc} {
    global pd_nt

    if {$pd_nt == 2} {
        if [string is upper [string index $acc end]] {
            return [format "%s%s" "Shift+" \
                        [string toupper [string map {Ctrl Meta} $acc] end]]
        } else {
            return [string toupper [string map {Ctrl Meta} $acc] end]
        }
    } else {
        return $acc
    }
}



###############  the "New" menu command  ########################
proc menu_new {} {
    global untitled_number
    global untitled_directory
    pd [concat pd filename Untitled-$untitled_number $untitled_directory \;]
    pd {
        #N canvas;
        #X pop 1;
    }
    set untitled_number [expr $untitled_number + 1]
}

################## the "Open" menu command #########################

proc menu_open {parent} {
    global pd_opendir
    set filename [tk_getOpenFile -defaultextension .pd -parent $parent\
        -filetypes { {{pd files} {.pd}} {{max files} {.pat}}} \
        -initialdir $pd_opendir]
    if {$filename != ""} {open_file $filename}
}

proc open_file {filename} {
    global pd_opendir
    set directory [string range $filename 0 [expr [string last / $filename] - 1]]
    set pd_opendir $directory
    set basename [string range $filename [expr [string last / $filename] + 1] end]
    if {[string last .pd $filename] >= 0} {
        pd "pd open [pdtk_enquote $basename] [pdtk_enquote $directory] ;"
    }
}

catch {
    package require tkdnd
    dnd bindtarget . text/uri-list <Drop> {
        foreach file %D {open_file $file}
    }
}

################## the "Message" menu command #########################
proc menu_send {} {
    toplevel .sendpanel
    entry .sendpanel.entry -textvariable send_textvariable
    pack .sendpanel.entry -side bottom -fill both -ipadx 100
    .sendpanel.entry select from 0
    .sendpanel.entry select adjust end
    bind .sendpanel.entry <KeyPress-Return> {
        pd [concat $send_textvariable \;]
    }
    pdtk_standardkeybindings .sendpanel.entry
    focus .sendpanel.entry
}

################## the "Quit" menu command #########################
proc menu_really_quit {} {pd {pd quit;}}

proc menu_quit {} {pd {pd verifyquit;}}

######### the "Pd" menu command, which puts the Pd window on top ########
proc menu_pop_pd {} {raise .}

######### the "audio" menu command  ###############
proc menu_audio {flag} {pd [concat pd dsp $flag \;]}

######### the "reselect" menu command ################
proc menu_reselect {name} {pd [concat $name reselect \;]}

######### the "documentation" menu command  ###############

set doc_number 1

# open text docs in a Pd window
proc menu_opentext {filename} {
    global doc_number
    global pd_guidir
    global pd_myversion
    set name [format ".help%d" $doc_number]
    toplevel $name
    text $name.text -relief raised -bd 2 -font text_font \
        -yscrollcommand "$name.scroll set" -background white
    scrollbar $name.scroll -command "$name.text yview"
    pack $name.scroll -side right -fill y
    pack $name.text -side left -fill both -expand 1
    
    set f [open $filename]
    while {![eof $f]} {
        set bigstring [read $f 1000]
        regsub -all PD_BASEDIR $bigstring $pd_guidir bigstring2
        regsub -all PD_VERSION $bigstring2 $pd_myversion bigstring3
        $name.text insert end $bigstring3
    }
    close $f
    set doc_number [expr $doc_number + 1] 
}

# open HTML docs from the menu using the OS-default HTML viewer
proc menu_openhtml {filename} {
    global pd_nt         

    if {$pd_nt == 0} {
        foreach candidate \
            { gnome-open xdg-open sensible-browser iceweasel firefox mozilla \
              galeon konqueror netscape lynx } {
                  set browser [lindex [auto_execok $candidate] 0]
                  if {[string length $browser]} {
                         puts stderr [format "%s %s" $browser $filename]
                         exec -- sh -c [format "%s %s" $browser $filename] &
                         break
                     }
                 }
    } elseif {$pd_nt == 2} {
        puts stderr [format "open %s" $filename]
            exec sh -c [format "open %s" $filename]
    } else {
        exec rundll32 url.dll,FileProtocolHandler \
            [format "file://%s" $filename] &
    }
}

proc menu_doc_open {subdir basename} {
    global pd_guidir
 
    set dirname $pd_guidir/$subdir

    if {[regexp ".*\.(txt|c)$" $basename]} {
        menu_opentext $dirname/$basename
    } elseif {[regexp ".*\.html?$" $basename]} {
                  menu_openhtml $dirname/$basename
    } else {
        pd [concat pd open [pdtk_enquote $basename] \
                [pdtk_enquote $dirname] \;]
    }
}


################## help browser and support functions #########################
proc menu_doc_browser {dir} {
        global .mbar
        if {![file isdirectory $dir]} {
                puts stderr "menu_doc_browser non-directory $dir\n"
        }
        if { [winfo exists .help_browser.frame] } {
                raise .help_browser
        } else {
                toplevel .help_browser -menu .mbar
                wm title .help_browser "Pd Documentation Browser"
                frame .help_browser.frame
                pack .help_browser.frame -side top -fill both
                doc_make_listbox .help_browser.frame $dir 0
         }
    }

proc doc_make_listbox {base dir count} {
        # check for [file readable]?
        #if { [info tclversion] >= 8.5 } {
                # requires Tcl 8.5 but probably deals with special chars better
#               destroy {expand}[lrange [winfo children $base] [expr {2 * $count}] end]
        #} else {
                if { [catch { eval destroy [lrange [winfo children $base] \
                                                                                [expr { 2 * $count }] end] } \
                                  errorMessage] } {
                        puts stderr "doc_make_listbox: error listing $dir\n"
                }
        #}
        # exportselection 0 looks good, but selection gets easily out-of-sync
        set current_listbox [listbox "[set b "$base.listbox$count"]-list" -yscrollcommand \
                                                         [list "$b-scroll" set] -height 20 -exportselection 0]
        pack $current_listbox [scrollbar "$b-scroll" -command [list $current_listbox yview]] \
                -side left -expand 1 -fill y -anchor w
        foreach item [concat [lsort -dictionary [glob -directory $dir -nocomplain -types {d} -- *]] \
                                          [lsort -dictionary [glob -directory $dir -nocomplain -types {f} -- *]]]  {
                $current_listbox insert end "[file tail $item][expr {[file isdirectory $item] ? {/} : {}}]"
        }
        bind $current_listbox <Button-1> [list doc_navigate $dir $count %W %x %y]
        bind $current_listbox <Double-Button-1> [list doc_double_button $dir $count %W %x %y]
}

proc doc_navigate {dir count width x y} {
        if {[set newdir [$width get [$width index "@$x,$y"]]] eq {}} {
                return
        }
        set dir_to_open [file join $dir $newdir]
        if {[file isdirectory $dir_to_open]} {
                doc_make_listbox [winfo parent $width] $dir_to_open [incr count]
        }
}

proc doc_double_button {dir count width x y} {
        global pd_guidir
        if {[set newdir [$width get [$width index "@$x,$y"]]] eq {}} {
                return
        }
        set dir_to_open [file join $dir $newdir]
        if {[file isdirectory $dir_to_open]} {
                 doc_navigate $dir $count $width $x $y
        } else {
                regsub -- $pd_guidir [file dirname $dir_to_open] "" subdir
                set file [file tail $dir_to_open]
                if { [catch {menu_doc_open $subdir $file} fid] } {
                        puts stderr "Could not open $pd_guidir/$subdir/$file\n"
                }
                return; 
        }
}

############# routine to add media, help, and apple menu items ###############

proc menu_addstd {mbar} {
    global pd_apilist pd_midiapilist pd_nt pd_tearoff
#          the "Audio" menu
    $mbar.audio add command -label {audio ON} -accelerator [accel_munge "Ctrl+/"] \
        -command {menu_audio 1} 
    $mbar.audio add command -label {audio OFF} -accelerator [accel_munge "Ctrl+."] \
        -command {menu_audio 0} 
    for {set x 0} {$x<[llength $pd_apilist]} {incr x} {
        $mbar.audio add radiobutton -label [lindex [lindex $pd_apilist $x] 0] \
            -command {menu_audio 0} -variable pd_whichapi \
                -value [lindex [lindex $pd_apilist $x] 1]\
                -command {pd [concat pd audio-setapi $pd_whichapi \;]}
    }
    for {set x 0} {$x<[llength $pd_midiapilist]} {incr x} {
        $mbar.audio add radiobutton -label [lindex [lindex $pd_midiapilist $x] 0] \
            -command {menu_midi 0} -variable pd_whichmidiapi \
                -value [lindex [lindex $pd_midiapilist $x] 1]\
                -command {pd [concat pd midi-setapi $pd_whichmidiapi \;]}
    }
         if {$pd_nt != 2} {
    $mbar.audio add command -label {Audio settings...} \
        -command {pd pd audio-properties \;}
    $mbar.audio add command -label {MIDI settings...} \
        -command {pd pd midi-properties \;}
         }
         
    $mbar.audio add command -label {Test Audio and MIDI} \
        -command {menu_doc_open doc/7.stuff/tools testtone.pd} 
    $mbar.audio add command -label {Load Meter} \
        -command {menu_doc_open doc/7.stuff/tools load-meter.pd} 

#       the MacOS X app menu

# The menu on the main menubar named $whatever.apple while be treated
# as a special menu on MacOS X.  Tcl/Tk assigns the $whatever.apple menu
# to the app-specific menu in MacOS X that is named after the app,
# so in our case, the Pd menu.  <hans@at.or.at>
# See SPECIAL MENUS IN MENUBARS http://www.tcl.tk/man/tcl8.4/TkCmd/menu.htm
         if {$pd_nt == 2} {
                  $mbar.apple add command -label "About Pd..." -command \
                                {menu_doc_open doc/1.manual 1.introduction.txt} 
                  menu $mbar.apple.preferences -tearoff 0
                  $mbar.apple add cascade -label "Preferences" -menu $mbar.apple.preferences
                  $mbar.apple.preferences add command -label "Path..." \
                                -command {pd pd start-path-dialog \;}
                  $mbar.apple.preferences add command -label "Startup..." \
                                -command {pd pd start-startup-dialog \;}
                  $mbar.apple.preferences add command -label "Audio Settings..." \
                                -command {pd pd audio-properties \;}
                  $mbar.apple.preferences add command -label "MIDI settings..." \
                                -command {pd pd midi-properties \;}
         }


        # the "Help" menu
    if {$pd_nt != 2} {
        $mbar.help add command -label {About Pd} \
            -command {menu_doc_open doc/1.manual 1.introduction.txt} 
    }
    $mbar.help add command -label {Html ...} \
        -command {menu_doc_open doc/1.manual index.htm} 
    $mbar.help add command -label {Browser ...} \
        -command {menu_doc_browser $help_top_directory} 
}

#################### the "File" menu for the Pd window ##############

.mbar.file add command -label New -command {menu_new} \
    -accelerator [accel_munge "Ctrl+n"]
.mbar.file add command -label Open -command {menu_open .} \
    -accelerator [accel_munge "Ctrl+o"]
.mbar.file add  separator
.mbar.file add command -label Message -command {menu_send} \
    -accelerator [accel_munge "Ctrl+m"]
# On MacOS X, these are in the standard HIG locations
# i.e. the Preferences menu under "Pd"
if {$pd_nt != 2} {
.mbar.file add command -label Path... \
    -command {pd pd start-path-dialog \;}
.mbar.file add command -label Startup... \
    -command {pd pd start-startup-dialog \;}
}
.mbar.file add  separator
.mbar.file add command -label Quit -command {menu_quit} \
    -accelerator [accel_munge "Ctrl+q"]

#################### the "Find" menu for the Pd window ##############
.mbar.find add command -label {Find last error} -command {menu_finderror} 

###########  functions for menu functions on document windows ########

proc menu_save {name} {
    pdtk_canvas_checkgeometry $name
    pd [concat $name menusave \;]
}

proc menu_saveas {name} {
    pdtk_canvas_checkgeometry $name
    pd [concat $name menusaveas \;]
}

proc menu_print {name} {
    set filename [tk_getSaveFile -initialfile pd.ps \
       -defaultextension .ps \
       -filetypes { {{postscript} {.ps}} }]

    if {$filename != ""} {
        $name.c postscript -file $filename 
    }
}

proc menu_close {name} {
    pdtk_canvas_checkgeometry $name
    pd [concat $name menuclose 0 \;]
}

proc menu_really_close {name} {
    pdtk_canvas_checkgeometry $name
    pd [concat $name menuclose 1 \;]
}

proc menu_undo {name} {
    global pd_undoaction
    global pd_redoaction
    global pd_undocanvas
    if {$name == $pd_undocanvas && $pd_undoaction != "no"} {
        pd [concat $name undo \;]
    }
}

proc menu_redo {name} {
    global pd_undoaction
    global pd_redoaction
    global pd_undocanvas
    if {$name == $pd_undocanvas && $pd_redoaction != "no"} {
        pd [concat $name redo \;]
    }
}

proc menu_cut {name} {
    pd [concat $name cut \;]
}

proc menu_copy {name} {
    pd [concat $name copy \;]
}

proc menu_paste {name} {
    pd [concat $name paste \;]
}

proc menu_duplicate {name} {
    pd [concat $name duplicate \;]
}

proc menu_selectall {name} {
    pd [concat $name selectall \;]
}

proc menu_texteditor {name} {
    pd [concat $name texteditor \;]
}

proc menu_font {name} {
    pd [concat $name menufont \;]
}

proc menu_tidyup {name} {
    pd [concat $name tidy \;]
}

proc menu_editmode {name} {
    pd [concat $name editmode 0 \;]
}

proc menu_object {name accel} {
    pd [concat $name obj $accel \;]
}

proc menu_message {name accel} {
    pd [concat $name msg $accel \;]
}

proc menu_floatatom {name accel} {
    pd [concat $name floatatom $accel \;]
}

proc menu_symbolatom {name accel} {
    pd [concat $name symbolatom $accel \;]
}

proc menu_comment {name accel} {
    pd [concat $name text $accel \;]
}

proc menu_graph {name} {
    pd [concat $name graph \;]
}

proc menu_array {name} {
    pd [concat $name menuarray \;]
}

############iemlib##################
proc menu_bng {name accel} {
    pd [concat $name bng $accel \;]
}

proc menu_toggle {name accel} {
    pd [concat $name toggle $accel \;]
}

proc menu_numbox {name accel} {
    pd [concat $name numbox $accel \;]
}

proc menu_vslider {name accel} {
    pd [concat $name vslider $accel \;]
}

proc menu_hslider {name accel} {
    pd [concat $name hslider $accel \;]
}

proc menu_hradio {name accel} {
    pd [concat $name hradio $accel \;]
}

proc menu_vradio {name accel} {
    pd [concat $name vradio $accel \;]
}

proc menu_vumeter {name accel} {
    pd [concat $name vumeter $accel \;]
}

proc menu_mycnv {name accel} {
    pd [concat $name mycnv $accel \;]
}

############iemlib##################

# correct edit menu, enabling or disabling undo/redo
# LATER also cut/copy/paste
proc menu_fixeditmenu {name} {
    global pd_undoaction
    global pd_redoaction
    global pd_undocanvas
#    puts stderr [concat menu_fixeditmenu $name $pd_undocanvas $pd_undoaction]
    if {$name == $pd_undocanvas && $pd_undoaction != "no"} {
        $name.m.edit entryconfigure "Undo*" -state normal \
            -label [concat "Undo " $pd_undoaction]
    } else {
        $name.m.edit entryconfigure "Undo*" -state disabled -label "Undo"
    }
    if {$name == $pd_undocanvas && $pd_redoaction != "no"} {
        $name.m.edit entryconfigure "Redo*" -state normal\
            -label [concat "Redo " $pd_redoaction]
    } else {
        $name.m.edit entryconfigure "Redo*" -state disabled
    }
}

# message from Pd to update the currently available undo/redo action
proc pdtk_undomenu {name undoaction redoaction} {
    global pd_undoaction
    global pd_redoaction
    global pd_undocanvas
#    puts stderr [concat pdtk_undomenu $name $undoaction $redoaction]
    set pd_undocanvas $name
    set pd_undoaction $undoaction
    set pd_redoaction $redoaction
    if {$name != "nobody"} {
#    unpleasant way of avoiding a more unpleasant bug situation --atl 2002.11.25
        menu_fixeditmenu $name
    }
}

proc menu_windowparent {name} {
    pd [concat $name findparent \;]
}

proc menu_findagain {name} {
    pd [concat $name findagain \;]
}

proc menu_finderror {} {
    pd [concat pd finderror \;]
}

proc menu_domenuwindow {i} {
    raise $i
}

proc menu_fixwindowmenu {name} {
    global menu_windowlist
    global pd_tearoff
    $name.m.windows add command
    if $pd_tearoff {
        $name.m.windows delete 4 end
    } else {
        $name.m.windows delete 3 end
    }
    foreach i $menu_windowlist {
        $name.m.windows add command -label [lindex $i 0] \
            -command [concat menu_domenuwindow [lindex $i 1]]
    }
}

################## the "find" menu item ###################

set find_canvas nobody
set find_string ""
set find_count 1
set find_wholeword 1

proc find_apply {name} {
    global find_string find_canvas find_wholeword
    pd [concat $find_canvas find [pdtk_encodedialog $find_string] \
        $find_wholeword \;]
    after 50 destroy $name
}

proc find_cancel {name} {
    after 50 destroy $name
}

proc menu_findobject {canvas} {
    global find_string find_canvas find_count find_wholeword
    
    set name [format ".find%d" $find_count]
    set find_count [expr $find_count + 1]

    set find_canvas $canvas
    
    toplevel $name

    label $name.label -text {find...}
    pack $name.label -side top

    entry $name.entry -textvariable find_string
    pack $name.entry -side top
    checkbutton $name.wholeword -variable find_wholeword \
        -text {whole word} -anchor e
    pack $name.wholeword -side bottom

    frame $name.buttonframe
    pack $name.buttonframe -side bottom -fill x -pady 2m
    button $name.buttonframe.cancel -text {Cancel}\
        -command "find_cancel $name"
    button $name.buttonframe.ok -text {OK}\
        -command "find_apply $name"
    pack $name.buttonframe.cancel -side left -expand 1
    pack $name.buttonframe.ok -side left -expand 1
    
    $name.entry select from 0
    $name.entry select adjust end
    bind $name.entry <KeyPress-Return> [ concat find_apply $name]
    pdtk_standardkeybindings $name.entry
    focus $name.entry
}


############# pdtk_canvas_new -- create a new canvas ###############
proc pdtk_canvas_new {name width height geometry editable} {
    global pd_opendir
    global pd_tearoff
    global pd_nt
    global tcl_version

    toplevel $name -menu $name.m
        # if we're a mac, refuse to make window so big you can't get to
        # the resizing control
    if {$pd_nt == 2} {
        if {$width > [winfo screenwidth $name] - 80} {
            set width [expr [winfo screenwidth $name] - 80]
        }
        if {$height > [winfo screenheight $name] - 80} {
            set height [expr [winfo screenheight $name] - 80]
        }
    }
    
# slide offscreen windows into view
    if {$tcl_version >= 8.4} {
        set geometry [split $geometry +]
        set i 1
        foreach geo {width height} {
            set screen($geo) [winfo screen$geo .]
            if {[expr [lindex $geometry $i] + [set $geo]] > $screen($geo)} {
                set pos($geo) [expr $screen($geo) - [set $geo]]
                if {$pos($geo) < 0} {set pos($geo) 0}
                lset geometry $i $pos($geo)
            }
            incr i
        }
        set geometry [join $geometry +] 
   }
   wm geometry $name $geometry
   canvas $name.c -width $width -height $height -background white \
        -yscrollcommand "$name.scrollvert set" \
        -xscrollcommand "$name.scrollhort set" \
        -scrollregion [concat 0 0 $width $height] 

    scrollbar $name.scrollvert -command "$name.c yview"
    scrollbar $name.scrollhort -command "$name.c xview" \
        -orient horizontal

    pack $name.scrollhort -side bottom -fill x
    pack $name.scrollvert -side right -fill y
    pack $name.c -side left -expand 1 -fill both
    wm minsize $name 1 1
    wm geometry $name $geometry
# the file menu

# The menus are instantiated here for the patch windows.
# For the main window, they are created on load, at the 
# top of this file.
    menu $name.m
    menu $name.m.file -tearoff $pd_tearoff
    $name.m add cascade -label File -menu $name.m.file

    $name.m.file add command -label New -command {menu_new} \
        -accelerator [accel_munge "Ctrl+n"]

    $name.m.file add command -label Open -command [concat menu_open $name] \
        -accelerator [accel_munge "Ctrl+o"]

    $name.m.file add  separator
    $name.m.file add command -label Message -command {menu_send} \
        -accelerator [accel_munge "Ctrl+m"]

         # arrange menus according to Apple HIG
         # these are now part of Preferences...
         if {$pd_nt != 2 } {
    $name.m.file add command -label Path... \
        -command {pd pd start-path-dialog \;} 

    $name.m.file add command -label Startup... \
        -command {pd pd start-startup-dialog \;} 
         }

    $name.m.file add  separator
    $name.m.file add command -label Close \
        -command [concat menu_close $name] \
        -accelerator [accel_munge "Ctrl+w"]

    $name.m.file add command -label Save -command [concat menu_save $name] \
        -accelerator [accel_munge "Ctrl+s"]

    $name.m.file add command -label "Save as..." \
        -command [concat menu_saveas $name] \
        -accelerator [accel_munge "Ctrl+S"]

    $name.m.file add command -label Print -command [concat menu_print $name] \
        -accelerator [accel_munge "Ctrl+p"]

    $name.m.file add separator

    $name.m.file add command -label Quit -command {menu_quit} \
        -accelerator [accel_munge "Ctrl+q"]

# the edit menu
    menu $name.m.edit -postcommand [concat menu_fixeditmenu $name] -tearoff $pd_tearoff
    $name.m add cascade -label Edit -menu $name.m.edit
    
    $name.m.edit add command -label Undo -command [concat menu_undo $name] \
        -accelerator [accel_munge "Ctrl+z"]

    $name.m.edit add command -label Redo -command [concat menu_redo $name] \
        -accelerator [accel_munge "Ctrl+Z"]

    $name.m.edit add separator

    $name.m.edit add command -label Cut -command [concat menu_cut $name] \
        -accelerator [accel_munge "Ctrl+x"]

    $name.m.edit add command -label Copy -command [concat menu_copy $name] \
        -accelerator [accel_munge "Ctrl+c"]

    $name.m.edit add command -label Paste \
        -command [concat menu_paste $name] \
        -accelerator [accel_munge "Ctrl+v"]

    $name.m.edit add command -label Duplicate \
        -command [concat menu_duplicate $name] \
        -accelerator [accel_munge "Ctrl+d"]

    $name.m.edit add command -label {Select all} \
        -command [concat menu_selectall $name] \
        -accelerator [accel_munge "Ctrl+a"]

    $name.m.edit add command -label {Reselect} \
        -command [concat menu_reselect $name] \
        -accelerator "Ctrl+Enter"

    $name.m.edit add separator

    $name.m.edit add command -label {Text Editor} \
        -command [concat menu_texteditor $name] \
        -accelerator [accel_munge "Ctrl+t"]

    $name.m.edit add command -label Font \
        -command [concat menu_font $name] 

    $name.m.edit add command -label {Tidy Up} \
        -command [concat menu_tidyup $name]

    $name.m.edit add separator
    
# Apple, Microsoft, and others put find functions in the Edit menu.
    $name.m.edit add command -label {Find...} \
                  -accelerator [accel_munge "Ctrl+f"] \
                  -command [concat menu_findobject $name] 
    $name.m.edit add command -label {Find Again} \
                  -accelerator [accel_munge "Ctrl+g"] \
                  -command [concat menu_findagain $name] 
    $name.m.edit add command -label {Find last error} \
                  -command [concat menu_finderror] 

    $name.m.edit add separator

############iemlib##################
# instead of "red = #BC3C60" we take "grey85", so there is no difference,
# if widget is selected or not.

    $name.m.edit add checkbutton -label "Edit mode" \
        -indicatoron true -selectcolor grey85 \
        -command [concat menu_editmode $name] \
        -accelerator [accel_munge "Ctrl+e"]     

    if { $editable == 0 } {
            $name.m.edit entryconfigure "Edit mode" -indicatoron false }

        
############iemlib##################


# the put menu
    menu $name.m.put -tearoff $pd_tearoff
    $name.m add cascade -label Put -menu $name.m.put

    $name.m.put add command -label Object \
        -command [concat menu_object $name 0] \
        -accelerator [accel_munge "Ctrl+1"]

    $name.m.put add command -label Message \
        -command [concat menu_message $name 0] \
        -accelerator [accel_munge "Ctrl+2"]

    $name.m.put add command -label Number \
        -command [concat menu_floatatom $name 0] \
        -accelerator [accel_munge "Ctrl+3"]

    $name.m.put add command -label Symbol \
        -command [concat menu_symbolatom $name 0] \
        -accelerator [accel_munge "Ctrl+4"]

    $name.m.put add command -label Comment \
        -command [concat menu_comment $name 0] \
        -accelerator [accel_munge "Ctrl+5"]

    $name.m.put add separator
        
############iemlib##################

    $name.m.put add command -label Bang \
        -command [concat menu_bng $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+b"]
    
    $name.m.put add command -label Toggle \
        -command [concat menu_toggle $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+t"]
    
    $name.m.put add command -label Number2 \
        -command [concat menu_numbox $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+n"]
    
    $name.m.put add command -label Vslider \
        -command [concat menu_vslider $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+v"]
    
    $name.m.put add command -label Hslider \
        -command [concat menu_hslider $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+h"]
    
    $name.m.put add command -label Vradio \
        -command [concat menu_vradio $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+d"]
    
    $name.m.put add command -label Hradio \
        -command [concat menu_hradio $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+i"]
    
    $name.m.put add command -label VU \
        -command [concat menu_vumeter $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+u"]
    
    $name.m.put add command -label Canvas \
        -command [concat menu_mycnv $name 0] \
        -accelerator [accel_munge "Shift+Ctrl+c"]

############iemlib##################
    
    $name.m.put add separator
        
    $name.m.put add command -label Graph \
        -command [concat menu_graph $name] 

    $name.m.put add command -label Array \
        -command [concat menu_array $name] 

# the find menu
# Apple, Microsoft, and others put find functions in the Edit menu.
# But in order to move these items to the Edit menu, the Find menu
# handling needs to be dealt with, including this line in g_canvas.c:
#         sys_vgui(".mbar.find delete %d\n", i);
# <hans@at.or.at>
    menu $name.m.find -tearoff $pd_tearoff
    $name.m add cascade -label Find -menu $name.m.find

    $name.m.find add command -label {Find...} \
        -accelerator [accel_munge "Ctrl+f"] \
        -command [concat menu_findobject $name] 
    $name.m.find add command -label {Find Again} \
        -accelerator [accel_munge "Ctrl+g"] \
        -command [concat menu_findagain $name] 
    $name.m.find add command -label {Find last error} \
        -command [concat menu_finderror] 
    
# the window menu
    menu $name.m.windows -postcommand [concat menu_fixwindowmenu $name] \
        -tearoff $pd_tearoff

    $name.m.windows add command -label {parent window}\
        -command [concat menu_windowparent $name] 
    $name.m.windows add command -label {Pd window} -command menu_pop_pd
    $name.m.windows add separator

# the audio menu
    menu $name.m.audio -tearoff $pd_tearoff

    if {$pd_nt != 2} {
        $name.m add cascade -label Windows -menu $name.m.windows
        $name.m add cascade -label Media -menu $name.m.audio
    } else {
        $name.m add cascade -label Media -menu $name.m.audio
        $name.m add cascade -label Window -menu $name.m.windows
# the MacOS X app menu
                  menu $name.m.apple -tearoff $pd_tearoff
                  $name.m add cascade -label "Apple" -menu $name.m.apple 
    }

# the help menu

    menu $name.m.help -tearoff $pd_tearoff
    $name.m add cascade -label Help -menu $name.m.help

    menu_addstd $name.m

# the popup menu
    menu $name.popup -tearoff false
    $name.popup add command -label {Properties} \
        -command [concat popup_action $name 0] 
    $name.popup add command -label {Open} \
        -command [concat popup_action $name 1] 
    $name.popup add command -label {Help} \
        -command [concat popup_action $name 2] 

# fix menu font size on Windows with tk scaling = 1
if {$pd_nt == 1} {
    $name.m.file configure -font menuFont
    $name.m.edit configure -font menuFont
    $name.m.find configure -font menuFont
    $name.m.put configure -font menuFont
    $name.m.windows configure -font menuFont
    $name.m.audio configure -font menuFont
    $name.m.help configure -font menuFont
    $name.popup configure -font menuFont
}

# WM protocol
    wm protocol $name WM_DELETE_WINDOW [concat menu_close $name]

# bindings.
# this is idiotic -- how do you just sense what mod keys are down and
# pass them on? I can't find it anywhere.
# Here we encode shift as 1, control 2, alt 4, in agreement
# with definitions in g_canvas.c.  The third button gets "8" but we don't
# bother with modifiers there.
# We don't handle multiple clicks yet.

    bind $name.c <Button> {pdtk_canvas_click %W %x %y %b 0}
    bind $name.c <Shift-Button> {pdtk_canvas_click %W %x %y %b 1}
    bind $name.c <Control-Shift-Button> {pdtk_canvas_click %W %x %y %b 3}
    # Alt key is called Option on the Mac
    if {$pd_nt == 2} {
        bind $name.c <Option-Button> {pdtk_canvas_click %W %x %y %b 4}
        bind $name.c <Option-Shift-Button> {pdtk_canvas_click %W %x %y %b 5}
        bind $name.c <Option-Control-Button> {pdtk_canvas_click %W %x %y %b 6}
        bind $name.c <Mod1-Button> {pdtk_canvas_click %W %x %y %b 6}
        bind $name.c <Option-Control-Shift-Button> \
            {pdtk_canvas_click %W %x %y %b 7}
    } else {
        bind $name.c <Alt-Button> {pdtk_canvas_click %W %x %y %b 4}
        bind $name.c <Alt-Shift-Button> {pdtk_canvas_click %W %x %y %b 5}
        bind $name.c <Alt-Control-Button> {pdtk_canvas_click %W %x %y %b 6}
        bind $name.c <Alt-Control-Shift-Button> \
            {pdtk_canvas_click %W %x %y %b 7}
    }
    global pd_nt
# button 2 is the right button on Mac; on other platforms it's button 3.
    if {$pd_nt == 2} {
        bind $name.c <Button-2> {pdtk_canvas_click %W %x %y %b 8}
        bind $name.c <Control-Button> {pdtk_canvas_click %W %x %y %b 8}
    } else {
        bind $name.c <Button-3> {pdtk_canvas_click %W %x %y %b 8}
        bind $name.c <Control-Button> {pdtk_canvas_click %W %x %y %b 2}
    }
#on linux, button 2 "pastes" from the X windows clipboard
    if {$pd_nt == 0} {
        bind $name.c <Button-2> {\
            pdtk_canvas_click %W %x %y %b 0;\
             pdtk_canvas_mouseup %W %x %y %b;\
             pdtk_pastetext}
    }

    bind $name.c <ButtonRelease> {pdtk_canvas_mouseup %W %x %y %b}
    bind $name.c <Control-Key> {pdtk_canvas_ctrlkey %W %K 0}
    bind $name.c <Control-Shift-Key> {pdtk_canvas_ctrlkey %W %K 1}
#    bind $name.c <Mod1-Key> {puts stderr [concat mod1 %W %K %A]}
    if {$pd_nt == 2} {
        bind $name.c <Mod1-Key> {pdtk_canvas_ctrlkey %W %K 0}
        bind $name.c <Mod1-Shift-Key> {pdtk_canvas_ctrlkey %W %K 1}
    }
    bind $name.c <Key> {pdtk_canvas_key %W %K %A 0}
    bind $name.c <Shift-Key> {pdtk_canvas_key %W %K %A 1}
    bind $name.c <KeyRelease> {pdtk_canvas_keyup %W %K %A}
    bind $name.c <Motion> {pdtk_canvas_motion %W %x %y 0}
    bind $name.c <Control-Motion> {pdtk_canvas_motion %W %x %y 2}
    if {$pd_nt == 2} {
        bind $name.c <Option-Motion> {pdtk_canvas_motion %W %x %y 4}
    } else { 
        bind $name.c <Alt-Motion> {pdtk_canvas_motion %W %x %y 4}
    }   
    bind $name.c <Map> {pdtk_canvas_map %W}
    bind $name.c <Unmap> {pdtk_canvas_unmap %W}
    focus $name.c

    switch $pd_nt { 0 {
        bind $name.c <Button-4>  "pdtk_canvas_scroll $name.c y -1"
        bind $name.c <Button-5>  "pdtk_canvas_scroll $name.c y +1"
        bind $name.c <Shift-Button-4>  "pdtk_canvas_scroll $name.c x -1"
        bind $name.c <Shift-Button-5>  "pdtk_canvas_scroll $name.c x +1"
    } default {
        bind $name.c  <MouseWheel> \
            "pdtk_canvas_scroll $name.c y \[expr -abs(%D)/%D\]"
        bind $name.c  <Shift-MouseWheel> \
            "pdtk_canvas_scroll $name.c x \[expr -abs(%D)/%D\]"
    }}

    catch {
        dnd bindtarget $name.c text/uri-list <Drop> \
            "pdtk_canvas_makeobjs $name %D %x %y"
    }

#    puts stderr "all done"
#   after 1 [concat raise $name]
    global pdtk_canvas_mouseup_name
    set pdtk_canvas_mouseup_name ""
}

#### jsarlo #####
proc pdtk_array_listview_setpage {arrayName page} {
    global pd_array_listview_page
    set pd_array_listview_page($arrayName) $page
}

proc pdtk_array_listview_changepage {arrayName np} {
    global pd_array_listview_page
    pdtk_array_listview_setpage \
      $arrayName [expr $pd_array_listview_page($arrayName) + $np]
    pdtk_array_listview_fillpage $arrayName
}

proc pdtk_array_listview_fillpage {arrayName} {
    global pd_array_listview_page
    global pd_array_listview_id
    set windowName [format ".%sArrayWindow" $arrayName]
    set topItem [expr [lindex [$windowName.lb yview] 0] * \
                 [$windowName.lb size]]
   
    if {[winfo exists $windowName]} {
      set cmd "$pd_array_listview_id($arrayName) \
               arrayviewlistfillpage \
               $pd_array_listview_page($arrayName) \
               $topItem"
   
      pd [concat $cmd \;]
    }
}

proc pdtk_array_listview_new {id arrayName page} {
    global pd_nt
    global pd_array_listview_page
    global pd_array_listview_id
     global fontname fontweight
    set pd_array_listview_page($arrayName) $page
    set pd_array_listview_id($arrayName) $id
    set windowName [format ".%sArrayWindow" $arrayName]
    if [winfo exists $windowName] then [destroy $windowName]
    toplevel $windowName
    wm protocol $windowName WM_DELETE_WINDOW \
      "pdtk_array_listview_close $id $arrayName"
    wm title $windowName [concat $arrayName "(list view)"]
    # FIXME
    set font 12
    set $windowName.lb [listbox $windowName.lb -height 20 -width 25\
                        -selectmode extended \
                        -relief solid -background white -borderwidth 1 \
                        -font [format {{%s} %d %s} $fontname $font $fontweight]\
                        -yscrollcommand "$windowName.lb.sb set"]
    set $windowName.lb.sb [scrollbar $windowName.lb.sb \
                           -command "$windowName.lb yview" -orient vertical]
    place configure $windowName.lb.sb -relheight 1 -relx 0.9 -relwidth 0.1
    pack $windowName.lb -expand 1 -fill both
    bind $windowName.lb <Double-ButtonPress-1> \
         "pdtk_array_listview_edit $arrayName $page $font"
    # handle copy/paste
    if {$pd_nt == 0} {
      selection handle $windowName.lb \
            "pdtk_array_listview_lbselection $arrayName"
    } else {
      if {$pd_nt == 1} {
        bind $windowName.lb <ButtonPress-3> \
           "pdtk_array_listview_popup $arrayName"
      } 
    }
    set $windowName.prevBtn [button $windowName.prevBtn -text "<-" \
        -command "pdtk_array_listview_changepage $arrayName -1"]
    set $windowName.nextBtn [button $windowName.nextBtn -text "->" \
        -command "pdtk_array_listview_changepage $arrayName 1"]
    pack $windowName.prevBtn -side left -ipadx 20 -pady 10 -anchor s
    pack $windowName.nextBtn -side right -ipadx 20 -pady 10 -anchor s
    focus $windowName
}

proc pdtk_array_listview_lbselection {arrayName off size} {
    set windowName [format ".%sArrayWindow" $arrayName]
    set itemNums [$windowName.lb curselection]
    set cbString ""
    for {set i 0} {$i < [expr [llength $itemNums] - 1]} {incr i} {
      set listItem [$windowName.lb get [lindex $itemNums $i]]
      append cbString [string range $listItem \
                        [expr [string first ") " $listItem] + 2] \
                        end]
      append cbString "\n"
    }
    set listItem [$windowName.lb get [lindex $itemNums $i]]
    append cbString [string range $listItem \
                      [expr [string first ") " $listItem] + 2] \
                      end]
    set last $cbString
}

# Win32 uses a popup menu for copy/paste
proc pdtk_array_listview_popup {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    if [winfo exists $windowName.popup] then [destroy $windowName.popup]
    menu $windowName.popup -tearoff false
    $windowName.popup add command -label {Copy} \
        -command "pdtk_array_listview_copy $arrayName; \
                  destroy $windowName.popup"
    $windowName.popup add command -label {Paste} \
        -command "pdtk_array_listview_paste $arrayName; \
                  destroy $windowName.popup"
    tk_popup $windowName.popup [winfo pointerx $windowName] \
             [winfo pointery $windowName] 0
}

proc pdtk_array_listview_copy {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    set itemNums [$windowName.lb curselection]
    set cbString ""
    for {set i 0} {$i < [expr [llength $itemNums] - 1]} {incr i} {
      set listItem [$windowName.lb get [lindex $itemNums $i]]
      append cbString [string range $listItem \
                        [expr [string first ") " $listItem] + 2] \
                        end]
      append cbString "\n"
    }
    set listItem [$windowName.lb get [lindex $itemNums $i]]
    append cbString [string range $listItem \
                      [expr [string first ") " $listItem] + 2] \
                      end]
    clipboard clear
    clipboard append $cbString
}

proc pdtk_array_listview_paste {arrayName} {
    global pd_array_listview_page
    global pd_array_listview_pagesize
    set cbString [selection get -selection CLIPBOARD]
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    set itemNum [lindex [$lbName curselection] 0]
    set splitChars ", \n"
    set itemString [split $cbString $splitChars]
    set flag 1
    for {set i 0; set counter 0} {$i < [llength $itemString]} {incr i} {
      if {[lindex $itemString $i] != {}} {
        pd [concat $arrayName [expr $itemNum + \
           [expr $counter + \
           [expr $pd_array_listview_pagesize \
                 * $pd_array_listview_page($arrayName)]]] \
           [lindex $itemString $i] \;]
        incr counter
        set flag 0
      }
    }
}

proc pdtk_array_listview_edit {arrayName page font} {
    global pd_array_listview_entry
    global pd_nt
     global fontname fontweight
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    if {[winfo exists $lbName.entry]} {
      pdtk_array_listview_update_entry \
        $arrayName $pd_array_listview_entry($arrayName)
      unset pd_array_listview_entry($arrayName)
    }
    set itemNum [$lbName index active]
    set pd_array_listview_entry($arrayName) $itemNum
    set bbox [$lbName bbox $itemNum]
    set y [expr [lindex $bbox 1] - 4]
    set $lbName.entry [entry $lbName.entry \
                       -font [format {{%s} %d %s} $fontname $font $fontweight]]
    $lbName.entry insert 0 []
    place configure $lbName.entry -relx 0 -y $y -relwidth 1
    lower $lbName.entry
    focus $lbName.entry
    bind $lbName.entry <Return> \
         "pdtk_array_listview_update_entry $arrayName $itemNum;"
}

proc pdtk_array_listview_update_entry {arrayName itemNum} {
    global pd_array_listview_page
    global pd_array_listview_pagesize
    set lbName [format ".%sArrayWindow.lb" $arrayName]
    set splitChars ", \n"
    set itemString [split [$lbName.entry get] $splitChars]
    set flag 1
    for {set i 0; set counter 0} {$i < [llength $itemString]} {incr i} {
      if {[lindex $itemString $i] != {}} {
        pd [concat $arrayName [expr $itemNum + \
           [expr $counter + \
           [expr $pd_array_listview_pagesize \
                 * $pd_array_listview_page($arrayName)]]] \
           [lindex $itemString $i] \;]
        incr counter
        set flag 0
      }
    }
    pdtk_array_listview_fillpage $arrayName
    destroy $lbName.entry
}

proc pdtk_array_listview_closeWindow {arrayName} {
    set windowName [format ".%sArrayWindow" $arrayName]
    destroy $windowName
}

proc pdtk_array_listview_close {id arrayName} {
    pdtk_array_listview_closeWindow $arrayName
    set cmd [concat $id "arrayviewclose" \;]
    pd $cmd
}
##### end jsarlo #####

#################### event binding procedures ################

#get the name of the toplevel window for a canvas; this is also
#the name of the canvas object in Pd.

proc canvastosym {name} {
    string range $name 0 [expr [string length $name] - 3]
}

set pdtk_lastcanvasconfigured ""
set pdtk_lastcanvasconfiguration ""
set pdtk_lastcanvasconfiguration2 ""

proc pdtk_canvas_checkgeometry {topname} {
    set boo [winfo geometry $topname.c]
    set boo2 [wm geometry $topname]
    global pdtk_lastcanvasconfigured
    global pdtk_lastcanvasconfiguration
    global pdtk_lastcanvasconfiguration2
    if {$topname != $pdtk_lastcanvasconfigured || \
        $boo != $pdtk_lastcanvasconfiguration || \
        $boo2 != $pdtk_lastcanvasconfiguration2} {
            set pdtk_lastcanvasconfigured $topname
            set pdtk_lastcanvasconfiguration $boo
            set pdtk_lastcanvasconfiguration2 $boo2
            pd $topname relocate $boo $boo2 \;
    }
}

proc pdtk_canvas_click {name x y b f} {
    global pd_nt
    if {$pd_nt == 0} {focus $name}
    pd [canvastosym $name] mouse [$name canvasx $x] [$name canvasy $y] $b $f \;
}

proc pdtk_canvas_shiftclick {name x y b} {
    pd [canvastosym $name] mouse [$name canvasx $x] [$name canvasy $y] $b 1 \;
}

proc pdtk_canvas_ctrlclick {name x y b} {
    pd [canvastosym $name] mouse [$name canvasx $x] [$name canvasy $y] $b 2 \;
}

proc pdtk_canvas_altclick {name x y b} {
    pd [canvastosym $name] mouse [$name canvasx $x] [$name canvasy $y] $b 3 \;
}

proc pdtk_canvas_dblclick {name x y b} {
    pd [canvastosym $name] mouse [$name canvasx $x] [$name canvasy $y] $b 4 \;
}

set pdtk_canvas_mouseup_name 0
set pdtk_canvas_mouseup_xminval 0
set pdtk_canvas_mouseup_xmaxval 0
set pdtk_canvas_mouseup_yminval 0
set pdtk_canvas_mouseup_ymaxval 0

proc pdtk_canvas_mouseup {name x y b} {
    pd [concat [canvastosym $name] mouseup [$name canvasx $x] \
        [$name canvasy $y] $b \;]
}

proc pdtk_canvas_getscroll {name} {
    global pdtk_canvas_mouseup_name
    global pdtk_canvas_mouseup_xminval
    global pdtk_canvas_mouseup_xmaxval
    global pdtk_canvas_mouseup_yminval
    global pdtk_canvas_mouseup_ymaxval

    set size [$name bbox all]
    if {$size != ""} {
        set xminval 0
        set yminval 0
        set xmaxval 100
        set ymaxval 100
        set x1 [lindex $size 0]
        set x2 [lindex $size 2]
        set y1 [lindex $size 1]
        set y2 [lindex $size 3]
        
        if {$x1 < 0} {set xminval $x1}
        if {$y1 < 0} {set yminval $y1}

        if {$x2 > 100} {set xmaxval $x2}
        if {$y2 > 100} {set ymaxval $y2}
        
        if {$pdtk_canvas_mouseup_name != $name || \
            $pdtk_canvas_mouseup_xminval != $xminval || \
            $pdtk_canvas_mouseup_xmaxval != $xmaxval || \
            $pdtk_canvas_mouseup_yminval != $yminval || \
            $pdtk_canvas_mouseup_ymaxval != $ymaxval } {
            
                set newsize "$xminval $yminval $xmaxval $ymaxval"
                $name configure -scrollregion $newsize
                set pdtk_canvas_mouseup_name $name
                set pdtk_canvas_mouseup_xminval $xminval
                set pdtk_canvas_mouseup_xmaxval $xmaxval
                set pdtk_canvas_mouseup_yminval $yminval
                set pdtk_canvas_mouseup_ymaxval $ymaxval
        }

    }
    pdtk_canvas_checkgeometry [canvastosym $name]
}

proc pdtk_canvas_key {name key iso shift} {
#    puts stderr [concat down key= $key iso= $iso]
#    .controls.switches.meterbutton configure -text $key
#  HACK for MAC OSX -- backspace seems different; I don't understand why.
#  invesigate this LATER...
    global pd_nt
    if {$pd_nt == 2} {
        if {$key == "BackSpace"} {
            set key 8
            set keynum 8
        }
        if {$key == "Delete"} {
            set key 8
            set keynum 8
        }
    }
    if {$key == "KP_Delete"} {
        set key 127
        set keynum 127
    }
    if {$iso != ""} {
        scan $iso %c keynum 
        pd [canvastosym $name] key 1 $keynum $shift\;
    } else {
        pd [canvastosym $name] key 1 $key $shift\;
    }
}

proc pdtk_canvas_keyup {name key iso} {
#    puts stderr [concat up key= $key iso= $iso]
    if {$iso != ""} {
        scan $iso %c keynum 
        pd [canvastosym $name] key 0 $keynum 0 \;
    } else {
        pd [canvastosym $name] key 0 $key 0 \;
    }
}

proc pdtk_canvas_ctrlkey {name key shift} {
# first get rid of ".c" suffix; we'll refer to the toplevel instead
    set topname [string trimright $name .c]
#   puts stderr [concat ctrl-key $key $topname]

    if {$key == "1"} {menu_object $topname 1}
    if {$key == "2"} {menu_message $topname 1}
    if {$key == "3"} {menu_floatatom $topname 1}
    if {$key == "4"} {menu_symbolatom $topname 1}
    if {$key == "5"} {menu_comment $topname 1}
    if {$key == "slash"} {menu_audio 1}
    if {$key == "period"} {menu_audio 0}
    if {$key == "Return"} {menu_reselect $topname}
    if {$shift == 1} {
        if {$key == "q" || $key == "Q"} {menu_really_quit}
        if {$key == "w" || $key == "W"} {menu_really_close $topname}
        if {$key == "s" || $key == "S"} {menu_saveas $topname}
        if {$key == "z" || $key == "Z"} {menu_redo $topname}
        if {$key == "b" || $key == "B"} {menu_bng $topname 1}
        if {$key == "t" || $key == "T"} {menu_toggle $topname 1}
        if {$key == "n" || $key == "N"} {menu_numbox $topname 1}
        if {$key == "v" || $key == "V"} {menu_vslider $topname 1}
        if {$key == "h" || $key == "H"} {menu_hslider $topname 1}
        if {$key == "i" || $key == "I"} {menu_hradio $topname 1}
        if {$key == "d" || $key == "D"} {menu_vradio $topname 1}
        if {$key == "u" || $key == "U"} {menu_vumeter $topname 1}
        if {$key == "c" || $key == "C"} {menu_mycnv $topname 1}
    } else {
        if {$key == "e" || $key == "E"} {menu_editmode $topname}
        if {$key == "q" || $key == "Q"} {menu_quit}
        if {$key == "s" || $key == "S"} {menu_save $topname}
        if {$key == "z" || $key == "Z"} {menu_undo $topname}
        if {$key == "n" || $key == "N"} {menu_new}
        if {$key == "o" || $key == "O"} {menu_open $topname}
        if {$key == "m" || $key == "M"} {menu_send}
        if {$key == "w" || $key == "W"} {menu_close $topname}
        if {$key == "p" || $key == "P"} {menu_print $topname}
        if {$key == "x" || $key == "X"} {menu_cut $topname}
        if {$key == "c" || $key == "C"} {menu_copy $topname}
        if {$key == "v" || $key == "V"} {menu_paste $topname}
        if {$key == "d" || $key == "D"} {menu_duplicate $topname}
        if {$key == "a" || $key == "A"} {menu_selectall $topname}
        if {$key == "t" || $key == "T"} {menu_texteditor $topname}
        if {$key == "f" || $key == "F"} {menu_findobject $topname}
        if {$key == "g" || $key == "G"} {menu_findagain $topname}
    }
}

proc pdtk_canvas_scroll {canvas xy distance} {
    $canvas [list $xy]view scroll $distance units
}

proc pdtk_canvas_motion {name x y mods} {
#    puts stderr [concat [canvastosym $name] $name $x $y]
    pd [canvastosym $name] motion [$name canvasx $x] [$name canvasy $y] $mods \;
}

# "map" event tells us when the canvas becomes visible (arg is "0") or
# invisible (arg is "").  Invisibility means the Window Manager has minimized
# us.  We don't get a final "unmap" event when we destroy the window.
proc pdtk_canvas_map {name} {
#   puts stderr [concat map $name]
    pd [canvastosym $name] map 1 \;
}

proc pdtk_canvas_unmap {name} {
#   puts stderr [concat unmap $name]
    pd [canvastosym $name] map 0 \;
}

proc pdtk_canvas_makeobjs {name files x y} {
    set c 0
    for {set n 0} {$n < [llength $files]} {incr n} {
        if {[regexp {.*/(.+).pd$} [lindex $files $n] file obj] == 1} {
            pd $name obj $x [expr $y + ($c * 30)] [pdtk_enquote $obj] \;
            incr c
        }
    } 
}

set saveas_dir nowhere

############ pdtk_canvas_saveas -- run a saveas dialog ##############

proc pdtk_canvas_saveas {name initfile initdir} {
    global pd_nt
    set filename [tk_getSaveFile -initialfile $initfile \
       -initialdir $initdir  -defaultextension .pd -parent $name.c \
        -filetypes { {{pd files} {.pd}} {{max files} {.pat}} }]

    if {$filename != ""} {
# yes, we need the extent even if we're on a mac.
        if {$pd_nt == 2} {
          if {[string last .pd $filename] < 0 && \
            [string last .PD $filename] < 0 && \
            [string last .pat $filename] < 0 && \
            [string last .PAT $filename] < 0} {
                set filename $filename.pd
                if {[file exists $filename]} {
                        set answer [tk_messageBox \
                        \-message [concat overwrite $filename "?"] \
                         \-type yesno \-icon question]
                        if {! [string compare $answer no]} {return}
                }
          }
        }

        set directory [string range $filename 0 \
            [expr [string last / $filename ] - 1]]
        set basename [string range $filename \
            [expr [string last / $filename ] + 1] end]
        pd [concat $name savetofile [pdtk_enquote $basename] \
             [pdtk_enquote $directory] \;]
#       pd [concat $name savetofile $basename $directory \;]
    }
}

############ pdtk_canvas_dofont -- run a font and resize dialog #########

set fontsize 0
set stretchval 0
set whichstretch 0

proc dofont_apply {name} {
    global fontsize
    global stretchval
    global whichstretch
    set cmd [concat $name font $fontsize $stretchval $whichstretch \;]
#    puts stderr $cmd
    pd $cmd
}

proc dofont_cancel {name} {
    set cmd [concat $name cancel \;]
#    puts stderr $cmd
    pd $cmd
}

proc pdtk_canvas_dofont {name initsize} {
    
    global fontsize
    set fontsize $initsize
    
    global stretchval
    set stretchval 100
    
    global whichstretch
    set whichstretch 1
    
    toplevel $name
    wm title $name  {FONT BOMB}
    wm protocol $name WM_DELETE_WINDOW [concat dofont_cancel $name]

    frame $name.buttonframe
    pack $name.buttonframe -side bottom -fill x -pady 2m
    button $name.buttonframe.cancel -text {Cancel}\
        -command "dofont_cancel $name"
    button $name.buttonframe.ok -text {Do it}\
        -command "dofont_apply $name"
    pack $name.buttonframe.cancel -side left -expand 1
    pack $name.buttonframe.ok -side left -expand 1
    
    frame $name.radiof
    pack $name.radiof -side left
    
    label $name.radiof.label -text {Font Size:}
    pack $name.radiof.label -side top

    radiobutton $name.radiof.radio8 -value 8 -variable fontsize -text "8"
    radiobutton $name.radiof.radio10 -value 10 -variable fontsize -text "10"
    radiobutton $name.radiof.radio12 -value 12 -variable fontsize -text "12"
    radiobutton $name.radiof.radio16 -value 16 -variable fontsize -text "16"
    radiobutton $name.radiof.radio24 -value 24 -variable fontsize -text "24"
    radiobutton $name.radiof.radio36 -value 36 -variable fontsize -text "36"
    pack $name.radiof.radio8 -side top -anchor w
    pack $name.radiof.radio10 -side top -anchor w
    pack $name.radiof.radio12 -side top -anchor w
    pack $name.radiof.radio16 -side top -anchor w
    pack $name.radiof.radio24 -side top -anchor w
    pack $name.radiof.radio36 -side top -anchor w

    frame $name.stretchf
    pack $name.stretchf -side left
    
    label $name.stretchf.label -text {Stretch:}
    pack $name.stretchf.label -side top
    
    entry $name.stretchf.entry -textvariable stretchval -width 5
    pack $name.stretchf.entry -side left

    radiobutton $name.stretchf.radio1 \
        -value 1 -variable whichstretch -text "X and Y"
    radiobutton $name.stretchf.radio2 \
        -value 2 -variable whichstretch -text "X only"
    radiobutton $name.stretchf.radio3 \
        -value 3 -variable whichstretch -text "Y only"

    pack $name.stretchf.radio1 -side top -anchor w
    pack $name.stretchf.radio2 -side top -anchor w
    pack $name.stretchf.radio3 -side top -anchor w

}

############ pdtk_gatom_dialog -- run a gatom dialog #########

# dialogs like this one can come up in many copies; but in TK the easiest
# way to get data from an "entry", etc., is to set an associated variable
# name.  This is especially true for grouped "radio buttons".  So we have
# to synthesize variable names for each instance of the dialog.  The dialog
# gets a TK pathname $id, from which it strips the leading "." to make a
# variable suffix $vid.  Then you can get the actual value out by asking for
# [eval concat $$variablename].  There should be an easier way but I don't see
# it yet.

proc gatom_escape {sym} {
    if {[string length $sym] == 0} {
        set ret "-"
#       puts stderr [concat escape1 $sym $ret]
    } else {
        if {[string equal -length 1 $sym "-"]} {
        set ret [string replace $sym 0 0 "--"]
#       puts stderr [concat escape $sym $ret]
        } else {
            set ret [string map {"$" "#"} $sym]
#            puts stderr [concat unescape $sym $ret]
        }
    }
    pdtk_unspace $ret
}

proc gatom_unescape {sym} {
    if {[string equal -length 1 $sym "-"]} {
        set ret [string replace $sym 0 0 ""]
#       puts stderr [concat unescape $sym $ret]
    } else {
        set ret [string map {"#" "$"} $sym]
#        puts stderr [concat unescape $sym $ret]
    }
    concat $ret
}
        
proc dogatom_apply {id} {
    set vid [string trimleft $id .]

    set var_gatomwidth [concat gatomwidth_$vid]
    global $var_gatomwidth
    set var_gatomlo [concat gatomlo_$vid]
    global $var_gatomlo
    set var_gatomhi [concat gatomhi_$vid]
    global $var_gatomhi
    set var_gatomwherelabel [concat gatomwherelabel_$vid]
    global $var_gatomwherelabel
    set var_gatomlabel [concat gatomlabel_$vid]
    global $var_gatomlabel
    set var_gatomsymfrom [concat gatomsymfrom_$vid]
    global $var_gatomsymfrom
    set var_gatomsymto [concat gatomsymto_$vid]
    global $var_gatomsymto

#    set cmd [concat $id param $gatomwidth $gatomlo $gatomhi \;]
    
    set cmd [concat $id param \
        [eval concat $$var_gatomwidth] \
        [eval concat $$var_gatomlo] \
        [eval concat $$var_gatomhi] \
        [eval gatom_escape $$var_gatomlabel] \
        [eval concat $$var_gatomwherelabel] \
        [eval gatom_escape $$var_gatomsymfrom] \
        [eval gatom_escape $$var_gatomsymto] \
        \;]

#    puts stderr $cmd
    pd $cmd
}

proc dogatom_cancel {name} {
    set cmd [concat $name cancel \;]
#    puts stderr $cmd
    pd $cmd
}

proc dogatom_ok {name} {
    dogatom_apply $name
    dogatom_cancel $name
}

proc pdtk_gatom_dialog {id initwidth initlo inithi \
    wherelabel label symfrom symto} {

    set vid [string trimleft $id .]

     global pd_nt

    set var_gatomwidth [concat gatomwidth_$vid]
    global $var_gatomwidth
    set var_gatomlo [concat gatomlo_$vid]
    global $var_gatomlo
    set var_gatomhi [concat gatomhi_$vid]
    global $var_gatomhi
    set var_gatomwherelabel [concat gatomwherelabel_$vid]
    global $var_gatomwherelabel
    set var_gatomlabel [concat gatomlabel_$vid]
    global $var_gatomlabel
    set var_gatomsymfrom [concat gatomsymfrom_$vid]
    global $var_gatomsymfrom
    set var_gatomsymto [concat gatomsymto_$vid]
    global $var_gatomsymto

    set $var_gatomwidth $initwidth
    set $var_gatomlo $initlo
    set $var_gatomhi $inithi
    set $var_gatomwherelabel $wherelabel
    set $var_gatomlabel [gatom_unescape $label]
    set $var_gatomsymfrom [gatom_unescape $symfrom]
    set $var_gatomsymto [gatom_unescape $symto]

    toplevel $id
    wm title $id "atom box properties"
    wm resizable $id 0 0
    wm protocol $id WM_DELETE_WINDOW [concat dogatom_cancel $id]

    frame $id.params -height 7
    pack $id.params -side top
    label $id.params.entryname -text "width"
    entry $id.params.entry -textvariable $var_gatomwidth -width 4
    pack $id.params.entryname $id.params.entry -side left

    labelframe $id.limits -text "limits" -padx 15 -pady 4 -borderwidth 1 \
          -font highlight_font
     pack $id.limits -side top -fill x
    frame $id.limits.lower
    pack $id.limits.lower -side left
    label $id.limits.lower.entryname -text "lower"
    entry $id.limits.lower.entry -textvariable $var_gatomlo -width 8
    pack $id.limits.lower.entryname $id.limits.lower.entry -side left
    frame $id.limits.upper
    pack $id.limits.upper -side left
    frame $id.limits.upper.spacer -width 20
    label $id.limits.upper.entryname -text "upper"
    entry $id.limits.upper.entry -textvariable $var_gatomhi -width 8
    pack  $id.limits.upper.spacer $id.limits.upper.entryname \
          $id.limits.upper.entry -side left

    frame $id.spacer1 -height 7
    pack $id.spacer1 -side top

    labelframe $id.label -text "label" -padx 5 -pady 4 -borderwidth 1 \
          -font highlight_font
     pack $id.label -side top -fill x
    frame $id.label.name
    pack $id.label.name -side top
    entry $id.label.name.entry -textvariable $var_gatomlabel -width 33
    pack $id.label.name.entry -side left
    frame $id.label.radio
    pack $id.label.radio -side top
    radiobutton $id.label.radio.left -value 0 \
        -variable $var_gatomwherelabel \
        -text "left   "  -justify left
    radiobutton $id.label.radio.right -value 1 \
        -variable $var_gatomwherelabel \
        -text "right" -justify left
    radiobutton $id.label.radio.top -value 2 \
        -variable $var_gatomwherelabel \
        -text "top" -justify left
    radiobutton $id.label.radio.bottom -value 3 \
        -variable $var_gatomwherelabel \
        -text "bottom" -justify left
    pack $id.label.radio.left -side left -anchor w
    pack $id.label.radio.right -side right -anchor w
    pack $id.label.radio.top -side top -anchor w
    pack $id.label.radio.bottom -side bottom -anchor w

    frame $id.spacer2 -height 7
    pack $id.spacer2 -side top

    labelframe $id.s_r -text "messages" -padx 5 -pady 4 -borderwidth 1 \
          -font highlight_font
     pack $id.s_r -side top -fill x
    frame $id.s_r.paramsymto
    pack $id.s_r.paramsymto -side top -anchor e
    label $id.s_r.paramsymto.entryname -text "send symbol"
    entry $id.s_r.paramsymto.entry -textvariable $var_gatomsymto -width 21
    pack $id.s_r.paramsymto.entry $id.s_r.paramsymto.entryname -side right

    frame $id.s_r.paramsymfrom
    pack $id.s_r.paramsymfrom -side top -anchor e
    label $id.s_r.paramsymfrom.entryname -text "receive symbol"
    entry $id.s_r.paramsymfrom.entry -textvariable $var_gatomsymfrom -width 21
    pack $id.s_r.paramsymfrom.entry $id.s_r.paramsymfrom.entryname -side right
        
    frame $id.buttonframe -pady 5
    pack $id.buttonframe -side top -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "dogatom_cancel $id"
    pack $id.buttonframe.cancel -side left -expand 1
    button $id.buttonframe.apply -text {Apply}\
        -command "dogatom_apply $id"
    pack $id.buttonframe.apply -side left -expand 1
    button $id.buttonframe.ok -text {OK}\
        -command "dogatom_ok $id"
    pack $id.buttonframe.ok -side left -expand 1

    bind $id.limits.upper.entry <KeyPress-Return> [concat dogatom_ok $id]
    bind $id.limits.lower.entry <KeyPress-Return> [concat dogatom_ok $id]
    bind $id.params.entry <KeyPress-Return> [concat dogatom_ok $id]
    pdtk_standardkeybindings $id.limits.upper.entry
    pdtk_standardkeybindings $id.limits.lower.entry
    pdtk_standardkeybindings $id.params.entry
    $id.params.entry select from 0
    $id.params.entry select adjust end
    focus $id.params.entry
}

############ pdtk_canvas_popup -- popup menu for canvas #########

set popup_xpix 0
set popup_ypix 0

proc popup_action {name action} {
    global popup_xpix popup_ypix
    set cmd [concat $name done-popup $action $popup_xpix $popup_ypix \;]
#    puts stderr $cmd
    pd $cmd
}

proc pdtk_canvas_popup {name xpix ypix canprop canopen} {
    global popup_xpix popup_ypix
    set popup_xpix $xpix
    set popup_ypix $ypix
    if {$canprop == 0} {$name.popup entryconfigure 0 -state disabled}
    if {$canprop == 1} {$name.popup entryconfigure 0 -state active}
    if {$canopen == 0} {$name.popup entryconfigure 1 -state disabled}
    if {$canopen == 1} {$name.popup entryconfigure 1 -state active}
    tk_popup $name.popup [expr $xpix + [winfo rootx $name.c]] \
         [expr $ypix + [winfo rooty $name.c]] 0
}


# begin of change "iemlib"
############ pdtk_iemgui_dialog -- dialog window for iem guis #########

set iemgui_define_min_flashhold 50
set iemgui_define_min_flashbreak 10
set iemgui_define_min_fontsize 4

proc iemgui_clip_dim {id} {
    set vid [string trimleft $id .]

    set var_iemgui_wdt [concat iemgui_wdt_$vid]
    global $var_iemgui_wdt
    set var_iemgui_min_wdt [concat iemgui_min_wdt_$vid]
    global $var_iemgui_min_wdt
    set var_iemgui_hgt [concat iemgui_hgt_$vid]
    global $var_iemgui_hgt
    set var_iemgui_min_hgt [concat iemgui_min_hgt_$vid]
    global $var_iemgui_min_hgt
    
    if {[eval concat $$var_iemgui_wdt] < [eval concat $$var_iemgui_min_wdt]} {
        set $var_iemgui_wdt [eval concat $$var_iemgui_min_wdt]
        $id.dim.w_ent configure -textvariable $var_iemgui_wdt
    }
    if {[eval concat $$var_iemgui_hgt] < [eval concat $$var_iemgui_min_hgt]} {
        set $var_iemgui_hgt [eval concat $$var_iemgui_min_hgt]
        $id.dim.h_ent configure -textvariable $var_iemgui_hgt
    }
}

proc iemgui_clip_num {id} {
    set vid [string trimleft $id .]

    set var_iemgui_num [concat iemgui_num_$vid]
    global $var_iemgui_num
    
    if {[eval concat $$var_iemgui_num] > 2000} {
        set $var_iemgui_num 2000
        $id.para.num_ent configure -textvariable $var_iemgui_num
    }
    if {[eval concat $$var_iemgui_num] < 1} {
        set $var_iemgui_num 1
        $id.para.num_ent configure -textvariable $var_iemgui_num
    }
}

proc iemgui_sched_rng {id} {
    set vid [string trimleft $id .]

    set var_iemgui_min_rng [concat iemgui_min_rng_$vid]
    global $var_iemgui_min_rng
    set var_iemgui_max_rng [concat iemgui_max_rng_$vid]
    global $var_iemgui_max_rng
    set var_iemgui_rng_sch [concat iemgui_rng_sch_$vid]
    global $var_iemgui_rng_sch

    global iemgui_define_min_flashhold
    global iemgui_define_min_flashbreak
    
    if {[eval concat $$var_iemgui_rng_sch] == 2} {
        if {[eval concat $$var_iemgui_max_rng] < [eval concat $$var_iemgui_min_rng]} {
            set hhh [eval concat $$var_iemgui_min_rng]
            set $var_iemgui_min_rng [eval concat $$var_iemgui_max_rng]
            set $var_iemgui_max_rng $hhh
            $id.rng.max_ent configure -textvariable $var_iemgui_max_rng
            $id.rng.min_ent configure -textvariable $var_iemgui_min_rng }
        if {[eval concat $$var_iemgui_max_rng] < $iemgui_define_min_flashhold} {
            set $var_iemgui_max_rng $iemgui_define_min_flashhold
            $id.rng.max_ent configure -textvariable $var_iemgui_max_rng
        }
        if {[eval concat $$var_iemgui_min_rng] < $iemgui_define_min_flashbreak} {
            set $var_iemgui_min_rng $iemgui_define_min_flashbreak
            $id.rng.min_ent configure -textvariable $var_iemgui_min_rng
        }
    }
    if {[eval concat $$var_iemgui_rng_sch] == 1} {
        if {[eval concat $$var_iemgui_min_rng] == 0.0} {
            set $var_iemgui_min_rng 1.0
            $id.rng.min_ent configure -textvariable $var_iemgui_min_rng
        }
    }
}

proc iemgui_verify_rng {id} {
    set vid [string trimleft $id .]

    set var_iemgui_min_rng [concat iemgui_min_rng_$vid]
    global $var_iemgui_min_rng
    set var_iemgui_max_rng [concat iemgui_max_rng_$vid]
    global $var_iemgui_max_rng
    set var_iemgui_lin0_log1 [concat iemgui_lin0_log1_$vid]
    global $var_iemgui_lin0_log1
    
    if {[eval concat $$var_iemgui_lin0_log1] == 1} {
        if {[eval concat $$var_iemgui_max_rng] == 0.0 && [eval concat $$var_iemgui_min_rng] == 0.0} {
            set $var_iemgui_max_rng 1.0
            $id.rng.max_ent configure -textvariable $var_iemgui_max_rng
            }
        if {[eval concat $$var_iemgui_max_rng] > 0} {
            if {[eval concat $$var_iemgui_min_rng] <= 0} {
                set $var_iemgui_min_rng [expr [eval concat $$var_iemgui_max_rng] * 0.01]
                $id.rng.min_ent configure -textvariable $var_iemgui_min_rng
            }
        } else {
            if {[eval concat $$var_iemgui_min_rng] > 0} {
                set $var_iemgui_max_rng [expr [eval concat $$var_iemgui_min_rng] * 0.01]
                $id.rng.max_ent configure -textvariable $var_iemgui_max_rng
            }
        }
    }
}

proc iemgui_clip_fontsize {id} {
    set vid [string trimleft $id .]

    set var_iemgui_gn_fs [concat iemgui_gn_fs_$vid]
    global $var_iemgui_gn_fs
    
    global iemgui_define_min_fontsize

    if {[eval concat $$var_iemgui_gn_fs] < $iemgui_define_min_fontsize} {
        set $var_iemgui_gn_fs $iemgui_define_min_fontsize
        $id.label.fs_ent configure -textvariable $var_iemgui_gn_fs
    }
}

proc iemgui_set_col_example {id} {
    set vid [string trimleft $id .]

    set var_iemgui_bcol [concat iemgui_bcol_$vid]
    global $var_iemgui_bcol
    set var_iemgui_fcol [concat iemgui_fcol_$vid]
    global $var_iemgui_fcol
    set var_iemgui_lcol [concat iemgui_lcol_$vid]
    global $var_iemgui_lcol
    
    $id.colors.sections.lb_bk configure \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_lcol]] \
       -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_lcol]]
    
    if { [eval concat $$var_iemgui_fcol] >= 0 } {
       $id.colors.sections.fr_bk configure \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_fcol]] \
       -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_fcol]]
    } else {
       $id.colors.sections.fr_bk configure \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_bcol]]}
}

proc iemgui_preset_col {id presetcol} {
    set vid [string trimleft $id .]

    set var_iemgui_l2_f1_b0 [concat iemgui_l2_f1_b0_$vid]
    global $var_iemgui_l2_f1_b0
    set var_iemgui_bcol [concat iemgui_bcol_$vid]
    global $var_iemgui_bcol
    set var_iemgui_fcol [concat iemgui_fcol_$vid]
    global $var_iemgui_fcol
    set var_iemgui_lcol [concat iemgui_lcol_$vid]
    global $var_iemgui_lcol
    
    if { [eval concat $$var_iemgui_l2_f1_b0] == 0 } { set $var_iemgui_bcol $presetcol }
    if { [eval concat $$var_iemgui_l2_f1_b0] == 1 } { set $var_iemgui_fcol $presetcol }
    if { [eval concat $$var_iemgui_l2_f1_b0] == 2 } { set $var_iemgui_lcol $presetcol }
    iemgui_set_col_example $id
}

proc iemgui_choose_col_bkfrlb {id} {
    set vid [string trimleft $id .]

    set var_iemgui_l2_f1_b0 [concat iemgui_l2_f1_b0_$vid]
    global $var_iemgui_l2_f1_b0
    set var_iemgui_bcol [concat iemgui_bcol_$vid]
    global $var_iemgui_bcol
    set var_iemgui_fcol [concat iemgui_fcol_$vid]
    global $var_iemgui_fcol
    set var_iemgui_lcol [concat iemgui_lcol_$vid]
    global $var_iemgui_lcol
    
    if {[eval concat $$var_iemgui_l2_f1_b0] == 0} {
        set $var_iemgui_bcol [expr [eval concat $$var_iemgui_bcol] & 0xFCFCFC]
        set helpstring [tk_chooseColor -title "Background-Color" -initialcolor [format "#%6.6x" [eval concat $$var_iemgui_bcol]]]
        if { $helpstring != "" } {
              set $var_iemgui_bcol [string replace $helpstring 0 0 "0x"]
              set $var_iemgui_bcol [expr [eval concat $$var_iemgui_bcol] & 0xFCFCFC] }
    }
    if {[eval concat $$var_iemgui_l2_f1_b0] == 1} {
        set $var_iemgui_fcol [expr [eval concat $$var_iemgui_fcol] & 0xFCFCFC]
        set helpstring [tk_chooseColor -title "Front-Color" -initialcolor [format "#%6.6x" [eval concat $$var_iemgui_fcol]]]
        if { $helpstring != "" } {
              set $var_iemgui_fcol [string replace $helpstring 0 0 "0x"]
              set $var_iemgui_fcol [expr [eval concat $$var_iemgui_fcol] & 0xFCFCFC] }
    }
    if {[eval concat $$var_iemgui_l2_f1_b0] == 2} {
        set $var_iemgui_lcol [expr [eval concat $$var_iemgui_lcol] & 0xFCFCFC]
        set helpstring [tk_chooseColor -title "Label-Color" -initialcolor [format "#%6.6x" [eval concat $$var_iemgui_lcol]]]
        if { $helpstring != "" } {
              set $var_iemgui_lcol [string replace $helpstring 0 0 "0x"]
              set $var_iemgui_lcol [expr [eval concat $$var_iemgui_lcol] & 0xFCFCFC] }
    }
    iemgui_set_col_example $id
}

proc iemgui_lilo {id} {
    set vid [string trimleft $id .]

    set var_iemgui_lin0_log1 [concat iemgui_lin0_log1_$vid]
    global $var_iemgui_lin0_log1
    set var_iemgui_lilo0 [concat iemgui_lilo0_$vid]
    global $var_iemgui_lilo0
    set var_iemgui_lilo1 [concat iemgui_lilo1_$vid]
    global $var_iemgui_lilo1
   
    iemgui_sched_rng $id

    if {[eval concat $$var_iemgui_lin0_log1] == 0} {
        set $var_iemgui_lin0_log1 1
        $id.para.lilo configure -text [eval concat $$var_iemgui_lilo1]
        iemgui_verify_rng $id
        iemgui_sched_rng $id
    } else {
        set $var_iemgui_lin0_log1 0
        $id.para.lilo configure -text [eval concat $$var_iemgui_lilo0]
    }
}

proc iemgui_toggle_font {id gn_f} {
    set vid [string trimleft $id .]

    set var_iemgui_gn_f [concat iemgui_gn_f_$vid]
    global $var_iemgui_gn_f
     global fontname fontweight
    
    set $var_iemgui_gn_f $gn_f

     switch -- $gn_f {
          0 { set current_font $fontname}
          1 { set current_font "Helvetica" }
          2 { set current_font "Times" }
     }
     set current_font_spec "{$current_font} 12 $fontweight"

     $id.label.fontpopup_label configure -text $current_font \
          -font $current_font_spec
     $id.label.name_entry configure -font $current_font_spec
     $id.colors.sections.fr_bk configure -font $current_font_spec
     $id.colors.sections.lb_bk configure -font $current_font_spec
}

proc iemgui_lb {id} {
    set vid [string trimleft $id .]

    set var_iemgui_loadbang [concat iemgui_loadbang_$vid]
    global $var_iemgui_loadbang

    if {[eval concat $$var_iemgui_loadbang] == 0} {
        set $var_iemgui_loadbang 1
        $id.para.lb configure -text "init"
    } else {
        set $var_iemgui_loadbang 0
        $id.para.lb configure -text "no init"
    }
}

proc iemgui_stdy_jmp {id} {
    set vid [string trimleft $id .]

    set var_iemgui_steady [concat iemgui_steady_$vid]
    global $var_iemgui_steady
    
    if {[eval concat $$var_iemgui_steady]} {
        set $var_iemgui_steady 0
        $id.para.stdy_jmp configure -text "jump on click"
    } else {
        set $var_iemgui_steady 1
        $id.para.stdy_jmp configure -text "steady on click"
    }
}

proc iemgui_apply {id} {
    set vid [string trimleft $id .]

    set var_iemgui_wdt [concat iemgui_wdt_$vid]
    global $var_iemgui_wdt
    set var_iemgui_min_wdt [concat iemgui_min_wdt_$vid]
    global $var_iemgui_min_wdt
    set var_iemgui_hgt [concat iemgui_hgt_$vid]
    global $var_iemgui_hgt
    set var_iemgui_min_hgt [concat iemgui_min_hgt_$vid]
    global $var_iemgui_min_hgt
    set var_iemgui_min_rng [concat iemgui_min_rng_$vid]
    global $var_iemgui_min_rng
    set var_iemgui_max_rng [concat iemgui_max_rng_$vid]
    global $var_iemgui_max_rng
    set var_iemgui_lin0_log1 [concat iemgui_lin0_log1_$vid]
    global $var_iemgui_lin0_log1
    set var_iemgui_lilo0 [concat iemgui_lilo0_$vid]
    global $var_iemgui_lilo0
    set var_iemgui_lilo1 [concat iemgui_lilo1_$vid]
    global $var_iemgui_lilo1
    set var_iemgui_loadbang [concat iemgui_loadbang_$vid]
    global $var_iemgui_loadbang
    set var_iemgui_num [concat iemgui_num_$vid]
    global $var_iemgui_num
    set var_iemgui_steady [concat iemgui_steady_$vid]
    global $var_iemgui_steady
    set var_iemgui_snd [concat iemgui_snd_$vid]
    global $var_iemgui_snd
    set var_iemgui_rcv [concat iemgui_rcv_$vid]
    global $var_iemgui_rcv
    set var_iemgui_gui_nam [concat iemgui_gui_nam_$vid]
    global $var_iemgui_gui_nam
    set var_iemgui_gn_dx [concat iemgui_gn_dx_$vid]
    global $var_iemgui_gn_dx
    set var_iemgui_gn_dy [concat iemgui_gn_dy_$vid]
    global $var_iemgui_gn_dy
    set var_iemgui_gn_f [concat iemgui_gn_f_$vid]
    global $var_iemgui_gn_f
    set var_iemgui_gn_fs [concat iemgui_gn_fs_$vid]
    global $var_iemgui_gn_fs
    set var_iemgui_bcol [concat iemgui_bcol_$vid]
    global $var_iemgui_bcol
    set var_iemgui_fcol [concat iemgui_fcol_$vid]
    global $var_iemgui_fcol
    set var_iemgui_lcol [concat iemgui_lcol_$vid]
    global $var_iemgui_lcol
    
    iemgui_clip_dim $id
    iemgui_clip_num $id
    iemgui_sched_rng $id
    iemgui_verify_rng $id
    iemgui_sched_rng $id
    iemgui_clip_fontsize $id
    
    if {[eval concat $$var_iemgui_snd] == ""} {set hhhsnd "empty"} else {set hhhsnd [eval concat $$var_iemgui_snd]}
    if {[eval concat $$var_iemgui_rcv] == ""} {set hhhrcv "empty"} else {set hhhrcv [eval concat $$var_iemgui_rcv]}
    if {[eval concat $$var_iemgui_gui_nam] == ""} {set hhhgui_nam "empty"
        } else {
    set hhhgui_nam [eval concat $$var_iemgui_gui_nam]}

    if {[string index $hhhsnd 0] == "$"} {
       set hhhsnd [string replace $hhhsnd 0 0 #] }
    if {[string index $hhhrcv 0] == "$"} {
       set hhhrcv [string replace $hhhrcv 0 0 #] }
    if {[string index $hhhgui_nam 0] == "$"} {
       set hhhgui_nam [string replace $hhhgui_nam 0 0 #] }
    
    set hhhsnd [pdtk_unspace $hhhsnd]
    set hhhrcv [pdtk_unspace $hhhrcv]
    set hhhgui_nam [pdtk_unspace $hhhgui_nam]
    
    pd [concat $id dialog \
        [eval concat $$var_iemgui_wdt] \
        [eval concat $$var_iemgui_hgt] \
        [eval concat $$var_iemgui_min_rng] \
        [eval concat $$var_iemgui_max_rng] \
        [eval concat $$var_iemgui_lin0_log1] \
        [eval concat $$var_iemgui_loadbang] \
        [eval concat $$var_iemgui_num] \
        $hhhsnd \
        $hhhrcv \
        $hhhgui_nam \
        [eval concat $$var_iemgui_gn_dx] \
        [eval concat $$var_iemgui_gn_dy] \
        [eval concat $$var_iemgui_gn_f] \
        [eval concat $$var_iemgui_gn_fs] \
        [eval concat $$var_iemgui_bcol] \
        [eval concat $$var_iemgui_fcol] \
        [eval concat $$var_iemgui_lcol] \
        [eval concat $$var_iemgui_steady] \
        \;]
}

proc iemgui_cancel {id} {pd [concat $id cancel \;]}

proc iemgui_ok {id} {
    iemgui_apply $id
    iemgui_cancel $id
}

proc pdtk_iemgui_dialog {id mainheader \
        dim_header wdt min_wdt wdt_label hgt min_hgt hgt_label \
        rng_header min_rng min_rng_label max_rng max_rng_label rng_sched \
        lin0_log1 lilo0_label lilo1_label loadbang steady num_label num \
        snd rcv \
        gui_name \
        gn_dx gn_dy \
        gn_f gn_fs \
        bcol fcol lcol} {

    set vid [string trimleft $id .]

     global pd_nt
     global fontname fontweight

    set var_iemgui_wdt [concat iemgui_wdt_$vid]
    global $var_iemgui_wdt
    set var_iemgui_min_wdt [concat iemgui_min_wdt_$vid]
    global $var_iemgui_min_wdt
    set var_iemgui_hgt [concat iemgui_hgt_$vid]
    global $var_iemgui_hgt
    set var_iemgui_min_hgt [concat iemgui_min_hgt_$vid]
    global $var_iemgui_min_hgt
    set var_iemgui_min_rng [concat iemgui_min_rng_$vid]
    global $var_iemgui_min_rng
    set var_iemgui_max_rng [concat iemgui_max_rng_$vid]
    global $var_iemgui_max_rng
    set var_iemgui_rng_sch [concat iemgui_rng_sch_$vid]
    global $var_iemgui_rng_sch
    set var_iemgui_lin0_log1 [concat iemgui_lin0_log1_$vid]
    global $var_iemgui_lin0_log1
    set var_iemgui_lilo0 [concat iemgui_lilo0_$vid]
    global $var_iemgui_lilo0
    set var_iemgui_lilo1 [concat iemgui_lilo1_$vid]
    global $var_iemgui_lilo1
    set var_iemgui_loadbang [concat iemgui_loadbang_$vid]
    global $var_iemgui_loadbang
    set var_iemgui_num [concat iemgui_num_$vid]
    global $var_iemgui_num
    set var_iemgui_steady [concat iemgui_steady_$vid]
    global $var_iemgui_steady
    set var_iemgui_snd [concat iemgui_snd_$vid]
    global $var_iemgui_snd
    set var_iemgui_rcv [concat iemgui_rcv_$vid]
    global $var_iemgui_rcv
    set var_iemgui_gui_nam [concat iemgui_gui_nam_$vid]
    global $var_iemgui_gui_nam
    set var_iemgui_gn_dx [concat iemgui_gn_dx_$vid]
    global $var_iemgui_gn_dx
    set var_iemgui_gn_dy [concat iemgui_gn_dy_$vid]
    global $var_iemgui_gn_dy
    set var_iemgui_gn_f [concat iemgui_gn_f_$vid]
    global $var_iemgui_gn_f
    set var_iemgui_gn_fs [concat iemgui_gn_fs_$vid]
    global $var_iemgui_gn_fs
    set var_iemgui_l2_f1_b0 [concat iemgui_l2_f1_b0_$vid]
    global $var_iemgui_l2_f1_b0
    set var_iemgui_bcol [concat iemgui_bcol_$vid]
    global $var_iemgui_bcol
    set var_iemgui_fcol [concat iemgui_fcol_$vid]
    global $var_iemgui_fcol
    set var_iemgui_lcol [concat iemgui_lcol_$vid]
    global $var_iemgui_lcol

    set $var_iemgui_wdt $wdt
    set $var_iemgui_min_wdt $min_wdt
    set $var_iemgui_hgt $hgt
    set $var_iemgui_min_hgt $min_hgt
    set $var_iemgui_min_rng $min_rng
    set $var_iemgui_max_rng $max_rng
    set $var_iemgui_rng_sch $rng_sched
    set $var_iemgui_lin0_log1 $lin0_log1
    set $var_iemgui_lilo0 $lilo0_label
    set $var_iemgui_lilo1 $lilo1_label
    set $var_iemgui_loadbang $loadbang
    set $var_iemgui_num $num
    set $var_iemgui_steady $steady
    if {$snd == "empty"} {set $var_iemgui_snd [format ""]
        } else {set $var_iemgui_snd [format "%s" $snd]}
    if {$rcv == "empty"} {set $var_iemgui_rcv [format ""]
        } else {set $var_iemgui_rcv [format "%s" $rcv]}
    if {$gui_name == "empty"} {set $var_iemgui_gui_nam [format ""]
        } else {set $var_iemgui_gui_nam [format "%s" $gui_name]}
    
    if {[string index [eval concat $$var_iemgui_snd] 0] == "#"} {
       set $var_iemgui_snd [string replace [eval concat $$var_iemgui_snd] 0 0 $] }
    if {[string index [eval concat $$var_iemgui_rcv] 0] == "#"} {
       set $var_iemgui_rcv [string replace [eval concat $$var_iemgui_rcv] 0 0 $] }
    if {[string index [eval concat $$var_iemgui_gui_nam] 0] == "#"} {
       set $var_iemgui_gui_nam [string replace [eval concat $$var_iemgui_gui_nam] 0 0 $] }
    set $var_iemgui_gn_dx $gn_dx
    set $var_iemgui_gn_dy $gn_dy
    set $var_iemgui_gn_f $gn_f
    set $var_iemgui_gn_fs $gn_fs
    
    set $var_iemgui_bcol $bcol
    set $var_iemgui_fcol $fcol
    set $var_iemgui_lcol $lcol
    
    set $var_iemgui_l2_f1_b0 0

    toplevel $id
    wm title $id [format "%s Properties" $mainheader]
    wm resizable $id 0 0
    wm protocol $id WM_DELETE_WINDOW [concat iemgui_cancel $id]
    
    frame $id.dim
    pack $id.dim -side top
    label $id.dim.head -text $dim_header
    label $id.dim.w_lab -text $wdt_label -width 6
    entry $id.dim.w_ent -textvariable $var_iemgui_wdt -width 5
    label $id.dim.dummy1 -text " " -width 10
    label $id.dim.h_lab -text $hgt_label -width 6
    entry $id.dim.h_ent -textvariable $var_iemgui_hgt -width 5
    pack $id.dim.head -side top
    pack $id.dim.w_lab $id.dim.w_ent $id.dim.dummy1 -side left
    if { $hgt_label != "empty" } {
        pack $id.dim.h_lab $id.dim.h_ent -side left}

    frame $id.rng
    pack $id.rng -side top
    label $id.rng.head -text $rng_header
    label $id.rng.min_lab -text $min_rng_label -width 6
    entry $id.rng.min_ent -textvariable $var_iemgui_min_rng -width 9
    label $id.rng.dummy1 -text " " -width 1
    label $id.rng.max_lab -text $max_rng_label -width 8
    entry $id.rng.max_ent -textvariable $var_iemgui_max_rng -width 9
    if { $rng_header != "empty" } {
        pack $id.rng.head -side top
        if { $min_rng_label != "empty" } {
            pack $id.rng.min_lab $id.rng.min_ent -side left}
        if { $max_rng_label != "empty" } {
            pack $id.rng.dummy1 \
            $id.rng.max_lab $id.rng.max_ent -side left} }
    
    if { [eval concat $$var_iemgui_lin0_log1] >= 0 || [eval concat $$var_iemgui_loadbang] >= 0 || [eval concat $$var_iemgui_num] > 0 || [eval concat $$var_iemgui_steady] >= 0 } {
        label $id.space1 -text ""
        pack $id.space1 -side top }

    frame $id.para
    pack $id.para -side top
    label $id.para.dummy2 -text "" -width 1
    label $id.para.dummy3 -text "" -width 1
    if {[eval concat $$var_iemgui_lin0_log1] == 0} {
        button $id.para.lilo -text [eval concat $$var_iemgui_lilo0] -width 5 -command "iemgui_lilo $id" }
    if {[eval concat $$var_iemgui_lin0_log1] == 1} {
        button $id.para.lilo -text [eval concat $$var_iemgui_lilo1] -width 5 -command "iemgui_lilo $id" }
    if {[eval concat $$var_iemgui_loadbang] == 0} {
        button $id.para.lb -text "no init" -width 5 -command "iemgui_lb $id" }
    if {[eval concat $$var_iemgui_loadbang] == 1} {
        button $id.para.lb -text "init" -width 5 -command "iemgui_lb $id" }
    label $id.para.num_lab -text $num_label -width 9
    entry $id.para.num_ent -textvariable $var_iemgui_num -width 4
    if {[eval concat $$var_iemgui_steady] == 0} {
        button $id.para.stdy_jmp -text "jump on click" -width 11 -command "iemgui_stdy_jmp $id" }
    if {[eval concat $$var_iemgui_steady] == 1} {
        button $id.para.stdy_jmp -text "steady on click" -width 11 -command "iemgui_stdy_jmp $id" }
    if {[eval concat $$var_iemgui_lin0_log1] >= 0} {
        pack $id.para.lilo -side left -expand 1}
    if {[eval concat $$var_iemgui_loadbang] >= 0} {
        pack $id.para.dummy2 $id.para.lb -side left -expand 1}
    if {[eval concat $$var_iemgui_num] > 0} {
        pack $id.para.dummy3 $id.para.num_lab $id.para.num_ent -side left -expand 1}
    if {[eval concat $$var_iemgui_steady] >= 0} {
        pack $id.para.dummy3 $id.para.stdy_jmp -side left -expand 1}

     frame $id.spacer0 -height 4
     pack $id.spacer0 -side top
    
     labelframe $id.s_r -borderwidth 1 -pady 4 -text "messages" \
        -font highlight_font
     pack $id.s_r -side top -fill x -ipadx 5
    frame $id.s_r.send
    pack $id.s_r.send -side top
    label $id.s_r.send.lab -text "   send-symbol:" -width 12  -justify right
    entry $id.s_r.send.ent -textvariable $var_iemgui_snd -width 22
    if { $snd != "nosndno" } {
        pack $id.s_r.send.lab $id.s_r.send.ent -side left}
    
    frame $id.s_r.receive
    pack $id.s_r.receive -side top
    label $id.s_r.receive.lab -text "receive-symbol:" -width 12 -justify right
    entry $id.s_r.receive.ent -textvariable $var_iemgui_rcv -width 22
    if { $rcv != "norcvno" } {
        pack $id.s_r.receive.lab $id.s_r.receive.ent -side left}
    
# get the current font name from the int given from C-space (gn_f)
     set current_font $fontname
    if {[eval concat $$var_iemgui_gn_f] == 1} \
          { set current_font "Helvetica" }
    if {[eval concat $$var_iemgui_gn_f] == 2} \
          { set current_font "Times" }

     frame $id.spacer1 -height 7
     pack $id.spacer1 -side top
    
     labelframe $id.label -borderwidth 1 -text "label" -pady 4 \
          -font highlight_font
     pack $id.label -side top -fill x
    entry $id.label.name_entry -textvariable $var_iemgui_gui_nam -width 30 \
          -font [list $current_font 12 $fontweight]
    pack $id.label.name_entry -side top -expand yes -fill both -padx 5
    
    frame $id.label.xy -padx 27 -pady 1
    pack $id.label.xy -side top
    label $id.label.xy.x_lab -text "x offset" -width 6
    entry $id.label.xy.x_entry -textvariable $var_iemgui_gn_dx -width 5
    label $id.label.xy.dummy1 -text " " -width 2
    label $id.label.xy.y_lab -text "y offset" -width 6
    entry $id.label.xy.y_entry -textvariable $var_iemgui_gn_dy -width 5
    pack $id.label.xy.x_lab $id.label.xy.x_entry $id.label.xy.dummy1 \
         $id.label.xy.y_lab $id.label.xy.y_entry -side left -anchor e
    
     label $id.label.fontpopup_label -text $current_font \
          -relief groove -font [list $current_font 12 $fontweight] -padx 5
    pack $id.label.fontpopup_label -side left -anchor w -expand yes -fill x
    label $id.label.fontsize_label -text "size" -width 4
    entry $id.label.fontsize_entry -textvariable $var_iemgui_gn_fs -width 5
     pack $id.label.fontsize_entry $id.label.fontsize_label \
          -side right -anchor e -padx 5 -pady 5
     menu $id.popup
     $id.popup add command \
          -label $fontname \
          -font [format {{%s} 12 %s} $fontname $fontweight] \
          -command "iemgui_toggle_font $id 0" 
     $id.popup add command \
          -label "Helvetica" \
          -font [format {Helvetica 12 %s} $fontweight] \
          -command "iemgui_toggle_font $id 1" 
     $id.popup add command \
          -label "Times" \
          -font [format {Times 12 %s} $fontweight] \
          -command "iemgui_toggle_font $id 2" 
     bind $id.label.fontpopup_label <Button> \
          [list tk_popup $id.popup %X %Y]

     frame $id.spacer2 -height 7
     pack $id.spacer2 -side top
    
    labelframe $id.colors -borderwidth 1 -text "colors" -font highlight_font
    pack $id.colors -fill x -ipadx 5 -ipady 4
    
    frame $id.colors.select
    pack $id.colors.select -side top
    radiobutton $id.colors.select.radio0 -value 0 -variable \
          $var_iemgui_l2_f1_b0 -text "background" -width 10 -justify left
    radiobutton $id.colors.select.radio1 -value 1 -variable \
          $var_iemgui_l2_f1_b0 -text "front" -width 5 -justify left
    radiobutton $id.colors.select.radio2 -value 2 -variable \
          $var_iemgui_l2_f1_b0 -text "label" -width 5 -justify left
    if { [eval concat $$var_iemgui_fcol] >= 0 } {
          pack $id.colors.select.radio0 $id.colors.select.radio1 \
                $id.colors.select.radio2 -side left
     } else {
          pack $id.colors.select.radio0 $id.colors.select.radio2 -side left \
     }
    
    frame $id.colors.sections
    pack $id.colors.sections -side top
    button $id.colors.sections.but -text "compose color" -width 12 \
             -command "iemgui_choose_col_bkfrlb $id"
    pack $id.colors.sections.but -side left -anchor w -padx 10 -pady 5 \
          -expand yes -fill x
    if { [eval concat $$var_iemgui_fcol] >= 0 } {
          label $id.colors.sections.fr_bk -text "o=||=o" -width 6 \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_fcol]] \
       -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_fcol]] \
       -font [list $current_font 12 $fontweight] -padx 2 -pady 2 -relief ridge
    } else {
          label $id.colors.sections.fr_bk -text "o=||=o" -width 6 \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -font [list $current_font 12 $fontweight] -padx 2 -pady 2 -relief ridge
     }
     label $id.colors.sections.lb_bk -text "testlabel" -width 9 \
       -background [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -activebackground [format "#%6.6x" [eval concat $$var_iemgui_bcol]] \
       -foreground [format "#%6.6x" [eval concat $$var_iemgui_lcol]] \
         -activeforeground [format "#%6.6x" [eval concat $$var_iemgui_lcol]] \
          -font [list $current_font 12 $fontweight] -padx 2 -pady 2 -relief ridge
    pack $id.colors.sections.lb_bk $id.colors.sections.fr_bk \
          -side right -anchor e -expand yes -fill both -pady 7

# color scheme by Mary Ann Benedetto http://piR2.org
    frame $id.colors.r1
    pack $id.colors.r1 -side top
    foreach i { 0 1 2 3 4 5 6 7 8 9} \
          hexcol { 0xFFFFFF 0xDFDFDF 0xBBBBBB 0xFFC7C6 0xFFE3C6 \
                            0xFEFFC6 0xC6FFC7 0xc6FEFF 0xC7C6FF 0xE3C6FF } \
          {
                label $id.colors.r1.c$i -background [format "#%6.6x" $hexcol] \
                     -activebackground [format "#%6.6x" $hexcol] -relief ridge \
                     -padx 7 -pady 0
                bind $id.colors.r1.c$i <Button> [format "iemgui_preset_col %s %d" $id $hexcol] 
          }
    pack $id.colors.r1.c0 $id.colors.r1.c1 $id.colors.r1.c2 $id.colors.r1.c3 \
          $id.colors.r1.c4 $id.colors.r1.c5 $id.colors.r1.c6 $id.colors.r1.c7 \
          $id.colors.r1.c8 $id.colors.r1.c9 -side left
    
    frame $id.colors.r2
    pack $id.colors.r2 -side top
    foreach i { 0 1 2 3 4 5 6 7 8 9 } \
          hexcol { 0x9F9F9F 0x7C7C7C 0x606060 0xFF0400 0xFF8300 \
                            0xFAFF00 0x00FF04 0x00FAFF 0x0400FF 0x9C00FF } \
          {
                label $id.colors.r2.c$i -background [format "#%6.6x" $hexcol] \
                     -activebackground [format "#%6.6x" $hexcol] -relief ridge \
                     -padx 7 -pady 0
                bind  $id.colors.r2.c$i <Button> \
                     [format "iemgui_preset_col %s %d" $id $hexcol] 
          }
    pack $id.colors.r2.c0 $id.colors.r2.c1 $id.colors.r2.c2 $id.colors.r2.c3 \
          $id.colors.r2.c4 $id.colors.r2.c5 $id.colors.r2.c6 $id.colors.r2.c7 \
          $id.colors.r2.c8 $id.colors.r2.c9 -side left
    
    frame $id.colors.r3
    pack $id.colors.r3 -side top
    foreach i { 0 1 2 3 4 5 6 7 8 9 } \
          hexcol { 0x404040 0x202020 0x000000 0x551312 0x553512 \
                            0x535512 0x0F4710 0x0E4345 0x131255 0x2F004D } \
          {
                label $id.colors.r3.c$i -background [format "#%6.6x" $hexcol] \
                     -activebackground [format "#%6.6x" $hexcol] -relief ridge \
                     -padx 7 -pady 0
                bind  $id.colors.r3.c$i <Button> \
                     [format "iemgui_preset_col %s %d" $id $hexcol] 
          }
    pack $id.colors.r3.c0 $id.colors.r3.c1 $id.colors.r3.c2 $id.colors.r3.c3 \
          $id.colors.r3.c4 $id.colors.r3.c5 $id.colors.r3.c6 $id.colors.r3.c7 \
          $id.colors.r3.c8 $id.colors.r3.c9 -side left
    
    frame $id.cao -pady 10
    pack $id.cao -side top
    button $id.cao.cancel -text {Cancel} -width 6 \
        -command "iemgui_cancel $id"
    label $id.cao.dummy1 -text "" -width 3
     button $id.cao.apply -text {Apply} -width 6 -command "iemgui_apply $id"
    label $id.cao.dummy2 -text "" -width 3
    button $id.cao.ok -text {OK} -width 6 \
        -command "iemgui_ok $id"
    
    pack $id.cao.cancel $id.cao.dummy1 -side left
     pack $id.cao.apply $id.cao.dummy2 -side left
    pack $id.cao.ok -side left

    if {[info tclversion] < 8.4} {
        bind $id <Key-Tab> {tkTabToWindow [tk_focusNext %W]}
        bind $id <<PrevWindow>> {tkTabToWindow [tk_focusPrev %W]}
    } else {
        bind $id <Key-Tab> {tk::TabToWindow [tk_focusNext %W]}
        bind $id <<PrevWindow>> {tk::TabToWindow [tk_focusPrev %W]}
    }
    
    bind $id.dim.w_ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.dim.h_ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.rng.min_ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.rng.max_ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.para.num_ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.s_r.send.ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.s_r.receive.ent <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.label.name_entry <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.label.xy.x_entry <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.label.xy.y_entry <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.label.fontsize_entry <KeyPress-Return> [concat iemgui_ok $id]
    bind $id.cao.ok <KeyPress-Return> [concat iemgui_ok $id]
    pdtk_standardkeybindings $id.dim.w_ent
    pdtk_standardkeybindings $id.dim.h_ent
    pdtk_standardkeybindings $id.rng.min_ent
    pdtk_standardkeybindings $id.rng.max_ent
    pdtk_standardkeybindings $id.para.num_ent
    pdtk_standardkeybindings $id.s_r.send.ent
    pdtk_standardkeybindings $id.s_r.receive.ent
    pdtk_standardkeybindings $id.label.name_entry
    pdtk_standardkeybindings $id.label.xy.x_entry
    pdtk_standardkeybindings $id.label.xy.y_entry
    pdtk_standardkeybindings $id.label.fontsize_entry
    pdtk_standardkeybindings $id.cao.ok
    
    $id.dim.w_ent select from 0
    $id.dim.w_ent select adjust end
    focus $id.dim.w_ent
}
# end of change "iemlib"

############ pdtk_array_dialog -- dialog window for arrays #########
# see comments above (pdtk_gatom_dialog) about variable name handling 

proc array_apply {id} {
# strip "." from the TK id to make a variable name suffix 
    set vid [string trimleft $id .]
# for each variable, make a local variable to hold its name...
    set var_array_name [concat array_name_$vid]
    global $var_array_name
    set var_array_n [concat array_n_$vid]
    global $var_array_n
    set var_array_saveit [concat array_saveit_$vid]
    global $var_array_saveit
    set var_array_drawasrects [concat array_drawasrects_$vid]
    global $var_array_drawasrects
    set var_array_otherflag [concat array_otherflag_$vid]
    global $var_array_otherflag
    set mofo [eval concat $$var_array_name]
    if {[string index $mofo 0] == "$"} {
       set mofo [string replace $mofo 0 0 #] }

    set saveit [eval concat $$var_array_saveit]
    set drawasrects [eval concat $$var_array_drawasrects]

    pd [concat $id arraydialog $mofo \
        [eval concat $$var_array_n] \
        [expr $saveit + 2 * $drawasrects] \
        [eval concat $$var_array_otherflag] \
        \;]
}

# jsarlo
proc array_viewlist {id} {
    pd [concat $id arrayviewlistnew\;]
}
# end jsarlo

proc array_cancel {id} {
    set cmd [concat $id cancel \;]
    pd $cmd
}

proc array_ok {id} {
    array_apply $id
    array_cancel $id
}

proc pdtk_array_dialog {id name n flags newone} {
    set vid [string trimleft $id .]

    set var_array_name [concat array_name_$vid]
    global $var_array_name
    set var_array_n [concat array_n_$vid]
    global $var_array_n
    set var_array_saveit [concat array_saveit_$vid]
    global $var_array_saveit
    set var_array_drawasrects [concat array_drawasrects_$vid]
    global $var_array_drawasrects
    set var_array_otherflag [concat array_otherflag_$vid]
    global $var_array_otherflag

    set $var_array_name $name
    set $var_array_n $n
    set $var_array_saveit [expr ( $flags & 1 ) != 0]
    set $var_array_drawasrects [expr ( $flags & 2 ) != 0]
    set $var_array_otherflag 0

    toplevel $id
    wm title $id {array}
    wm resizable $id 0 0
    wm protocol $id WM_DELETE_WINDOW [concat array_cancel $id]

    frame $id.name
    pack $id.name -side top
    label $id.name.label -text "name"
    entry $id.name.entry -textvariable $var_array_name
    pack $id.name.label $id.name.entry -side left

    frame $id.n
    pack $id.n -side top
    label $id.n.label -text "size"
    entry $id.n.entry -textvariable $var_array_n
    pack $id.n.label $id.n.entry -side left

    checkbutton $id.saveme -text {save contents} -variable $var_array_saveit \
        -anchor w
    pack $id.saveme -side top

    frame $id.drawasrects
    pack $id.drawasrects -side top
    radiobutton $id.drawasrects.drawasrects0 -value 0 \
        -variable $var_array_drawasrects \
        -text "draw as points"
    radiobutton $id.drawasrects.drawasrects1 -value 1 \
        -variable $var_array_drawasrects \
        -text "polygon"
    radiobutton $id.drawasrects.drawasrects2 -value 2 \
        -variable $var_array_drawasrects \
        -text "bezier curve"
    pack $id.drawasrects.drawasrects0 -side top -anchor w
    pack $id.drawasrects.drawasrects1 -side top -anchor w
    pack $id.drawasrects.drawasrects2 -side top -anchor w

    if {$newone != 0} {
        frame $id.radio
        pack $id.radio -side top
        radiobutton $id.radio.radio0 -value 0 \
            -variable $var_array_otherflag \
            -text "in new graph"
        radiobutton $id.radio.radio1 -value 1 \
            -variable $var_array_otherflag \
            -text "in last graph"
        pack $id.radio.radio0 -side top -anchor w
        pack $id.radio.radio1 -side top -anchor w
    } else {    
        checkbutton $id.deleteme -text {delete me} \
            -variable $var_array_otherflag -anchor w
        pack $id.deleteme -side top
    }
    # jsarlo
    if {$newone == 0} {
      button $id.listview -text {View list}\
        -command "array_viewlist $id"
      pack $id.listview -side left
    }
    # end jsarlo
    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "array_cancel $id"
    if {$newone == 0} {button $id.buttonframe.apply -text {Apply}\
        -command "array_apply $id"}
    button $id.buttonframe.ok -text {OK}\
        -command "array_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    if {$newone == 0} {pack $id.buttonframe.apply -side left -expand 1}
    pack $id.buttonframe.ok -side left -expand 1
    
    bind $id.name.entry <KeyPress-Return> [concat array_ok $id]
    bind $id.n.entry <KeyPress-Return> [concat array_ok $id]
    pdtk_standardkeybindings $id.name.entry
    pdtk_standardkeybindings $id.n.entry
    $id.name.entry select from 0
    $id.name.entry select adjust end
    focus $id.name.entry
}

############ pdtk_canvas_dialog -- dialog window for canvass #########
# see comments above (pdtk_gatom_dialog) about variable name handling 

proc canvas_apply {id} {
# strip "." from the TK id to make a variable name suffix 
    set vid [string trimleft $id .]
# for each variable, make a local variable to hold its name...

    set var_canvas_xscale [concat canvas_xscale_$vid]
    global $var_canvas_xscale
    set var_canvas_yscale [concat canvas_yscale_$vid]
    global $var_canvas_yscale
    set var_canvas_graphme [concat canvas_graphme_$vid]
    global $var_canvas_graphme
    set var_canvas_hidetext [concat canvas_hidetext_$vid]
    global $var_canvas_hidetext
    set var_canvas_x1 [concat canvas_x1_$vid]
    global $var_canvas_x1
    set var_canvas_x2 [concat canvas_x2_$vid]
    global $var_canvas_x2
    set var_canvas_xpix [concat canvas_xpix_$vid]
    global $var_canvas_xpix
    set var_canvas_xmargin [concat canvas_xmargin_$vid]
    global $var_canvas_xmargin
    set var_canvas_y1 [concat canvas_y1_$vid]
    global $var_canvas_y1
    set var_canvas_y2 [concat canvas_y2_$vid]
    global $var_canvas_y2
    set var_canvas_ypix [concat canvas_ypix_$vid]
    global $var_canvas_ypix
    set var_canvas_ymargin [concat canvas_ymargin_$vid]
    global $var_canvas_ymargin

    pd [concat $id donecanvasdialog \
        [eval concat $$var_canvas_xscale] \
        [eval concat $$var_canvas_yscale] \
        [expr [eval concat $$var_canvas_graphme]+2*[eval concat $$var_canvas_hidetext]] \
        [eval concat $$var_canvas_x1] \
        [eval concat $$var_canvas_y1] \
        [eval concat $$var_canvas_x2] \
        [eval concat $$var_canvas_y2] \
        [eval concat $$var_canvas_xpix] \
        [eval concat $$var_canvas_ypix] \
        [eval concat $$var_canvas_xmargin] \
        [eval concat $$var_canvas_ymargin] \
        \;]
}

proc canvas_cancel {id} {
    set cmd [concat $id cancel \;]
    pd $cmd
}

proc canvas_ok {id} {
    canvas_apply $id
    canvas_cancel $id
}

proc canvas_checkcommand {id} {
    set vid [string trimleft $id .]
#    puts stderr [concat canvas_checkcommand $id $vid]

    set var_canvas_xscale [concat canvas_xscale_$vid]
    global $var_canvas_xscale
    set var_canvas_yscale [concat canvas_yscale_$vid]
    global $var_canvas_yscale
    set var_canvas_graphme [concat canvas_graphme_$vid]
    global $var_canvas_graphme
    set var_canvas_hidetext [concat canvas_hidetext_$vid]
    global $var_canvas_hidetext
    set var_canvas_x1 [concat canvas_x1_$vid]
    global $var_canvas_x1
    set var_canvas_x2 [concat canvas_x2_$vid]
    global $var_canvas_x2
    set var_canvas_xpix [concat canvas_xpix_$vid]
    global $var_canvas_xpix
    set var_canvas_xmargin [concat canvas_xmargin_$vid]
    global $var_canvas_xmargin
    set var_canvas_y1 [concat canvas_y1_$vid]
    global $var_canvas_y1
    set var_canvas_y2 [concat canvas_y2_$vid]
    global $var_canvas_y2
    set var_canvas_ypix [concat canvas_ypix_$vid]
    global $var_canvas_ypix
    set var_canvas_ymargin [concat canvas_ymargin_$vid]
    global $var_canvas_ymargin

    if { [eval concat $$var_canvas_graphme] != 0 } {
        $id.hidetext configure -state normal
        $id.xrange.entry1 configure -state normal
        $id.xrange.entry2 configure -state normal
        $id.xrange.entry3 configure -state normal
        $id.xrange.entry4 configure -state normal
        $id.yrange.entry1 configure -state normal
        $id.yrange.entry2 configure -state normal
        $id.yrange.entry3 configure -state normal
        $id.yrange.entry4 configure -state normal
        $id.xscale.entry configure -state disabled
        $id.yscale.entry configure -state disabled
        set x1 [eval concat $$var_canvas_x1]
        set y1 [eval concat $$var_canvas_y1]
        set x2 [eval concat $$var_canvas_x2]
        set y2 [eval concat $$var_canvas_y2]
        if { [eval concat $$var_canvas_x1] == 0 && \
             [eval concat $$var_canvas_y1] == 0 && \
             [eval concat $$var_canvas_x2] == 0 && \
             [eval concat $$var_canvas_y2] == 0 } {
                set $var_canvas_x2 1
                set $var_canvas_y2 1
        }
        if { [eval concat $$var_canvas_xpix] == 0 } {
            set $var_canvas_xpix 85
            set $var_canvas_xmargin 100
        }
        if { [eval concat $$var_canvas_ypix] == 0 } {
            set $var_canvas_ypix 60
            set $var_canvas_ymargin 100
        }
    } else {
        $id.hidetext configure -state disabled
        $id.xrange.entry1 configure -state disabled
        $id.xrange.entry2 configure -state disabled
        $id.xrange.entry3 configure -state disabled
        $id.xrange.entry4 configure -state disabled
        $id.yrange.entry1 configure -state disabled
        $id.yrange.entry2 configure -state disabled
        $id.yrange.entry3 configure -state disabled
        $id.yrange.entry4 configure -state disabled
        $id.xscale.entry configure -state normal
        $id.yscale.entry configure -state normal
        if { [eval concat $$var_canvas_xscale] == 0 } {
            set $var_canvas_xscale 1
        }
        if { [eval concat $$var_canvas_yscale] == 0 } {
            set $var_canvas_yscale -1
        }
    }
}

proc pdtk_canvas_dialog {id xscale yscale graphme x1 y1 x2 y2 \
    xpix ypix xmargin ymargin} {
    set vid [string trimleft $id .]

    set var_canvas_xscale [concat canvas_xscale_$vid]
    global $var_canvas_xscale
    set var_canvas_yscale [concat canvas_yscale_$vid]
    global $var_canvas_yscale
    set var_canvas_graphme [concat canvas_graphme_$vid]
    global $var_canvas_graphme
    set var_canvas_hidetext [concat canvas_hidetext_$vid]
    global $var_canvas_hidetext
    set var_canvas_x1 [concat canvas_x1_$vid]
    global $var_canvas_x1
    set var_canvas_x2 [concat canvas_x2_$vid]
    global $var_canvas_x2
    set var_canvas_xpix [concat canvas_xpix_$vid]
    global $var_canvas_xpix
    set var_canvas_xmargin [concat canvas_xmargin_$vid]
    global $var_canvas_xmargin
    set var_canvas_y1 [concat canvas_y1_$vid]
    global $var_canvas_y1
    set var_canvas_y2 [concat canvas_y2_$vid]
    global $var_canvas_y2
    set var_canvas_ypix [concat canvas_ypix_$vid]
    global $var_canvas_ypix
    set var_canvas_ymargin [concat canvas_ymargin_$vid]
    global $var_canvas_ymargin

    set $var_canvas_xscale $xscale
    set $var_canvas_yscale $yscale
    set $var_canvas_graphme [expr ($graphme!=0)?1:0]
    set $var_canvas_hidetext [expr ($graphme&2)?1:0]
    set $var_canvas_x1 $x1
    set $var_canvas_y1 $y1
    set $var_canvas_x2 $x2
    set $var_canvas_y2 $y2
    set $var_canvas_xpix $xpix
    set $var_canvas_ypix $ypix
    set $var_canvas_xmargin $xmargin
    set $var_canvas_ymargin $ymargin

    toplevel $id
    wm title $id {canvas}
    wm protocol $id WM_DELETE_WINDOW [concat canvas_cancel $id]

    label $id.toplabel -text "Canvas Properties"
    pack $id.toplabel -side top
    
    frame $id.xscale
    pack $id.xscale -side top
    label $id.xscale.label -text "X units per pixel"
    entry $id.xscale.entry -textvariable $var_canvas_xscale -width 10
    pack $id.xscale.label $id.xscale.entry -side left

    frame $id.yscale
    pack $id.yscale -side top
    label $id.yscale.label -text "Y units per pixel"
    entry $id.yscale.entry -textvariable $var_canvas_yscale -width 10
    pack $id.yscale.label $id.yscale.entry -side left

    checkbutton $id.graphme -text {graph on parent} \
        -variable $var_canvas_graphme -anchor w \
        -command [concat canvas_checkcommand $id]
    pack $id.graphme -side top

    checkbutton $id.hidetext -text {hide object name and arguments} \
        -variable $var_canvas_hidetext -anchor w \
        -command [concat canvas_checkcommand $id]
    pack $id.hidetext -side top

    frame $id.xrange
    pack $id.xrange -side top
    label $id.xrange.label1 -text "X range: from"
    entry $id.xrange.entry1 -textvariable $var_canvas_x1 -width 6
    label $id.xrange.label2 -text "to"
    entry $id.xrange.entry2 -textvariable $var_canvas_x2 -width 6
    label $id.xrange.label3 -text "size"
    entry $id.xrange.entry3 -textvariable $var_canvas_xpix -width 4
    label $id.xrange.label4 -text "margin"
    entry $id.xrange.entry4 -textvariable $var_canvas_xmargin -width 4
    pack $id.xrange.label1 $id.xrange.entry1 \
        $id.xrange.label2 $id.xrange.entry2 \
        $id.xrange.label3 $id.xrange.entry3 \
        $id.xrange.label4 $id.xrange.entry4 \
        -side left

    frame $id.yrange
    pack $id.yrange -side top
    label $id.yrange.label1 -text "Y range: from"
    entry $id.yrange.entry1 -textvariable $var_canvas_y1 -width 6
    label $id.yrange.label2 -text "to"
    entry $id.yrange.entry2 -textvariable $var_canvas_y2 -width 6
    label $id.yrange.label3 -text "size"
    entry $id.yrange.entry3 -textvariable $var_canvas_ypix -width 4
    label $id.yrange.label4 -text "margin"
    entry $id.yrange.entry4 -textvariable $var_canvas_ymargin -width 4
    pack $id.yrange.label1 $id.yrange.entry1 \
        $id.yrange.label2 $id.yrange.entry2 \
        $id.yrange.label3 $id.yrange.entry3 \
        $id.yrange.label4 $id.yrange.entry4 \
        -side left

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "canvas_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "canvas_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "canvas_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    pack $id.buttonframe.apply -side left -expand 1
    pack $id.buttonframe.ok -side left -expand 1

    bind $id.xscale.entry <KeyPress-Return> [concat canvas_ok $id]
    bind $id.yscale.entry <KeyPress-Return> [concat canvas_ok $id]
    pdtk_standardkeybindings $id.xscale.entry
    pdtk_standardkeybindings $id.yscale.entry
    $id.xscale.entry select from 0
    $id.xscale.entry select adjust end
    focus $id.xscale.entry
    canvas_checkcommand $id
}

############ pdtk_data_dialog -- run a data dialog #########
proc dodata_send {name} {
#    puts stderr [$name.text get 0.0 end]

    for {set i 1} {[$name.text compare [concat $i.0 + 3 chars] < end]} \
            {incr i 1} {
#       puts stderr [concat it's [$name.text get $i.0 [expr $i + 1].0]]
        set cmd [concat $name data [$name.text get $i.0 [expr $i + 1].0] \;]
#       puts stderr $cmd
        pd $cmd
    }
    set cmd [concat $name end \;]
#    puts stderr $cmd
    pd $cmd
}

proc dodata_cancel {name} {
    set cmd [concat $name cancel \;]
#    puts stderr $cmd
    pd $cmd
}

proc dodata_ok {name} {
    dodata_send $name
    dodata_cancel $name
}

proc pdtk_data_dialog {name stuff} {
    global pd_deffont
    toplevel $name
    wm title $name {Atom}
    wm protocol $name WM_DELETE_WINDOW [concat dodata_cancel $name]

    frame $name.buttonframe
    pack $name.buttonframe -side bottom -fill x -pady 2m
    button $name.buttonframe.send -text {Send (Ctrl s)}\
        -command [concat dodata_send $name]
    button $name.buttonframe.ok -text {OK (Ctrl t)}\
        -command [concat dodata_ok $name]
    pack $name.buttonframe.send -side left -expand 1
    pack $name.buttonframe.ok -side left -expand 1

    text $name.text -relief raised -bd 2 -height 40 -width 60 \
        -yscrollcommand "$name.scroll set" -font $pd_deffont
    scrollbar $name.scroll -command "$name.text yview"
    pack $name.scroll -side right -fill y
    pack $name.text -side left -fill both -expand 1
    $name.text insert end $stuff
    focus $name.text
    bind $name.text <Control-t> [concat dodata_ok $name]
    bind $name.text <Control-s> [concat dodata_send $name]
}

############ check or uncheck the "edit" menu item ##############
#####################iemlib#######################
proc pdtk_canvas_editval {name value} {
    if { $value } {
        $name.m.edit entryconfigure "Edit mode" -indicatoron true
    } else {                          
        $name.m.edit entryconfigure "Edit mode" -indicatoron false
    }                                                 
}
#####################iemlib#######################

############ pdtk_text_new -- create a new text object #2###########
proc pdtk_text_new {canvasname myname x y text font color} {
#    if {$font < 13} {set fontname [format -*-courier-bold----%d-* $font]}
#    if {$font >= 13} {set fontname [format -*-courier-----%d-* $font]}

        global pd_fontlist 
        switch -- $font {
                8  { set typeface [lindex $pd_fontlist 0] }
                9  { set typeface [lindex $pd_fontlist 1] }
                10 { set typeface [lindex $pd_fontlist 2] }
                12 { set typeface [lindex $pd_fontlist 3] }
                14 { set typeface [lindex $pd_fontlist 4] }
                16 { set typeface [lindex $pd_fontlist 5] }
                18 { set typeface [lindex $pd_fontlist 6] }
                24 { set typeface [lindex $pd_fontlist 7] }
                30 { set typeface [lindex $pd_fontlist 8] }
                36 { set typeface [lindex $pd_fontlist 9] }
        }

    $canvasname create text $x $y \
        -font $typeface \
        -tags $myname -text $text -fill $color  -anchor nw 
#    pd [concat $myname size [$canvasname bbox $myname] \;]
}

################ pdtk_text_set -- change the text ##################
proc pdtk_text_set {canvasname myname text} {
    $canvasname itemconfig $myname -text $text
#    pd [concat $myname size [$canvasname bbox $myname] \;]
}

############### event binding procedures for Pd window ################

proc pdtk_pd_ctrlkey {name key shift} {
#    puts stderr [concat key $key shift $shift]
#    .dummy itemconfig goo -text [concat ---> control-key event $key];
    if {$key == "n" || $key == "N"} {menu_new}
    if {$key == "o" || $key == "O"} {menu_open .}
    if {$key == "m" || $key == "M"} {menu_send}
    if {$key == "q" || $key == "Q"} {
        if {$shift == 1} {menu_really_quit} else    {menu_quit}
    }
    if {$key == "slash"} {menu_audio 1}
    if {$key == "period"} {menu_audio 0}
}

######### startup function.  ##############
# Tell pd the current directory; this is used in case the command line
# asked pd to open something.  Also, get character width and height for
# seven "useful" font sizes.

# tb: user defined typefaces
proc pdtk_pd_startup {version apilist midiapilist fontname_from_pd \
        fontweight_from_pd} {
#    puts stderr [concat $version $apilist $fontname]
    global pd_myversion pd_apilist pd_midiapilist pd_nt
    set pd_myversion $version
    set pd_apilist $apilist
    set pd_midiapilist $midiapilist
     global fontname fontweight
     set fontname $fontname_from_pd
     set fontweight $fontweight_from_pd
    global pd_fontlist
    set pd_fontlist {}

    set fontlist ""
    foreach i {8 9 10 12 14 16 18 24 30 36} {
       set font [format {{%s} %d %s} $fontname_from_pd -$i $fontweight_from_pd]
       set pd_fontlist [linsert $pd_fontlist 100000 $font] 
       set width0 [font measure  $font x]
       set height0 [lindex [font metrics $font] 5]
       set fontlist [concat $fontlist $i [font measure  $font x] \
           [lindex [font metrics $font] 5]]
    }

    set tclpatch [info patchlevel]
    if {$tclpatch == "8.3.0" || \
        $tclpatch == "8.3.1" || \
        $tclpatch == "8.3.2" || \
        $tclpatch == "8.3.3" } {
        set oldtclversion 1
    } else {
        set oldtclversion 0
    }
    pd [concat pd init [pdtk_enquote [pwd]] $oldtclversion $fontlist \;];

    # add the audio and help menus to the Pd window.  We delayed this
    # so that we'd know the value of "apilist".
    menu_addstd .mbar 

    global pd_nt
    if {$pd_nt == 2} {
        global pd_macdropped pd_macready
        set pd_macready 1
        foreach file $pd_macdropped {
            pd [concat pd open [pdtk_enquote [file tail $file]] \
                [pdtk_enquote  [file dirname $file]] \;]
                menu_doc_open [file dirname $file] [file tail $file]
        }
    }
}

##################### DSP ON/OFF, METERS, DIO ERROR ###################
proc pdtk_pd_dsp {value} {
    global ctrls_audio_on
    if {$value == "ON"} {set ctrls_audio_on 1} else {set ctrls_audio_on 0}
#    puts stderr [concat its $ctrls_audio_on]
}

proc pdtk_pd_meters {indb outdb inclip outclip} {
#    puts stderr [concat meters $indb $outdb $inclip $outclip]
    global ctrls_inlevel ctrls_outlevel
    set ctrls_inlevel $indb
    if {$inclip == 1} {
        .controls.inout.in.clip configure -background red
    } else {
        .controls.inout.in.clip configure -background grey
    }
    set ctrls_outlevel $outdb
    if {$outclip == 1} {
        .controls.inout.out.clip configure -background red
    } else {
        .controls.inout.out.clip configure -background grey
    }
    
}

proc pdtk_pd_dio {red} {
#    puts stderr [concat dio $red]
    if {$red == 1} {
        .controls.dio configure -background red -activebackground red
    } else {
        .controls.dio configure -background grey -activebackground lightgrey
    }
        
}

############# text editing from the "edit" menu ###################
set edit_number 1

proc texteditor_send {name} {
    set topname [string trimright $name .text]
    for {set i 0} \
        {[$name compare [concat 0.0 + [expr $i + 1] chars] < end]} \
            {incr i 1} {
        set cha [$name get [concat 0.0 + $i chars]]
        scan $cha %c keynum
        pd [concat pd key 1 $keynum 0 \;]
    }
}

proc texteditor_ok {name} {
    set topname [string trimright $name .text]
    texteditor_send $name
    destroy $topname
}


proc pdtk_pd_texteditor {stuff} {
    global edit_number pd_deffont
    set name [format ".text%d" $edit_number]
    set edit_number [expr $edit_number + 1]

    toplevel $name
    wm title $name {TEXT}

    frame $name.buttons
    pack $name.buttons -side bottom -fill x -pady 2m
    button $name.buttons.send -text {Send (Ctrl s)}\
        -command "texteditor_send $name.text"
    button $name.buttons.ok -text {OK (Ctrl t)}\
        -command "texteditor_ok $name.text"
    pack $name.buttons.send -side left -expand 1
    pack $name.buttons.ok -side left -expand 1

    text $name.text -relief raised -bd 2 -height 12 -width 60 \
        -yscrollcommand "$name.scroll set" -font $pd_deffont
    scrollbar $name.scroll -command "$name.text yview"
    pack $name.scroll -side right -fill y
    pack $name.text -side left -fill both -expand 1
    $name.text insert end $stuff
    focus $name.text
    bind $name.text <Control-t> {texteditor_ok %W}
    bind $name.text <Control-s> {texteditor_send %W}
}

#  paste text into a text box
proc pdtk_pastetext {} {
    global pdtk_pastebuffer
    set pdtk_pastebuffer ""
    catch {global pdtk_pastebuffer; set pdtk_pastebuffer [clipboard get]}
#    puts stderr [concat paste $pdtk_pastebuffer]
    for {set i 0} {$i < [string length $pdtk_pastebuffer]} {incr i 1} {
        set cha [string index $pdtk_pastebuffer $i]
        scan $cha %c keynum
        pd [concat pd key 1 $keynum 0 \;]
    }
}

############# open and save dialogs for objects in Pd ##########

proc pdtk_openpanel {target localdir} {
    global pd_opendir
    if {$localdir == ""} {
      set localdir $pd_opendir
    }
    set filename [tk_getOpenFile -initialdir $localdir]
    if {$filename != ""} {
        set directory [string range $filename 0 \
            [expr [string last / $filename ] - 1]]
        set pd_opendir $directory

        pd [concat $target callback [pdtk_enquote $filename] \;]
    }
}

proc pdtk_savepanel {target localdir} {
    global pd_savedir
    if {$localdir == ""} {
      set localdir $pd_savedir
    }
    set filename [tk_getSaveFile -initialdir $localdir]
    if {$filename != ""} {
        pd [concat $target callback [pdtk_enquote $filename] \;]
    }
}

########################### comport hack ########################

set com1 0
set com2 0
set com3 0
set com4 0

proc com1_open {} {
    global com1
    set com1 [open com1 w]
    .dummy itemconfig goo -text $com1
    fconfigure $com1 -buffering none
    fconfigure $com1 -mode 19200,e,8,2
}

proc com1_send {str} {
    global com1
    puts -nonewline $com1 $str
}


############# start a polling process to watch the socket ##############
# this is needed for nt, and presumably for Mac as well.
# in UNIX this is handled by a tcl callback (set up in t_tkcmd.c)

if {$pd_nt == 1} {
    proc polleofloop {} {
        pd_pollsocket
        after 20 polleofloop
    }

    polleofloop
}

####################### audio dialog ##################3

proc audio_apply {id} {
    global audio_indev1 audio_indev2 audio_indev3 audio_indev4 
    global audio_inchan1 audio_inchan2 audio_inchan3 audio_inchan4
    global audio_inenable1 audio_inenable2 audio_inenable3 audio_inenable4
    global audio_outdev1 audio_outdev2 audio_outdev3 audio_outdev4 
    global audio_outchan1 audio_outchan2 audio_outchan3 audio_outchan4
    global audio_outenable1 audio_outenable2 audio_outenable3 audio_outenable4
    global audio_sr audio_advance audio_callback

    pd [concat pd audio-dialog \
        $audio_indev1 \
        $audio_indev2 \
        $audio_indev3 \
        $audio_indev4 \
        [expr $audio_inchan1 * ( $audio_inenable1 ? 1 : -1 ) ]\
        [expr $audio_inchan2 * ( $audio_inenable2 ? 1 : -1 ) ]\
        [expr $audio_inchan3 * ( $audio_inenable3 ? 1 : -1 ) ]\
        [expr $audio_inchan4 * ( $audio_inenable4 ? 1 : -1 ) ]\
        $audio_outdev1 \
        $audio_outdev2 \
        $audio_outdev3 \
        $audio_outdev4 \
        [expr $audio_outchan1 * ( $audio_outenable1 ? 1 : -1 ) ]\
        [expr $audio_outchan2 * ( $audio_outenable2 ? 1 : -1 ) ]\
        [expr $audio_outchan3 * ( $audio_outenable3 ? 1 : -1 ) ]\
        [expr $audio_outchan4 * ( $audio_outenable4 ? 1 : -1 ) ]\
        $audio_sr \
        $audio_advance \
        $audio_callback \
        \;]
}

proc audio_cancel {id} {
    pd [concat $id cancel \;]
}

proc audio_ok {id} {
    audio_apply $id
    audio_cancel $id
}

# callback from popup menu
proc audio_popup_action {buttonname varname devlist index} {
    global audio_indevlist audio_outdevlist $varname
    $buttonname configure -text [lindex $devlist $index]
#    puts stderr [concat popup_action $buttonname $varname $index]
    set $varname $index
}

# create a popup menu
proc audio_popup {name buttonname varname devlist} {
    global pd_nt
    if [winfo exists $name.popup] {destroy $name.popup}
    menu $name.popup -tearoff false
    if {$pd_nt == 1} {
    $name.popup configure -font menuFont
    }
#    puts stderr [concat $devlist ]
    for {set x 0} {$x<[llength $devlist]} {incr x} {
        $name.popup add command -label [lindex $devlist $x] \
            -command [list audio_popup_action \
                $buttonname $varname $devlist $x] 
    }
    tk_popup $name.popup [winfo pointerx $name] [winfo pointery $name] 0
}

# start a dialog window to select audio devices and settings.  "multi"
# is 0 if only one device is allowed; 1 if one apiece may be specified for
# input and output; and 2 if we can select multiple devices.  "longform"
# (which only makes sense if "multi" is 2) asks us to make controls for
# opening several devices; if not, we get an extra button to turn longform
# on and restart the dialog.

proc pdtk_audio_dialog {id indev1 indev2 indev3 indev4 \
        inchan1 inchan2 inchan3 inchan4 \
        outdev1 outdev2 outdev3 outdev4 \
        outchan1 outchan2 outchan3 outchan4 sr advance multi callback \
        longform} {
    global audio_indev1 audio_indev2 audio_indev3 audio_indev4 
    global audio_inchan1 audio_inchan2 audio_inchan3 audio_inchan4
    global audio_inenable1 audio_inenable2 audio_inenable3 audio_inenable4
    global audio_outdev1 audio_outdev2 audio_outdev3 audio_outdev4
    global audio_outchan1 audio_outchan2 audio_outchan3 audio_outchan4
    global audio_outenable1 audio_outenable2 audio_outenable3 audio_outenable4
    global audio_sr audio_advance audio_callback
    global audio_indevlist audio_outdevlist
    global pd_indev pd_outdev

    set audio_indev1 $indev1
    set audio_indev2 $indev2
    set audio_indev3 $indev3
    set audio_indev4 $indev4

    set audio_inchan1 [expr ( $inchan1 > 0 ? $inchan1 : -$inchan1 ) ]
    set audio_inenable1 [expr $inchan1 > 0 ]
    set audio_inchan2 [expr ( $inchan2 > 0 ? $inchan2 : -$inchan2 ) ]
    set audio_inenable2 [expr $inchan2 > 0 ]
    set audio_inchan3 [expr ( $inchan3 > 0 ? $inchan3 : -$inchan3 ) ]
    set audio_inenable3 [expr $inchan3 > 0 ]
    set audio_inchan4 [expr ( $inchan4 > 0 ? $inchan4 : -$inchan4 ) ]
    set audio_inenable4 [expr $inchan4 > 0 ]

    set audio_outdev1 $outdev1
    set audio_outdev2 $outdev2
    set audio_outdev3 $outdev3
    set audio_outdev4 $outdev4

    set audio_outchan1 [expr ( $outchan1 > 0 ? $outchan1 : -$outchan1 ) ]
    set audio_outenable1 [expr $outchan1 > 0 ]
    set audio_outchan2 [expr ( $outchan2 > 0 ? $outchan2 : -$outchan2 ) ]
    set audio_outenable2 [expr $outchan2 > 0 ]
    set audio_outchan3 [expr ( $outchan3 > 0 ? $outchan3 : -$outchan3 ) ]
    set audio_outenable3 [expr $outchan3 > 0 ]
    set audio_outchan4 [expr ( $outchan4 > 0 ? $outchan4 : -$outchan4 ) ]
    set audio_outenable4 [expr $outchan4 > 0 ]

    set audio_sr $sr
    set audio_advance $advance
    set audio_callback $callback
    toplevel $id
    wm title $id {audio}
    wm protocol $id WM_DELETE_WINDOW [concat audio_cancel $id]

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "audio_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "audio_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "audio_ok $id"
    button $id.buttonframe.save -text {Save all settings}\
        -command "audio_apply $id \; pd pd save-preferences \\;"
    pack $id.buttonframe.cancel $id.buttonframe.apply $id.buttonframe.ok \
        $id.buttonframe.save -side left -expand 1
    
        # sample rate and advance
    frame $id.srf
    pack $id.srf -side top
    
    label $id.srf.l1 -text "sample rate:"
    entry $id.srf.x1 -textvariable audio_sr -width 7
    label $id.srf.l2 -text "delay (msec):"
    entry $id.srf.x2 -textvariable audio_advance -width 4
    pack $id.srf.l1 $id.srf.x1 $id.srf.l2 $id.srf.x2 -side left
    if {$audio_callback >= 0} {
        checkbutton $id.srf.x3 -variable audio_callback \
            -text {use callbacks} -anchor e
        pack $id.srf.x3 -side left
    }
        # input device 1
    frame $id.in1f
    pack $id.in1f -side top

    checkbutton $id.in1f.x0 -variable audio_inenable1 \
        -text {input device 1} -anchor e
    button $id.in1f.x1 -text [lindex $audio_indevlist $audio_indev1] \
        -command [list audio_popup $id $id.in1f.x1 audio_indev1 $audio_indevlist]
    label $id.in1f.l2 -text "channels:"
    entry $id.in1f.x2 -textvariable audio_inchan1 -width 3
    pack $id.in1f.x0 $id.in1f.x1 $id.in1f.l2 $id.in1f.x2 -side left

        # input device 2
    if {$longform && $multi > 1 && [llength $audio_indevlist] > 1} {
        frame $id.in2f
        pack $id.in2f -side top

        checkbutton $id.in2f.x0 -variable audio_inenable2 \
            -text {input device 2} -anchor e
        button $id.in2f.x1 -text [lindex $audio_indevlist $audio_indev2] \
            -command [list audio_popup $id $id.in2f.x1 audio_indev2 \
                $audio_indevlist]
        label $id.in2f.l2 -text "channels:"
        entry $id.in2f.x2 -textvariable audio_inchan2 -width 3
        pack $id.in2f.x0 $id.in2f.x1 $id.in2f.l2 $id.in2f.x2 -side left
    }

        # input device 3
    if {$longform && $multi > 1 && [llength $audio_indevlist] > 2} {
        frame $id.in3f
        pack $id.in3f -side top

        checkbutton $id.in3f.x0 -variable audio_inenable3 \
            -text {input device 3} -anchor e
        button $id.in3f.x1 -text [lindex $audio_indevlist $audio_indev3] \
            -command [list audio_popup $id $id.in3f.x1 audio_indev3 \
                $audio_indevlist]
        label $id.in3f.l2 -text "channels:"
        entry $id.in3f.x2 -textvariable audio_inchan3 -width 3
        pack $id.in3f.x0 $id.in3f.x1 $id.in3f.l2 $id.in3f.x2 -side left
    }

        # input device 4
    if {$longform && $multi > 1 && [llength $audio_indevlist] > 3} {
        frame $id.in4f
        pack $id.in4f -side top

        checkbutton $id.in4f.x0 -variable audio_inenable4 \
            -text {input device 4} -anchor e
        button $id.in4f.x1 -text [lindex $audio_indevlist $audio_indev4] \
            -command [list audio_popup $id $id.in4f.x1 audio_indev4 \
                $audio_indevlist]
        label $id.in4f.l2 -text "channels:"
        entry $id.in4f.x2 -textvariable audio_inchan4 -width 3
        pack $id.in4f.x0 $id.in4f.x1 $id.in4f.l2 $id.in4f.x2 -side left
    }

        # output device 1
    frame $id.out1f
    pack $id.out1f -side top

    checkbutton $id.out1f.x0 -variable audio_outenable1 \
        -text {output device 1} -anchor e
    if {$multi == 0} {
        label $id.out1f.l1 \
            -text "(same as input device) ..............      "
    } else {
        button $id.out1f.x1 -text [lindex $audio_outdevlist $audio_outdev1] \
            -command  [list audio_popup $id $id.out1f.x1 audio_outdev1 \
                $audio_outdevlist]
    }
    label $id.out1f.l2 -text "channels:"
    entry $id.out1f.x2 -textvariable audio_outchan1 -width 3
    if {$multi == 0} {
        pack $id.out1f.x0 $id.out1f.l1 $id.out1f.x2 -side left
    } else {
        pack $id.out1f.x0 $id.out1f.x1 $id.out1f.l2 $id.out1f.x2 -side left
    }

        # output device 2
    if {$longform && $multi > 1 && [llength $audio_outdevlist] > 1} {
        frame $id.out2f
        pack $id.out2f -side top

        checkbutton $id.out2f.x0 -variable audio_outenable2 \
            -text {output device 2} -anchor e
        button $id.out2f.x1 -text [lindex $audio_outdevlist $audio_outdev2] \
            -command \
            [list audio_popup $id $id.out2f.x1 audio_outdev2 $audio_outdevlist]
        label $id.out2f.l2 -text "channels:"
        entry $id.out2f.x2 -textvariable audio_outchan2 -width 3
        pack $id.out2f.x0 $id.out2f.x1 $id.out2f.l2 $id.out2f.x2 -side left
    }

        # output device 3
    if {$longform && $multi > 1 && [llength $audio_outdevlist] > 2} {
        frame $id.out3f
        pack $id.out3f -side top

        checkbutton $id.out3f.x0 -variable audio_outenable3 \
            -text {output device 3} -anchor e
        button $id.out3f.x1 -text [lindex $audio_outdevlist $audio_outdev3] \
            -command \
            [list audio_popup $id $id.out3f.x1 audio_outdev3 $audio_outdevlist]
        label $id.out3f.l2 -text "channels:"
        entry $id.out3f.x2 -textvariable audio_outchan3 -width 3
        pack $id.out3f.x0 $id.out3f.x1 $id.out3f.l2 $id.out3f.x2 -side left
    }

        # output device 4
    if {$longform && $multi > 1 && [llength $audio_outdevlist] > 3} {
        frame $id.out4f
        pack $id.out4f -side top

        checkbutton $id.out4f.x0 -variable audio_outenable4 \
            -text {output device 4} -anchor e
        button $id.out4f.x1 -text [lindex $audio_outdevlist $audio_outdev4] \
            -command \
            [list audio_popup $id $id.out4f.x1 audio_outdev4 $audio_outdevlist]
        label $id.out4f.l2 -text "channels:"
        entry $id.out4f.x2 -textvariable audio_outchan4 -width 3
        pack $id.out4f.x0 $id.out4f.x1 $id.out4f.l2 $id.out4f.x2 -side left
    }

        # if not the "long form" but if "multi" is 2, make a button to
        # restart with longform set. 
    
    if {$longform == 0 && $multi > 1} {
        frame $id.longbutton
        pack $id.longbutton -side top
        button $id.longbutton.b -text {use multiple devices} \
            -command  {pd pd audio-properties 1 \;}
        pack $id.longbutton.b
    }
    bind $id.srf.x1 <KeyPress-Return> [concat audio_ok $id]
    bind $id.srf.x2 <KeyPress-Return> [concat audio_ok $id]
    bind $id.in1f.x2 <KeyPress-Return> [concat audio_ok $id]
    bind $id.out1f.x2 <KeyPress-Return> [concat audio_ok $id]
    $id.srf.x1 select from 0
    $id.srf.x1 select adjust end
    focus $id.srf.x1
    pdtk_standardkeybindings $id.srf.x1
    pdtk_standardkeybindings $id.srf.x2
    pdtk_standardkeybindings $id.in1f.x2
    pdtk_standardkeybindings $id.out1f.x2
}

####################### midi dialog ##################

proc midi_apply {id} {
    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4
    global midi_alsain midi_alsaout

    pd [concat pd midi-dialog \
        $midi_indev1 \
        $midi_indev2 \
        $midi_indev3 \
        $midi_indev4 \
        $midi_outdev1 \
        $midi_outdev2 \
        $midi_outdev3 \
        $midi_outdev4 \
        $midi_alsain \
        $midi_alsaout \
        \;]
}

proc midi_cancel {id} {
    pd [concat $id cancel \;]
}

proc midi_ok {id} {
    midi_apply $id
    midi_cancel $id
}

# callback from popup menu
proc midi_popup_action {buttonname varname devlist index} {
    global midi_indevlist midi_outdevlist $varname
    $buttonname configure -text [lindex $devlist $index]
#    puts stderr [concat popup_action $buttonname $varname $index]
    set $varname $index
}

# create a popup menu
proc midi_popup {name buttonname varname devlist} {
    global pd_nt
    if [winfo exists $name.popup] {destroy $name.popup}
    menu $name.popup -tearoff false
    if {$pd_nt == 1} {
    $name.popup configure -font menuFont
    }
#    puts stderr [concat $devlist ]
    for {set x 0} {$x<[llength $devlist]} {incr x} {
        $name.popup add command -label [lindex $devlist $x] \
            -command [list midi_popup_action \
                $buttonname $varname $devlist $x] 
    }
    tk_popup $name.popup [winfo pointerx $name] [winfo pointery $name] 0
}

# start a dialog window to select midi devices.  "longform" asks us to make
# controls for opening several devices; if not, we get an extra button to
# turn longform on and restart the dialog.
proc pdtk_midi_dialog {id indev1 indev2 indev3 indev4 \
        outdev1 outdev2 outdev3 outdev4 longform} {
    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4
    global midi_indevlist midi_outdevlist
    global midi_alsain midi_alsaout

    set midi_indev1 $indev1
    set midi_indev2 $indev2
    set midi_indev3 $indev3
    set midi_indev4 $indev4
    set midi_outdev1 $outdev1
    set midi_outdev2 $outdev2
    set midi_outdev3 $outdev3
    set midi_outdev4 $outdev4
    set midi_alsain [llength $midi_indevlist]
    set midi_alsaout [llength $midi_outdevlist]

    toplevel $id
    wm title $id {midi}
    wm protocol $id WM_DELETE_WINDOW [concat midi_cancel $id]

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "midi_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "midi_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "midi_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    pack $id.buttonframe.apply -side left -expand 1
    pack $id.buttonframe.ok -side left -expand 1
    
        # input device 1
    frame $id.in1f
    pack $id.in1f -side top

    label $id.in1f.l1 -text "input device 1:"
    button $id.in1f.x1 -text [lindex $midi_indevlist $midi_indev1] \
        -command [list midi_popup $id $id.in1f.x1 midi_indev1 $midi_indevlist]
    pack $id.in1f.l1 $id.in1f.x1 -side left

        # input device 2
    if {$longform && [llength $midi_indevlist] > 2} {
        frame $id.in2f
        pack $id.in2f -side top

        label $id.in2f.l1 -text "input device 2:"
        button $id.in2f.x1 -text [lindex $midi_indevlist $midi_indev2] \
            -command [list midi_popup $id $id.in2f.x1 midi_indev2 \
                $midi_indevlist]
        pack $id.in2f.l1 $id.in2f.x1 -side left
    }

        # input device 3
    if {$longform && [llength $midi_indevlist] > 3} {
        frame $id.in3f
        pack $id.in3f -side top

        label $id.in3f.l1 -text "input device 3:"
        button $id.in3f.x1 -text [lindex $midi_indevlist $midi_indev3] \
            -command [list midi_popup $id $id.in3f.x1 midi_indev3 \
                $midi_indevlist]
        pack $id.in3f.l1 $id.in3f.x1 -side left
    }

        # input device 4
    if {$longform && [llength $midi_indevlist] > 4} {
        frame $id.in4f
        pack $id.in4f -side top

        label $id.in4f.l1 -text "input device 4:"
        button $id.in4f.x1 -text [lindex $midi_indevlist $midi_indev4] \
            -command [list midi_popup $id $id.in4f.x1 midi_indev4 \
                $midi_indevlist]
        pack $id.in4f.l1 $id.in4f.x1 -side left
    }

        # output device 1

    frame $id.out1f
    pack $id.out1f -side top
    label $id.out1f.l1 -text "output device 1:"
    button $id.out1f.x1 -text [lindex $midi_outdevlist $midi_outdev1] \
        -command [list midi_popup $id $id.out1f.x1 midi_outdev1 \
            $midi_outdevlist]
    pack $id.out1f.l1 $id.out1f.x1 -side left

        # output device 2
    if {$longform && [llength $midi_outdevlist] > 2} {
        frame $id.out2f
        pack $id.out2f -side top
        label $id.out2f.l1 -text "output device 2:"
        button $id.out2f.x1 -text [lindex $midi_outdevlist $midi_outdev2] \
            -command \
            [list midi_popup $id $id.out2f.x1 midi_outdev2 $midi_outdevlist]
        pack $id.out2f.l1 $id.out2f.x1 -side left
    }

        # output device 3
    if {$longform && [llength $midi_midi_outdevlist] > 3} {
        frame $id.out3f
        pack $id.out3f -side top
        label $id.out3f.l1 -text "output device 3:"
        button $id.out3f.x1 -text [lindex $midi_outdevlist $midi_outdev3] \
            -command \
            [list midi_popup $id $id.out3f.x1 midi_outdev3 $midi_outdevlist]
        pack $id.out3f.l1 $id.out3f.x1 -side left
    }

        # output device 4
    if {$longform && [llength $midi_midi_outdevlist] > 4} {
        frame $id.out4f
        pack $id.out4f -side top
        label $id.out4f.l1 -text "output device 4:"
        button $id.out4f.x1 -text [lindex $midi_outdevlist $midi_outdev4] \
            -command \
            [list midi_popup $id $id.out4f.x1 midi_outdev4 $midi_outdevlist]
        pack $id.out4f.l1 $id.out4f.x1 -side left
    }

        # if not the "long form" make a button to
        # restart with longform set. 
    
    if {$longform == 0} {
        frame $id.longbutton
        pack $id.longbutton -side top
        button $id.longbutton.b -text {use multiple devices} \
            -command  {pd pd midi-properties 1 \;}
        pack $id.longbutton.b
    }
}

proc pdtk_alsa_midi_dialog {id indev1 indev2 indev3 indev4 \
        outdev1 outdev2 outdev3 outdev4 longform alsa} {
    global midi_indev1 midi_indev2 midi_indev3 midi_indev4 
    global midi_outdev1 midi_outdev2 midi_outdev3 midi_outdev4
    global midi_indevlist midi_outdevlist
    global midi_alsain midi_alsaout

    set midi_indev1 $indev1
    set midi_indev2 $indev2
    set midi_indev3 $indev3
    set midi_indev4 $indev4
    set midi_outdev1 $outdev1
    set midi_outdev2 $outdev2
    set midi_outdev3 $outdev3
    set midi_outdev4 $outdev4
    set midi_alsain [llength $midi_indevlist]
    set midi_alsaout [llength $midi_outdevlist]
    
    toplevel $id
    wm title $id {midi}
    wm protocol $id WM_DELETE_WINDOW [concat midi_cancel $id]

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "midi_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "midi_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "midi_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    pack $id.buttonframe.apply -side left -expand 1
    pack $id.buttonframe.ok -side left -expand 1

    frame $id.in1f
    pack $id.in1f -side top

  if {$alsa == 0} {
        # input device 1
    label $id.in1f.l1 -text "input device 1:"
    button $id.in1f.x1 -text [lindex $midi_indevlist $midi_indev1] \
        -command [list midi_popup $id $id.in1f.x1 midi_indev1 $midi_indevlist]
    pack $id.in1f.l1 $id.in1f.x1 -side left

        # input device 2
    if {$longform && [llength $midi_indevlist] > 2} {
        frame $id.in2f
        pack $id.in2f -side top

        label $id.in2f.l1 -text "input device 2:"
        button $id.in2f.x1 -text [lindex $midi_indevlist $midi_indev2] \
            -command [list midi_popup $id $id.in2f.x1 midi_indev2 \
                $midi_indevlist]
        pack $id.in2f.l1 $id.in2f.x1 -side left
    }

        # input device 3
    if {$longform && [llength $midi_indevlist] > 3} {
        frame $id.in3f
        pack $id.in3f -side top

        label $id.in3f.l1 -text "input device 3:"
        button $id.in3f.x1 -text [lindex $midi_indevlist $midi_indev3] \
            -command [list midi_popup $id $id.in3f.x1 midi_indev3 \
                $midi_indevlist]
        pack $id.in3f.l1 $id.in3f.x1 -side left
    }

        # input device 4
    if {$longform && [llength $midi_indevlist] > 4} {
        frame $id.in4f
        pack $id.in4f -side top

        label $id.in4f.l1 -text "input device 4:"
        button $id.in4f.x1 -text [lindex $midi_indevlist $midi_indev4] \
            -command [list midi_popup $id $id.in4f.x1 midi_indev4 \
                $midi_indevlist]
        pack $id.in4f.l1 $id.in4f.x1 -side left
    }

        # output device 1

    frame $id.out1f
    pack $id.out1f -side top
    label $id.out1f.l1 -text "output device 1:"
    button $id.out1f.x1 -text [lindex $midi_outdevlist $midi_outdev1] \
        -command [list midi_popup $id $id.out1f.x1 midi_outdev1 \
            $midi_outdevlist]
    pack $id.out1f.l1 $id.out1f.x1 -side left

        # output device 2
    if {$longform && [llength $midi_outdevlist] > 2} {
        frame $id.out2f
        pack $id.out2f -side top
        label $id.out2f.l1 -text "output device 2:"
        button $id.out2f.x1 -text [lindex $midi_outdevlist $midi_outdev2] \
            -command \
            [list midi_popup $id $id.out2f.x1 midi_outdev2 $midi_outdevlist]
        pack $id.out2f.l1 $id.out2f.x1 -side left
    }

        # output device 3
    if {$longform && [llength $midi_outdevlist] > 3} {
        frame $id.out3f
        pack $id.out3f -side top
        label $id.out3f.l1 -text "output device 3:"
        button $id.out3f.x1 -text [lindex $midi_outdevlist $midi_outdev3] \
            -command \
            [list midi_popup $id $id.out3f.x1 midi_outdev3 $midi_outdevlist]
        pack $id.out3f.l1 $id.out3f.x1 -side left
    }

        # output device 4
    if {$longform && [llength $midi_outdevlist] > 4} {
        frame $id.out4f
        pack $id.out4f -side top
        label $id.out4f.l1 -text "output device 4:"
        button $id.out4f.x1 -text [lindex $midi_outdevlist $midi_outdev4] \
            -command \
            [list midi_popup $id $id.out4f.x1 midi_outdev4 $midi_outdevlist]
        pack $id.out4f.l1 $id.out4f.x1 -side left
    }

        # if not the "long form" make a button to
        # restart with longform set. 
    
    if {$longform == 0} {
        frame $id.longbutton
        pack $id.longbutton -side top
        button $id.longbutton.b -text {use multiple alsa devices} \
            -command  {pd pd midi-properties 1 \;}
        pack $id.longbutton.b
    }
    }
    if {$alsa} {
        label $id.in1f.l1 -text "In Ports:"
        entry $id.in1f.x1 -textvariable midi_alsain -width 4
        pack $id.in1f.l1 $id.in1f.x1 -side left
        label $id.in1f.l2 -text "Out Ports:"
        entry $id.in1f.x2 -textvariable midi_alsaout -width 4
        pack $id.in1f.l2 $id.in1f.x2 -side left
    }
}

############ pdtk_path_dialog -- dialog window for search path #########

proc path_apply {id} {
    global pd_extrapath pd_verbose
    global pd_path_count
    set pd_path {}

    for {set x 0} {$x < $pd_path_count} {incr x} {
        global pd_path$x
        set this_path [set pd_path$x]
        if {0==[string match "" $this_path]} {
            lappend pd_path [pdtk_encodedialog $this_path]
        }
    }

    pd [concat pd path-dialog $pd_extrapath $pd_verbose $pd_path \;]
}

proc path_cancel {id} {
    pd [concat $id cancel \;]
}

proc path_ok {id} {
    path_apply $id
    path_cancel $id
}

proc pdtk_path_dialog {id extrapath verbose} {
    global pd_extrapath pd_verbose
    global pd_path
    global pd_path_count

    set pd_path_count [expr [llength $pd_path] + 2]
    if { $pd_path_count < 10 } { set pd_path_count 10 }

    for {set x 0} {$x < $pd_path_count} {incr x} {
        global pd_path$x
        set pd_path$x [lindex $pd_path $x]
    }

    set pd_extrapath $extrapath
    set pd_verbose $verbose
    toplevel $id
    wm title $id {PD search path for patches and other files}
    wm protocol $id WM_DELETE_WINDOW [concat path_cancel $id]

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "path_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "path_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "path_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    pack $id.buttonframe.apply -side left -expand 1
    pack $id.buttonframe.ok -side left -expand 1
    
    frame $id.extraframe
    pack $id.extraframe -side bottom -fill x -pady 2m
    checkbutton $id.extraframe.extra -text {use standard extensions} \
        -variable pd_extrapath -anchor w 
    checkbutton $id.extraframe.verbose -text {verbose} \
        -variable pd_verbose -anchor w 
    button $id.extraframe.save -text {Save all settings}\
        -command "path_apply $id \; pd pd save-preferences \\;"
    pack $id.extraframe.extra $id.extraframe.verbose $id.extraframe.save \
        -side left -expand 1

    for {set x 0} {$x < $pd_path_count} {incr x} {
        entry $id.f$x -textvariable pd_path$x -width 80
        bind $id.f$x <KeyPress-Return> [concat path_ok $id]
        pdtk_standardkeybindings $id.f$x
        pack $id.f$x -side top
    }

    focus $id.f0
}

proc pd_set {var value} {
        global $var
        set $var $value
}

########## pdtk_startup_dialog -- dialog window for startup options #########

proc startup_apply {id} {
    global pd_nort pd_flags
    global pd_startup_count

    set pd_startup {}
    for {set x 0} {$x < $pd_startup_count} {incr x} {
        global pd_startup$x
        set this_startup [set pd_startup$x]
        if {0==[string match "" $this_startup]} {lappend pd_startup [pdtk_encodedialog $this_startup]}
    }

    pd [concat pd startup-dialog $pd_nort [pdtk_encodedialog $pd_flags] $pd_startup \;]
}

proc startup_cancel {id} {
    pd [concat $id cancel \;]
}

proc startup_ok {id} {
    startup_apply $id
    startup_cancel $id
}

proc pdtk_startup_dialog {id nort flags} {
    global pd_nort pd_nt pd_flags
    global pd_startup
    global pd_startup_count

    set pd_startup_count [expr [llength $pd_startup] + 2]
    if { $pd_startup_count < 10 } { set pd_startup_count 10 }

    for {set x 0} {$x < $pd_startup_count} {incr x} {
        global pd_startup$x
        set pd_startup$x [lindex $pd_startup $x]
    }

    set pd_nort $nort
    set pd_flags $flags
    toplevel $id
    wm title $id {Pd binaries to load (on next startup)}
    wm protocol $id WM_DELETE_WINDOW [concat startup_cancel $id]

    frame $id.buttonframe
    pack $id.buttonframe -side bottom -fill x -pady 2m
    button $id.buttonframe.cancel -text {Cancel}\
        -command "startup_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "startup_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "startup_ok $id"
    pack $id.buttonframe.cancel -side left -expand 1
    pack $id.buttonframe.apply -side left -expand 1
    pack $id.buttonframe.ok -side left -expand 1
    
    frame $id.flags
    pack $id.flags -side bottom
    label $id.flags.entryname -text {startup flags}
    entry $id.flags.entry -textvariable pd_flags -width 80
    bind $id.flags.entry <KeyPress-Return> [concat startup_ok $id]
    pdtk_standardkeybindings $id.flags.entry
    pack $id.flags.entryname $id.flags.entry -side left

    frame $id.nortframe
    pack $id.nortframe -side bottom -fill x -pady 2m
    if {$pd_nt != 1} {
        checkbutton $id.nortframe.nort -text {defeat real-time scheduling} \
            -variable pd_nort -anchor w
    }
    button $id.nortframe.save -text {Save all settings}\
        -command "startup_apply $id \; pd pd save-preferences \\;"
    if {$pd_nt != 1} {
        pack $id.nortframe.nort $id.nortframe.save -side left -expand 1
    } else {
        pack $id.nortframe.save -side left -expand 1
    }



    for {set x 0} {$x < $pd_startup_count} {incr x} {
        entry $id.f$x -textvariable pd_startup$x -width 80
        bind $id.f$x <KeyPress-Return> [concat startup_ok $id]
        pdtk_standardkeybindings $id.f$x
        pack $id.f$x -side top
    }

    focus $id.f0
}

########## data-driven dialog -- convert others to this someday? ##########

proc ddd_apply {id} {
    set vid [string trimleft $id .]
    set var_count [concat ddd_count_$vid]
    global $var_count
    set count [eval concat $$var_count]
    set values {}

    for {set x 0} {$x < $count} {incr x} {
        set varname [concat ddd_var_$vid$x]
        global $varname
        lappend values [eval concat $$varname]
    }
    set cmd [concat $id done $values \;]

#    puts stderr $cmd
    pd $cmd
}

proc ddd_cancel {id} {
    set cmd [concat $id cancel \;]
#    puts stderr $cmd
    pd $cmd
}

proc ddd_ok {id} {
    ddd_apply $id
    ddd_cancel $id
}

proc ddd_dialog {id dialogname} {
    global ddd_fields
    set vid [string trimleft $id .]
    set count [llength $ddd_fields]

    set var_count [concat ddd_count_$vid]
    global $var_count
    set $var_count $count

    toplevel $id
    label $id.label -text $dialogname
    pack $id.label -side top
    wm title $id "Pd dialog"
    wm resizable $id 0 0
    wm protocol $id WM_DELETE_WINDOW [concat ddd_cancel $id]

    for {set x 0} {$x < $count} {incr x} {
        set varname [concat ddd_var_$vid$x]
        global $varname
        set fieldname [lindex $ddd_fields $x 0]
        set $varname [lindex $ddd_fields $x 1]
        frame $id.frame$x
        pack $id.frame$x -side top -anchor e
        label $id.frame$x.label -text $fieldname
        entry $id.frame$x.entry -textvariable $varname -width 20
        bind $id.frame$x.entry <KeyPress-Return> [concat ddd_ok $id]
        pdtk_standardkeybindings $id.frame$x.entry
        pack $id.frame$x.entry $id.frame$x.label -side right
    }
            
    frame $id.buttonframe -pady 5
    pack $id.buttonframe -side top -fill x -pady 2
    button $id.buttonframe.cancel -text {Cancel}\
        -command "ddd_cancel $id"
    button $id.buttonframe.apply -text {Apply}\
        -command "ddd_apply $id"
    button $id.buttonframe.ok -text {OK}\
        -command "ddd_ok $id"
    pack $id.buttonframe.cancel $id.buttonframe.apply \
        $id.buttonframe.ok -side left -expand 1

#    $id.params.entry select from 0
#    $id.params.entry select adjust end
#    focus $id.params.entry
}


