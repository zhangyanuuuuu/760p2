#
#------------------------------------------------------------------------
# cmuview DRAWING EDITOR v2
#
#    updated Oct 29 01   R Rutenbar -- Added highlighting and balloon-style help
#                                      popups for rects (rfb, rob), ovals (ovb),
#                                      lines and arrows (lnb, arb).
#    updated Oct 27 01   R Rutenbar -- New  version, updated images,
#                                      New options menu:
#                                           Auto zoom to fit = ON
#                                           Background = LIGHT
#    updated Oct 20 01   R Rutenbar -- fixed bugs in Ruler, and with not showing
#                                      zero-th movie frame properly.
#                                      Added auto play/rewind and stop "VCR"
#                                      style controls, along with new Delay/Frame
#                                      slider to control rate of movie play.
#    updated Oct 17 01   R Rutenbar -- added doClose routine and ability
#                                      to close a file, and open a new
#                                      file without closing the whole tcl
#                                      shell.  Added Options menu, with
#                                      ability to select background color, and
#                                      whether auto zoomtofit is on on not
#    updated Mar 1 00    R Rutenbar -- general bug fix/cleanup
#                                      Added cmu logo to "About" dialog
#                                      BUGS  -- ruler now broken, 
#                                               won't take RULERUNITS string.
#
#    updated Nov 27 99   R Rutenbar -- added real menu bar:  File, Help, 
#                                      ballon help, etc. Added icons to
#                                      cmd buttons.  Did zoom fixes
#                                      for the click zooms (now always go to
#                                      screen center).  Added rewind mechanisms.
#                                      New measure box facility.
#    updated Oct 24 99   R Rutenbar -- total rewrite, layer palette,
#                                      box zoom, more robust zooming
#    updated Nov 18 98   R Rutenbar -- rewrote to handle movies stored in files,
#                                      first version of measure box,
#                                      added arrow drawing method
#    created Apr  5 98   R Rutenbar -- zeroth version, with tcl procedure
#                                      drawing primitives
#------------------------------------------------------------------------

# version number just gets printed in the "About" dialog
set cmuviewVersion 2.0.1

#------------------------------------------------------------------------
# go get the other utility routines, widgets, objects, etc, we need
#
#     current directory hierarchy assumptions:
#            There is a "cmuscripts" directory in SAME dir as this script
#            There is a "cmuimages" directory in the SAME dir as this script
#------------------------------------------------------------------------

# we start from THIS path to find all our scripts and images
# (...and, remember also to edit the path listed in the balloon.tcl
# file in cmuscripts/balloon.tcl
#
set cmupath "C:/Documents\ and\ Settings/rutenbar/My\ Documents/rar/Class/aa\ F05\ 760/code"
set cmupath "./"
# all from:
#   "Effective Tcl/Tk Programming"
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
source [file join $cmupath cmuscripts balloon.tcl]
source [file join $cmupath cmuscripts dialog.tcl]
source [file join $cmupath cmuscripts confirm.tcl]
source [file join $cmupath cmuscripts notice.tcl]
source [file join $cmupath cmuscripts textdisp.tcl]


#------------------------------------------------------------------------
#
# UTILITIES -- some boring utility stuff to make life easier
#
#------------------------------------------------------------------------
proc min { a b } {
   if { $a < $b } {
      return $a
   } else {
      return $b
   }
}

proc max { a b } {
   if { $a < $b } {
      return $b
   } else {
      return $a
   }
}
proc canvasLeftX {} {
   return [.c canvasx 0]
}

proc canvasRightX {} {
   return [.c canvasx [winfo width .c]]
}

proc canvasCenterX {} {
   return [.c canvasx [expr [winfo width .c]/2.0]]
}

proc canvasTopY {} {
   return [.c canvasy 0]
}

proc canvasBottomY {} {
   return [.c canvasy [winfo height .c]]
}

proc canvasCenterY {} {
   return [.c canvasy [expr [winfo height .c]/2.0]]
}

proc screenCenterX {} {
   return [expr [winfo width .c]/2.0]
}

proc screenCenterY {} {
   return [expr [winfo height .c]/2.0]
}


#------------------------------------------------------------------------
# 
# BASIC TK WIDGET DEFNS AND PACKING
#
#------------------------------------------------------------------------


#------------------------------------------------------------------------
# WINDOW RETITLE AT TOP
#------------------------------------------------------------------------
wm title . "cmuview Graphical Viewer"


# ----------------------------------------------------------------------
# MAIN MENU
# ----------------------------------------------------------------------
frame .mbar -borderwidth 1 -relief raised
pack .mbar -fill x

# FILE menu (at left...)
menubutton .mbar.file -text "File" -menu .mbar.file.m
pack .mbar.file -side left

menu .mbar.file.m
.mbar.file.m add command -label "Open..." -command {doOpen }
.mbar.file.m add command -label "Close" -command { doClose }
.mbar.file.m add command -label "Save postscript as..."   -command {doPrint }
.mbar.file.m add separator
.mbar.file.m add command -label "Exit" -command {doExit}

# OPTIONS menu (2nd from left...)
menubutton .mbar.options -text "Options" -menu .mbar.options.m
pack .mbar.options -side left

menu .mbar.options.m
# option is to toggle auto zoomtofit on/off.  Default is OFF
# global var is autoZoomToFitState, default val = 1
.mbar.options.m add command -label "Unset AutoZoomToFit" -command {doToggleAutoZoomToFit }
# option is to toggle background color, from tcl-default to/from black
# global var is backgroundBlackState, default val = 0
.mbar.options.m add command -label "Set Background Black" -command {doToggleBackgroundColor }


# HELP menu (at right...)
menubutton .mbar.help -text "Help" -menu .mbar.help.m
pack .mbar.help -side right

menu .mbar.help.m
.mbar.help.m add command -label "Overview..." -command {doOverview}

.mbar.help.m add command -label "Hide Balloon Help" -command {
    set mesg [.mbar.help.m entrycget 2 -label]
    if {[string match "Hide*" $mesg]} {
        balloonhelp_control 0
        .mbar.help.m entryconfigure 2 -label "Show Balloon Help"
    } else {
        balloonhelp_control 1
        .mbar.help.m entryconfigure 2 -label "Hide Balloon Help"
    }
}

.mbar.help.m add separator
.mbar.help.m add command -label "About..." -command {wm deiconify .about}


#-----------------------------------------------------------------------
# GLOBAL VARS FOR FILE IO
#-----------------------------------------------------------------------
set openFile 0

# ----------------------------------------------------------------------
# doOpen
#      Call std tk open file dialog to get the file to source
# ----------------------------------------------------------------------
proc doOpen {} {
global openFile

    # first, check if there is a file that has already been opened;
    # if so, we gotta close it first
    if {$openFile == 1} {
      doClose
    }

    # OK, now we can go try to actually read the new file
    set file [tk_getOpenFile]
    set openFile 1
    if {$file != ""} {
        set cmd {
            source $file
        }
        if {[catch $cmd err] != 0} {
            notice_show "Cannot open this file:\n$err" error
            set openFile 0
        }
    }
}

# ----------------------------------------------------------------------
# doClose
#      Reset all the right global variables so that a subsequent call
#      to doOPen() will do the right thing
# ----------------------------------------------------------------------
proc doClose {} {
global frameCounter  movieFrame  movieDone movieDelay movieLive enableReplay 
global openFile 

    # clear the canvas .c of ALL drawn stuff, immediately, now
    .c delete all 

    # also, to be conservative, we do an update to let tcl handle pending events
    update

    # reset all the movieFrame info to its initial, default state
    set movieLive 1
    set movieDone 0
    set movieDelay 0
    set enableReplay 0
    set frameCounter 0
    # make sure to actually ERASE the old movie!
    array unset movieFrame
    # now, its ok to re-init by defining the 0th frame of movieFrame array
    set movieFrame(0) {}

    # reset the movie replay slider and disable it
    # change it's label
    .bottom.replay configure -label "Movie Replay: Disabled..."
    # turn it "off" so its not enabled anymore
    .bottom.replay configure -state disabled
    # reconfigure it so the top end of scale == low end of scale
    .bottom.replay configure -to 0

    # reset state of the file-is-open flag
    set openFile 0
}


# ----------------------------------------------------------------------
# doPrint
#
# Prompts the user for a file, then gets the postscript contents of
# the .c canvas and attempts to save it into the file.  If
# anything goes wrong, a notice dialog reports the error.
# ----------------------------------------------------------------------
proc doPrint {} {

    set file [tk_getSaveFile -defaultextension "ps"]
    if {$file != ""} {
        
       # get the real canvas coords of what is displayed now
       set x0 [.c canvasx 0]
       set y0 [.c canvasy 0]
       set w  [expr [.c canvasx [winfo width .c]] - $x0]
       set h  [expr [.c canvasy [winfo height .c]] - $y0]

       # make a string which is the ps dump of the stuff visible in
       # window now
       set ps [.c  postscript -x $x0 -y $y0 -width $w -height $h ]

       set cmd {
            set fid [open $file w]
            puts $fid $ps
            close $fid
       }
       if {[catch $cmd err] != 0} {
            notice_show "Cannot save postscript file:\n$err" error
       }
    }
}



# ----------------------------------------------------------------------
# exit routines:  doExit,   cmuexit  
#
# WEIRD side effects:  THIS is where the movie frame slider gets setup,
# since its not till we see an "exit" in the input stream that we
# know how many frames we have.  WE enable this slider here, and config it
# AFTER we hit an "exit".  This is probably not the best way to do this...
# ----------------------------------------------------------------------

# Note carefully:
# this is how we REALLY quit.  Called directly from FILE menu.
# If you run "exit" yourself, we just quit, pow, immediately.
proc doExit {}  {
    exit
}

# if we are playing back a movie, "cmuexit" indicates we have just done
# the last frame;  deal with the different modes of operation:
#   live movie:  ask for quit confirmation
#   file playback, no replay:  ditto
#   file playback with replay:  mark that the movie is DONE, update replay slider,
#                               pop a notify dialog
#
proc cmuexit {} {
global frameCounter  movieFrame   movieDone movieLive enableReplay 

   # if we are in a live movie stream, that's it, we're done;
   # as a courtesy, we will pop up a notification window to
   # warn the user this is done, but after that we just quit
   if { $movieLive == 1  ||  $enableReplay == 0} {
      if { [confirm_ask  "This is the last frame of the drawing;  exit now?"] == 1 } {
         # they said OK, quit right NOW
         exit
      } else {
         # we just return, the drawing "hangs" with the last image up on
         # the canvas, user has to go to FILE menu to get out
         return
      }
   } elseif { $movieDone == 0} {
      # we are doing replay on a movie, so the first time we see this
      # command is from the file read;  add it to the movieFrame
      append movieFrame($frameCounter) "cmuexit;"
    
      # mark that the movie is in fact now DONE
      set movieDone 1

      # MOVIE REPLAY SLIDER SCALE SIDE EFFECTS HERE
      #
      #   update the replay slider so it actually works now:
      # change it's label
      .bottom.replay configure -label "Movie Frames(0 to $frameCounter)"
      # turn it "on" so its not disabled anymore
      .bottom.replay configure -state normal
      # reconfigure it so the top end of scale == last movie frame
      .bottom.replay configure -to $frameCounter
      # aesthetically refigure where to put the approx 3 tick marks...
      .bottom.replay configure -tickinterval [expr  round((1.0)*$frameCounter / 3.0) ]

      # one more subtle action to take:  we have just enabled the .bottom.replay
      # slider, and it will end up set by default at 0.  However, we
      # have not actually INTERPRETED any of the commands in movie frame 0.
      # In other words, the slider is set at frame 0, but we have not
      # *DRAWN* frame 0.  We need to do that.  If not, the usual cmuconfig
      # and cmuruler commands that end up in the very first frame dont
      # get run, and this creates later drawing/zooming/ruler problems.
      # To draw this zero-th frame, set the replay slider to 0, replay frame 0
      .bottom.replay set 0
      doReplay 0 
      
      
      # that's it for this FIRST time we see this command
      return


   } else {
      # if we get here, we just saw "cmuexit" in the last movieFrame() as
      # as a stored command;  we don't need to do anything at all...
      return
   }
}

#-----------------------------------------------------------------------
# GLOBAL VARS FOR OPTIONS MENU
#-----------------------------------------------------------------------
# there are 2 options on this menu, defining 2 variables:
#   options to toggle autoZoomToFit (default OFF)
#   option to toggle backgroundBlack (default OFF means default color)
set autoZoomToFitState 1
set backgroundBlackState 0
# we default it here.  we will set it to the INIT default color later
set globalLightCanvasBackground  white

proc doToggleAutoZoomToFit {} {
global autoZoomToFitState

  if { $autoZoomToFitState== 0 } {
    # its OFF now, so turn it ON, and relabel menu (1st command on menu)
    .mbar.options.m entryconfigure 1 -label "Unset AutoZoomToFit"
    set autoZoomToFitState 1
  } else {
    # its ON now, so turn it OFF
    .mbar.options.m entryconfigure 1 -label "Set AutoZoomToFit"
    set autoZoomToFitState 0
  } 
} 

proc doToggleBackgroundColor {} {
global backgroundBlackState  globalLightCanvasBackground

  if { $backgroundBlackState == 0 } {
    # its light now, so turn it black, and relabel menu (2nd command on menu)
    .c config -background black
    .mbar.options.m entryconfigure 2 -label "Reset Background Light"
    set backgroundBlackState 1
  } else {
    # its black now, so turn it default light
    .c config -background $globalLightCanvasBackground
    .mbar.options.m entryconfigure 2 -label "Set Background Black"
    set backgroundBlackState 0
  } 
}  
  

# ----------------------------------------------------------------------
# HELP OVERVIEW WINDOW
# ----------------------------------------------------------------------
set helpInfo ""
proc doOverview {} {
    global helpInfo

    if {[winfo exists $helpInfo]} {
        raise $helpInfo
    } else {
        set helpInfo [textdisplay_create "cmuview: Help"]

        textdisplay_append $helpInfo "cmuview:  General Overview\n" heading
        textdisplay_append $helpInfo {.......
		}

        textdisplay_append $helpInfo "File\n" heading
        textdisplay_append $helpInfo {....
		}

        textdisplay_append $helpInfo "Layer Palette\n" heading
        textdisplay_append $helpInfo {.....
		}

        textdisplay_append $helpInfo "Layer Palette\n" heading
        textdisplay_append $helpInfo {.....
		}

    }
}





# ----------------------------------------------------------------------
# ABOUT WINDOW  (POPPED UP FROM HELP MENU)
#      Make it, fill it, then disappear it;  it pops up wheneve
#      "About..." gets called from Help menu
# ----------------------------------------------------------------------
toplevel .about
wm title .about "cmuview Graphical Viewer"

button .about.ok -text "Dismiss" -command {wm withdraw .about}
pack .about.ok -side bottom -pady 8


set logo [image create photo -file [file join $cmupath cmuimages cmulogo.gif]]
label .about.logo -image $logo
pack .about.logo -side left -padx 8 -pady 4

label .about.cmu -text "Carnegie Mellon University\n\
Dept of Electrical & Computer Engineering\n\
Pittsburgh, PA 15213  USA."
pack .about.cmu -fill x  -pady 8
catch {.about.cmu configure -font -*-helvetica-bold-o-normal--*-140-*}

label .about.explain -text "A general Tcl/Tk debugging viewer \n\
for layout geometry, with support for \n\
a layer palette, movie playback, and zooming.\n\
Version $cmuviewVersion"

pack .about.explain -fill x  -pady 8
catch {.about.explain configure -font -*-helvetica-bold-o-normal--*-140-*}

label .about.authors -text "Rob A. Rutenbar,\n  with contributions from\n\
Michael Krasnicki, Elias Fallon\nPrakash Gopalakrishnan, Sambasivan Narayan"
pack .about.authors -fill x 
catch {.about.author1 configure -font -*-helvetica-bold-r-normal--*-140-*}


focus .about.ok
wm withdraw .about





#------------------------------------------------------------------------
# COMMAND BUTTONS, SLIDERS AT BOTTOM
#------------------------------------------------------------------------
frame  .bottom

# MOVIE REPLAY SCALE:  initially it goes from 0 to 0 and is disabled at startup
# Note that the way a movie actually gets "played" is this slider gets
# set to an appopriate frame, and then the doReplay() callback gets called,
# with the value of the slider setting supplied as the parameter.  This value
# is the index into the movieFrame( ) array, which is just a huge string
# of tcl drawing commands.  We eval this string, and, voila, the frame is drawn.
scale  .bottom.replay -from 0  -to 0 -length 144  \
      -variable currentFrame -orient horizontal \
       -label "Movie Replay: Disabled"   -showvalue true \
       -command "doReplay"  -state disabled
balloonhelp_for .bottom.replay  "Select movie frame to show"

# STATUS BOX:  place to print things on the GUI
label  .bottom.statusbox -width 50 -wraplength 6i -anchor w -bg white -relief sunken -text "Status:"
balloonhelp_for .bottom.statusbox  "Status info for most recent draw command"

# BUTTONS:  images on each one
set imZoomin  [image create photo -file [file join $cmupath cmuimages cmuzoomin.gif]]
set imZoomout [image create photo -file [file join $cmupath cmuimages cmuzoomout.gif]]
set imZoomfit [image create photo -file [file join $cmupath cmuimages cmuzoomtofit.gif]]
set imNext    [image create photo -file [file join $cmupath cmuimages cmunext.gif]]
set imPrev    [image create photo -file [file join $cmupath cmuimages cmuprev.gif]]
set imRewind  [image create photo -file [file join $cmupath cmuimages cmurewind.gif]]
set imPlay    [image create photo -file [file join $cmupath cmuimages cmuplay.gif]]
set imStop    [image create photo -file [file join $cmupath cmuimages cmustop.gif]]
set imRuler   [image create photo -file [file join $cmupath cmuimages cmuruler.gif]]

# BOTTONS:  definitions, images on each, command callbacks
button .bottom.next    -image $imNext     -command "doNext"
button .bottom.prev    -image $imPrev     -command "doPrev"
button .bottom.play    -image $imPlay     -command "doPlay"
button .bottom.rewind  -image $imRewind   -command "doRewind"
button .bottom.stop    -image $imStop     -command "doStop"
button .bottom.ruler   -image $imRuler    -command "doRuler"
button .bottom.zoomFIT -image $imZoomfit  -command "doZoomFIT"
button .bottom.zoomIN  -image $imZoomin   -command "doZoomIN"
button .bottom.zoomOUT -image $imZoomout  -command "doZoomOUT"

# BALLOON HELP FOR EACH BUTTON
balloonhelp_for .bottom.next     "Step to next frame of movie"
balloonhelp_for .bottom.prev     "Step back to previous frame of movie"
balloonhelp_for .bottom.play     "Play entire movie, automatically"
balloonhelp_for .bottom.rewind   "Rewind entire movie, while watching it"
balloonhelp_for .bottom.stop     "Stop a playing movie"
balloonhelp_for .bottom.ruler    "Toggle ruler--left click draws ruler-box"
balloonhelp_for .bottom.zoomFIT  "Zoom to fit layout"
balloonhelp_for .bottom.zoomIN   "Zoom in"
balloonhelp_for .bottom.zoomOUT  "Zoom out"

# BOTTOM.STEP SCALE:  set how big each zoom click is
scale  .bottom.step -from 1.0  -to 500.0 -length 72  \
       -variable zoomStepSlider -orient horizontal \
       -label "Zoom Step" -tickinterval 499  -showvalue true \
       -command "doSetZoomStep" 
balloonhelp_for .bottom.step  "Set size of zoom step for click-zooms"

# BOTTOM.SPEED SCALE:  set how fast to auto play/rewind the movie
scale  .bottom.speed -from 0.0  -to 10.0 -length 72  \
       -variable speedSlider -orient horizontal \
       -label "Delay/Frame" -tickinterval 5  -showvalue true \
       -command "doSetDelay" 
balloonhelp_for .bottom.speed  "Set delay/frame (sec) for auto movie play"

# pack the status box across the top...
pack  .bottom           -side bottom -fill x
pack  .bottom.statusbox -side top -pady 1m -fill x 
# then the one step buttons for next/prev and frames
pack  .bottom.next -side right -padx 1m -anchor e
pack  .bottom.prev -side right -padx 1m -anchor e
pack  .bottom.replay -side right -padx 2m -anchor e
# then the rewind/stop/play buttons, and delay slider
pack  .bottom.play -side right -padx 1m -anchor e
pack  .bottom.stop -side right -padx 1m -anchor e
pack  .bottom.rewind -side right -padx 1m -anchor e
pack  .bottom.speed -side right -padx 2m -anchor e
# then the zooms, ruler, and zoom-step
pack  .bottom.ruler -side right -padx 1m -anchor e
pack  .bottom.zoomFIT -side right -padx 1m -anchor e
pack  .bottom.zoomOUT -side right -padx 1m -anchor e
pack  .bottom.zoomIN -side right -padx 1m -anchor e
pack  .bottom.step -side right -padx 2m -anchor w

#------------------------------------------------------------------------
# DRAWING CANVAS FOR GEOMTRY + 2 SCROLLBARS
#------------------------------------------------------------------------

# default scroll region is {0 0 2000 2000}
set SCROLLMAXX 2000
set SCROLLMAXY 2000
set reg [list 0 0 $SCROLLMAXX $SCROLLMAXY]

frame .guts  -borderwidth 1m  -relief groove
scrollbar .cx -orient horiz -command ".c xview"
scrollbar .cy -orient vert -command ".c yview"
canvas .c -scrollregion $reg  -confine false \
       -xscrollcommand ".cx set"  -yscrollcommand ".cy set" 

# remember the LIGHT color of the canvas background 
# (in Windows its name is SystemButtonFace -- but thats not true everywhere)
# this is the default background when we start up; 
set globalLightCanvasBackground white
 
# If you want default to be a different color, set it HERE
#  eg  .c config -background black


#------------------------------------------------------------------------
# CANVAS FOR THE LAYER PALETTE + SCROLLBAR
#------------------------------------------------------------------------

frame .palette -relief groove  

set smalllogo [image create photo -file [file join $cmupath cmuimages cmulogosmall.gif]]
label .palette.logo -image $smalllogo -relief raised

# note fixed 4cm width so palette doesn't expand on widow resize
# and, default scrollregion will get updated later
canvas .palette.pc -width 4c -scrollregion {0 0 4c 30c} \
                             -yscrollcommand ".palette.pcy set"
scrollbar .palette.pcy -orient vert -command ".palette.pc yview"

pack .palette.logo -side top -padx 0 -pady 2

pack .palette.pc  -side left -padx 1m -anchor e -fill y
pack .palette.pcy -side left -anchor e -fill y

#------------------------------------------------------------------------
# arrange all the canvas-related components with geometry manager
#                  col 0      col 1    col 2 
#  grid manager:   palette    c        cy      row 0
#                  palette    cx       --      row 1  
#------------------------------------------------------------------------
#
grid rowconfig      .guts 0    -weight 1 -minsize 0
grid columnconfig   .guts 1    -weight 1 -minsize 0
grid .c -in .guts -padx 1 -pady 1 \
        -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
grid .cy -in .guts -padx 1 -pady 1 \
        -row 0 -column 2 -rowspan 1 -columnspan 1 -sticky ns
grid .cx -in .guts -padx 1 -pady 1 \
        -row 1 -column 1 -rowspan 1 -columnspan 1 -sticky ew
grid .palette -in .guts -padx 0 -pady 0 \
        -row 0 -column 0 -rowspan 2 -columnspan 1 -sticky ns

# finally, pack the whole overall frame
pack .guts -side left -anchor w -expand yes -fill both -padx 1 -pady 1

#------------------------------------------------------------------------
# Build the layer palette's buttons
#   Note the colors are 'hardwired', ie, we only deal with 
#   colors form the list below, we don't extract them from
#   from the live stream of drawn tk .c canvas items.
#------------------------------------------------------------------------
set vert 0.25
#  COLORLIST is here..
foreach color {
    "DARKtext"\
    "WHITEtext"\
    "black"\
    "white"\
    "red"\
    "DarkGreen"\
    "SpringGreen"\
    "yellow"\
    "RosyBrown"\
    "SandyBrown"\
    "IndianRed"\
    "blue2"\
    "purple"\
    "HotPink"\
    "LightPink"\
    "LightSalmon1"\
    "sienna4"\
    "LightBlue3"\
    "SteelBlue"\
    "chocolate1"\
    "OliveDrab3"\
    "turquoise" } {
    # special cases for first 2 palette entries--they are text not colors

    if {$color == "DARKtext" } {

       # first draw at left a small filled rect in white
       .palette.pc create rectangle 0.1c [expr $vert - 0.15]c \
                                    0.5c [expr $vert + 0.15]c -fill white
       # then add some text onto that rect
       .palette.pc create text 0.3c [expr $vert + 0.15]c -anchor s \
                          -text "ab" -font {times 8} -fill black
       # make a new checkbutton for dark text
       checkbutton .palette.pc.darktext -text $color  -font {times 8 bold} \
                            -command "doFont dark" -variable palettetextdark
       # add balloon help for this button
       balloonhelp_for .palette.pc.darktext "Turn on/off all NON-white text in layout"      
       # set default as ON, ie, text color is selected to display
       .palette.pc.darktext select 
       # put the checkbutton in the palette canvas itself 
       .palette.pc create window 0.6c [expr $vert]c -anchor w -window .palette.pc.darktext
       # draw a separator line between successive layer buttons in palette
       .palette.pc create line 0c [expr $vert +0.4]c \
                               4c [expr $vert + 0.4]c -fill black

       # update vertical distance from top of palette for drawing next button
       set vert [expr $vert + 0.8]

    } elseif {$color == "WHITEtext" } {

       # first draw at left a small filled rect in black
       .palette.pc create rectangle 0.1c [expr $vert - 0.15]c \
                                    0.5c [expr $vert + 0.15]c -fill black
       # then add some white text onto that rect
       .palette.pc create text 0.3c [expr $vert + 0.15]c -anchor s \
                          -text "ab" -font {times 8} -fill white
       # make a new checkbutton for white text
       checkbutton .palette.pc.whitetext -text $color  -font {times 8 bold} \
                            -command "doFont white" -variable palettetextwhite
       # add balloon help for this button
       balloonhelp_for .palette.pc.whitetext "Turn on/off all white text in layout"                               
       # set default as ON, ie, text color is selected to display
       .palette.pc.whitetext select 
       # put the checkbutton in the palette canvas itself 
       .palette.pc create window 0.6c [expr $vert]c -anchor w -window .palette.pc.whitetext
       # draw a separator line between successive layer buttons in palette
       .palette.pc create line 0c [expr $vert +0.4]c \
                               4c [expr $vert + 0.4]c -fill black

       # update vertical distance from top of palette for drawing next button
       set vert [expr $vert + 0.8]
    } else {
     
       # ordinary colors for .c drawn items

       # first draw at left a small filled rect in this color
       .palette.pc create rectangle 0.1c [expr $vert - 0.15]c \
                                    0.5c [expr $vert + 0.15]c -fill $color
       # make unique name for window, ensure last name in path starts 
       #  with a LOWER case letter, "b" here, since window names lower-case only
       set cb ".palette.pc.b$color"
       # make a new checkbutton with this name
       # note the var for the button is "palette$color", eg, palettered,
       checkbutton $cb -text $color  -font {times 8 bold} \
                       -command "doColor $color " -variable palette$color
       # add balloon help for this button
       balloonhelp_for $cb "Turn on/off all $color geometry in layout"      

       # set default as ON, ie, color is selected to display
       $cb select 
       # put the layer checkbutton in the palette canvas itself 
       .palette.pc create window 0.6c [expr $vert]c -anchor w -window $cb
       # draw a separator line between successive layer buttons in palette
       .palette.pc create line 0c [expr $vert +0.4]c \
                               4c [expr $vert + 0.4]c -fill black

       # update vertical distance from top of palette for drawing next button
       set vert [expr $vert + 0.8]
    }
}

# get bounding box of overall layer palette
set palettebbox [.palette.pc bbox all]
# use bbox to update palette scrollregion so scrollbars work right
.palette.pc configure -scrollregion $palettebbox


#------------------------------------------------------------------------
# doColor { Colorvalue }
#
# set up call-back command for palette color buttons.  
# Each color has a global  variable
# named "palette<color>" eg, "paletteblue2". 
#    ==0 means not set, means color NOT drawn
#    ==1 means set, means color IS drawn
#------------------------------------------------------------------------
proc doColor { colorvalue } {

# make sure to declare the checkbutton var global so we can read it
global palette$colorvalue

   set filltag fill$colorvalue
   set outlinetag out$colorvalue
   set linetag line$colorvalue

   # eval the var associated with the checkbutton, eg, paletteblue2
   #  note tcl magic: we first build the name of the variable,
   #   and inside the quotes we protect first '$' but eval 2nd, so that
   #   this actually becomes a string like "$paletteblue2".
   #   To then actually get its contents (0 or 1) we add "set var..." in front
   #   and then, after substitution, we get something like "set var $paletteblue2"
   #   and we eval this to set $var to the button state
   eval "set var \$palette$colorvalue" 

   if { $var == 1 } {
      # color is now enabled.  redraw all the items of this color
      # in particular, look for fill-able items like rects, ovals
      #   that match filltag, and re-fill them
      .c itemconfigure $filltag -fill $colorvalue -outline black
      # ... now, look for outlined-but-not-filled items 
      #   that match outline tag, and re-outline them
      .c itemconfigure $outlinetag -outline $colorvalue
      # ...finally, look for lines with this color, and re-line them
      #    note, NO outline for lines
      .c itemconfigure $linetag -fill $colorvalue  
   } else {
      # color is now disabled.  undraw all the items of this color
      # in particular, look for fill-able items like rects, ovals
      #    that match filltag, and turn off their
      #    color (set it to {}) AND their assumed-black outline (set it to {})
      .c itemconfigure $filltag -fill {} -outline {}
      # ...ditto for outlined-but-not-filled items (like some rects)
      #    that were unfilled but had a custom outline color
      .c itemconfigure $outlinetag -fill {} -outline {}
      # ...finally, turn off color on lines that match
      .c itemconfigure $linetag -fill {}
   }
}

#------------------------------------------------------------------------
# doFont { colorvalue }
#
# setup call back for palette text buttons
# all we do is override the font size to make text 
# "semi invisible".  This is all we can do since
# the trick of drawing with -fill {} won't work for text
#------------------------------------------------------------------------
proc doFont { colorvalue } {

#make sure we have the checkbutton var global
global palettetext$colorvalue

#also, make sure we can get to the fonts
global cmufontwhite cmufontdark

   # get the var value
   eval "set tvar \$palettetext$colorvalue"


   if {$tvar == 1} {
     # this color text is now ENABLED.  Restore it to proper size
     # remember we expect $colorvalue==white or $colorvalue==dark
     # since that's all we track here
     
     if {$colorvalue == "white"} {
        # we just restore font size, which auto changes all the
        # text drawn in .c with this font.  
        font configure $cmufontwhite -size 8
     } else {
        # do the same for dark non-white font
        font configure $cmufontdark -size 8
     }
   } else {
     # this color text is now DISABLED.  Render it invisible.
     
     if {$colorvalue == "white"} {
        # we just override font size, which auto changes all the
        # text drawn in .c with this font.  neg font size means
        # absolute pixel height for font, so this means 1 pix high,
        # rendering the font semi-invisible
        font configure $cmufontwhite -size -1
     } else {
        # do the same for dark non-white font
        font configure $cmufontdark -size -1
     }
   }
}




#------------------------------------------------------------------------
#
# ZOOM-RELATED STUFF FOR DRAWING CANVAS .c
#
#    Bindings and globals and initialization stuff
#------------------------------------------------------------------------

# right click == zoom out, center to click
bind .c <ButtonPress-3> {
   doPointZoom %x %y -1
}

# debugging  -- turned off now
#bind .c <Motion> {
#    trackmouse %x %y
#}

# left botton == draw/drag a temp zoom box 
bind .c <ButtonPress-1>   { ZoomBoxStart %x %y }
bind .c <B1-Motion>       { ZoomBoxMove  %x %y }
bind .c <ButtonRelease-1> { ZoomBoxEnd   %x %y }

# zoom global vars and initialization of zoom step slider
set globalScaling 1.0
set globalZoomStep 1
.bottom.step set 1

# zoom box global vars stuff
set zboxXstart 0
set zboxYstart 0
set zboxXend 0
set zboxYend 0


#------------------------------------------------------------------------
# doPointZoom { x y dir }
#
# POINT ZOOM STEP -- zoom to click point, recenter in visible screen
#
#------------------------------------------------------------------------
proc doPointZoom { x y dir } {

   global globalScaling zoomSlider zoomStepSlider
   global SCROLLMAXX  SCROLLMAXY

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   # get canvas position of this click
   set cx [.c canvasx $x]
   set cy [.c canvasy $y]

   
   # get the current scrollregion and bbox of drawn items
   # for the underlying canvas,
   # in case this zoom scales objects off the edge of the region
   # and we need to resize this canvas scrollregion;
   # we only worry about the rightmost bottommost edge of the these regions,
   # assume the other corner is close to 0 0
   set creg   [.c cget -scrollregion]
   set cregx  [lindex $creg 2]
   set cregy  [lindex $creg 3]
   set cbbox  [.c bbox all]
   set cbboxx [lindex $cbbox 2]
   set cbboxy [lindex $cbbox 3]

   # Next, get the actual dimensions of the visible screen region
   set visibleHeight [winfo height .c]
   set visibleWidth  [winfo width .c]

   # which way are we zooming?
   if { $dir >= 0 } {
      # zoom UP

      # OK, we want to go from globalScaling to (globalScaling + zoomstep) scaling
      # and, since we want a relative scaling, we compute it thus
      set relScaling [expr ((1.0)*($globalScaling + $zoomStepSlider))/(1.0*$globalScaling)]

      # next part is the  "zoom too big?" check -- to make sure we don't
      # scale anything off edge of the srollregion.

      # This zoom will scale (multiply) by relScaling the rightmost & bottommost
      # coords of the bounding box:  do these go off the canvas scrollregion?
      if { [expr $relScaling * $cbboxx] > $cregx } {
        # off edge in x direction.  reset x size to 5% bigger than current bbox x
        set cnewreg [.c cget -scrollregion]
        set cregx [expr 1.05 * $relScaling * $cbboxx]
        set cnewreg [lreplace $cnewreg 2 2 $cregx]
        .c configure -scrollregion $cnewreg
      }
      if { [expr $relScaling * $cbboxy] > $cregy } {
        # off edge in y direction.  reset y size to 5% bigger than current bbox y
        set cnewreg [.c cget -scrollregion]
        set cregy [expr 1.05 * $relScaling * $cbboxy]
        set cnewreg [lreplace $cnewreg 3 3 $cregy]
        .c configure -scrollregion $cnewreg
      }
      # note also that cregx and cregy are now  correctly holding
      # the bottom right coord for the scrollregion on the canvas .c
      # which we use in the calc of the scrollbar adjustment

   } else {

     # zoom DOWN

      # OK, we want to go from globalScaling to (globalScaling + zoomstep) scaling
      # and, since we want a relative scaling, we compute it thus
      set relScaling [expr ((1.0)*($globalScaling - $zoomStepSlider))/(1.0*$globalScaling)]
      
      # check to see relScaling is positive, nonzero
      if { ($relScaling <= 0.0) || ([expr $relScaling * $globalScaling] < 1.0) } {
         # too small, prob due to large NEG zoomstep, just assume we want
         # to go back to overall scaling of 1.0, ie, undo curr scaling
         set relScaling [expr 1.0 / $globalScaling]
      }

      # check if we can quit now: if relScaling == 1.0 and we know we
      # are zooming OUT, then we are not going to change anything.
      # If we quit now, we avoid screwing up the scroll bars
      if {$relScaling == 1.0 } {
         return
      }

      # next part is the  "zoom too small?" check 
      # This zoom will scale (multiply) by relScaling the rightmost & bottommost
      # coords of the bounding box:  when we zoomed in we made the canvas
      # bigger, so here we make is smaller.  Basic check is make sure
      # the canvas doesn't get smaller than the original SCROLLMAXX SCROLLMAXY
      # settings at the start of drawing
      if { [expr $relScaling * $cbboxx] < $SCROLLMAXX } {
        # too small in x direction.  reset x size 
        set cnewreg [.c cget -scrollregion]
        set cregx $SCROLLMAXX
        set cnewreg [lreplace $cnewreg 2 2 $cregx]
        .c configure -scrollregion $cnewreg
      }
      if { [expr $relScaling * $cbboxy] < $SCROLLMAXY } {
        # too small in y direction.  reset y size 
        set cnewreg [.c cget -scrollregion]
        set cregy $SCROLLMAXY
        set cnewreg [lreplace $cnewreg 3 3 $cregy]
        .c configure -scrollregion $cnewreg
      }
      # note also that cregx and cregy are now  correctly holding
      # the bottom right coord for the scrollregion on the canvas .c
      # which we use in the calc of the scrollbar adjustment
   }

   # now, to do the zoom has 2 parts
   #   1. Actually zoom, by scaling all items on .c
   #   2. Adjust scrollbars to bring clickpoint of the zoom to
   #      the centerpoint of the visible screen

   # do the actual zoom by scaling all items on .c
   .c  scale scalable 0 0 $relScaling $relScaling

   # adjust the scrollbars:  
   #
   # this is where the clickpoint, on the underlying canvas
   # got scaled to as a result of our zoom
   set zcx [expr $relScaling * $cx]
   set zcy [expr $relScaling * $cy]

   # this is the fraction of the canvas we want to left of left-edge of visible screen
   set xfrac [expr  ($zcx - ($visibleWidth/2.0)) / (1.0 * $cregx) ]
   if {$xfrac < 0.0 } {
      # too small, reset
      set xfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to left can possibly be, given current
   # size of visible region and current canvas size
   set maxxfrac [expr ((1.0 * $cregx)-$visibleWidth) / (1.0*$cregx) ]
   if {$xfrac > $maxxfrac} {
      # too big, reset
      set xfrac $maxxfrac
   }

   # this is the fraction of the canvas we want to top of top-edge of visible screen
   set yfrac [expr  ($zcy - ($visibleHeight/2.0)) / (1.0 * $cregy) ]
   if {$yfrac < 0.0 } {
      #too small, reset
      set yfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to top can possibly be, given current
   # size of visible region and current canvas size
   set maxyfrac [expr ((1.0 * $cregy)-$visibleHeight) / (1.0*$cregy) ]
   if {$yfrac > $maxyfrac} {
      # too big, reset
      set yfrac $maxyfrac
   }
   
   # adjust scrollbars
   .c xview moveto $xfrac
   .c yview moveto $yfrac

   # update global scaling
   set globalScaling [expr $relScaling * $globalScaling]
}



#------------------------------------------------------------------------
# doZoomFIT {}
#
# FIT ZOOM -- rescale so entire bbox of drawn stuff on .c is visible
#             This is mostly just the ZoomBoxEnd code, slightly modified
#             so the "zoom box" is really the bounding box of stuff drawn
#             on the .c canvas that we can actually scale (ie, not text)
#
#------------------------------------------------------------------------
proc doZoomFIT {} {

   global globalScaling zoomSlider zoomStepSlider

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }
   
   # get the current scrollregion 
   # for the underlying canvas,
   # in case this zoom scales objects off the edge of the region
   # and we need to resize this canvas scrollregion;
   # we only worry about the rightmost bottommost edge of the these regions,
   # assume the other corner is close to 0 0
   set creg   [.c cget -scrollregion]
   set cregx  [lindex $creg 2]
   set cregy  [lindex $creg 3]

   # get current bbox of drawn stuff that we CAN change size of;
   # (this means in particular don't look at text; if it doesn't
   # fit on screen now, doing .c scale ... won't fix this.)
   # THIS is a major difference between zoom to fit scaling and the
   # scaling that the zoom to click point does...
   set cbbox [.c bbox recto rectf line arrow oval]
   set cboxXstart [lindex $cbbox 0]
   set cboxYstart [lindex $cbbox 1]
   set cboxXend   [lindex $cbbox 2]
   set cboxYend   [lindex $cbbox 3]

   # our vars cbox** hold the coords of the  bounding box of drawn stuff on .c;
   # compute height and width of this zoom box, ands it geometric center
   set zoomWidth [expr abs( $cboxXstart - $cboxXend ) ]
   set zoomHeight [expr abs( $cboxYstart - $cboxYend ) ]
   # exact center of the visible screen
   set cenx [expr ($cboxXstart + $cboxXend)/2.0]
   set ceny [expr ($cboxYstart + $cboxYend)/2.0]

   # Next, get the actual dimensions of the visible screen region
   set visibleHeight [winfo height .c]
   set visibleWidth  [winfo width .c]

   # if this box is "too small" , want to avoid an unintended HUGE
   # zoom, we just set the zoom to the zoomscale's default
   if { ($zoomWidth <= 3) || ($zoomHeight <= 3) } {

      # OK, we want to go from globalScaling to (globalScaling + zoomstep) scaling
      # and, since we want a relative scaling, we compute it thus
      set relScaling [expr ((1.0)*($globalScaling + $zoomStepSlider))/(1.0*$globalScaling)]

   } else {

      # OK, it's a reasonable size bbox and we should compute how to zoom to the box
   
      # We want to scale the bbox so it "maximally" fits in visible screen;
      # so that the zoomed region still fits in the shape of the screen, we
      # calculate max scaling for each dimension x, y independently
      # and take the smallest one.
      set xscal [expr (1.0*$visibleWidth)/(1.0*$zoomWidth)]
      set yscal [expr (1.0*$visibleHeight)/(1.0*$zoomHeight)]

      # relScaling is how much "more" scaling we need to do, to do this zoom.
      set relScaling [min $xscal $yscal ]

      # back off this max scaling just a little to avoid getting too close
      # to the edges of visible region after actual zoom
      set relScaling [expr 0.9*$relScaling]

   }

   # next part is the  "zoom too big?" check -- to make sure we don't
   # scale anything off edge of the srollregion.

   # This zoom will scale (multiply) by relScaling the rightmost & bottommost
   # coords of the bounding box:  do these go off the canvas scrollregion?
   if { [expr $relScaling * $cboxXend] > $cregx } {
      # off edge in x direction.  reset x size to 5% bigger than current bbox x
      set cnewreg [.c cget -scrollregion]
      set cregx [expr 1.05 * $relScaling * $cboxXend]
      set cnewreg [lreplace $cnewreg 2 2 $cregx]
      .c configure -scrollregion $cnewreg
   }
   if { [expr $relScaling * $cboxYend] > $cregy } {
      # off edge in y direction.  reset y size to 5% bigger than current bbox y
      set cnewreg [.c cget -scrollregion]
      set cregy [expr 1.05 * $relScaling * $cboxYend]
      set cnewreg [lreplace $cnewreg 3 3 $cregy]
      .c configure -scrollregion $cnewreg
   }
   # note also that cregx and cregy are now  correctly holding
   # the bottom right coord for the scrollregion on the canvas .c
   # which we use in the calc of the scrollbar adjustment

   # now, to do the zoom has 2 parts"
   #   1. Actually zoom, by scaling all items on .c
   #   2. Adjust scrollbars to bring centerpoint of zoom box to
   #      the centerpoint of the visible screen

   # do the actual zoom by scaling all items on .c
   .c  scale scalable 0 0 $relScaling $relScaling

   # adjust the scrollbars:  
   #
   # this is where the center of the zoombox, on the underlying canvas
   # got scaled to as a result of our zoom
   set zcenx [expr $relScaling * $cenx]
   set zceny [expr $relScaling * $ceny]

   # this is the fraction of the canvas we want to left of left-edge of visible screen
   set xfrac [expr  ($zcenx - ($visibleWidth/2.0)) / (1.0 * $cregx) ]
   if {$xfrac < 0.0 } {
      # too small, reset
      set xfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to left can possibly be, given current
   # size of visible region and current canvas size
   set maxxfrac [expr ((1.0 * $cregx)-$visibleWidth) / (1.0*$cregx) ]
   if {$xfrac > $maxxfrac} {
      # too big, reset
      set xfrac $maxxfrac
   }

   # this is the fraction of the canvas we want to top of top-edge of visible screen
   set yfrac [expr  ($zceny - ($visibleHeight/2.0)) / (1.0 * $cregy) ]
   if {$yfrac < 0.0 } {
      #too small, reset
      set yfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to top can possibly be, given current
   # size of visible region and current canvas size
   set maxyfrac [expr ((1.0 * $cregy)-$visibleHeight) / (1.0*$cregy) ]
   if {$yfrac > $maxyfrac} {
      # too big, reset
      set yfrac $maxyfrac
   }
   
   # adjust scrollbars
   .c xview moveto $xfrac
   .c yview moveto $yfrac

   # update global scaling
   set globalScaling [expr $relScaling * $globalScaling]

}

#------------------------------------------------------------------------
# doZoomOUT {}
#
# ZOOM OUT-- binds to "little Z" button, just does doPointZoom to 
# center of screen, using zoomstep size as default zoom amount
#
#------------------------------------------------------------------------
proc doZoomOUT {} {

    doPointZoom [screenCenterX] [screenCenterY] -1
}

#------------------------------------------------------------------------
# doZoomIN {}
#
# ZOOM IN-- binds to "big Z" button, just does doPointZoom to 
# center of screen, using zoomstep size as default zoom amount
#
#------------------------------------------------------------------------
proc doZoomIN {} {

    doPointZoom [screenCenterX] [screenCenterY] +1
}


#------------------------------------------------------------------------
# doSetZoomStep { zvalue }
#
# RESET ZOOM STEP SIZE -- just change zoom step slider
#
#------------------------------------------------------------------------
proc doSetZoomStep { zvalue } {

    global globalZoomStep
 
    set globalZoomStep $zvalue
}




#------------------------------------------------------------------------
# 
# BOX ZOOM callback procs -- draw a box on screen, zoom to this box
#
#------------------------------------------------------------------------


#------------------------------------------------------------------------
# ZoomBoxStart { x y }
#
# Start zoom box: draw a degenerate 1pt box.  Be careful to transform the
# click at (x,y) into underlying canvas coords, and to undo the effect
# of scaling
#------------------------------------------------------------------------
proc ZoomBoxStart { x y } {

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   global zboxXstart
   global zboxYstart
   set zboxXstart [.c canvasx $x]
   set zboxYstart [.c canvasy $y]

   # it's just the start click, but it's a degenerate 1pt box
   # with start AND end coords;  essential if user just releases
   # button after this one click that we have a COMPLETE box
   set zboxXend $zboxXstart
   set zboxYend $zboxYstart
   .c create rectangle $zboxXstart $zboxYstart $zboxXstart $zboxYstart -outline yellow -tag zoombox

}

#------------------------------------------------------------------------
# ZoomBoxMove { x y }
#
# Move zoom box: drag the box by deleting the prior box and redrawing it.
# again, be careful abouts canvas coords and scaling
#------------------------------------------------------------------------
proc ZoomBoxMove { x y } {
   global zboxXstart 
   global zboxYstart 
   global zboxXend
   global zboxYend 

    # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   set zboxXend [.c canvasx $x]
   set zboxYend [.c canvasy $y]
   .c delete "zoombox"
   .c create rectangle $zboxXstart $zboxYstart $zboxXend $zboxYend -outline yellow -tag zoombox
}

#------------------------------------------------------------------------
# ZoomBoxEnd { x y }
#
# End zoom box: DO the actual zoom 
#------------------------------------------------------------------------
proc ZoomBoxEnd { x y } {
   global zboxXstart 
   global zboxYstart 
   global zboxXend
   global zboxYend 
   global globalScaling zoomSlider zoomStepSlider

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   # update zoom box position
   set zboxXend [.c canvasx $x]
   set zboxYend [.c canvasy $y]

   # erase the drawn zoombox
   .c delete "zoombox"

   # our global vars zbox** hold the drawn zoom region;
   # compute height and width of this zoom box, ands it geometric center
   set zoomWidth [expr abs( $zboxXstart - $zboxXend ) ]
   set zoomHeight [expr abs( $zboxYstart - $zboxYend ) ]

   # first, check to see if it's not really a zoom "box" but it's
   # really just a single click (not click-and-drag).  If so,
   # then we punt here and just call the zoom in to point routine
   # for this point.  ie, it's not a zoom to box, it's really a
   # click-zoom to this one pt
   if { ($zoomWidth <= 2) && ($zoomHeight <= 2) } {
       # OK, it's really a click, just go zoom to this click
       doPointZoom $x $y +1
       return
   }
   
   # get the current scrollregion and bbox of drawn items
   # for the underlying canvas,
   # in case this zoom scales objects off the edge of the region
   # and we need to resize this canvas scrollregion;
   # we only worry about the rightmost bottommost edge of the these regions,
   # assume the other corner is close to 0 0
   set creg   [.c cget -scrollregion]
   set cregx  [lindex $creg 2]
   set cregy  [lindex $creg 3]
   set cbbox  [.c bbox all]
   set cbboxx [lindex $cbbox 2]
   set cbboxy [lindex $cbbox 3]

   # our global vars zbox** hold the drawn zoom region;
   # compute  its geometric center, ie, the
   # exact center of the visible screen
   set cenx [expr ($zboxXstart + $zboxXend)/2.0]
   set ceny [expr ($zboxYstart + $zboxYend)/2.0]

   # Next, get the actual dimensions of the visible screen region
   set visibleHeight [winfo height .c]
   set visibleWidth  [winfo width .c]

   # if this box is still "too small" it probably means user just clicked
   # instead of drawing a drag box;  to avoid an unintended HUGE
   # zoom, we just set the zoom to the zoomscale's default
   if { ($zoomWidth <= 5) || ($zoomHeight <= 5) } {

      # OK, we want to go from globalScaling to (globalScaling + zoomstep) scaling
      # and, since we want a relative scaling, we compute it thus
      set relScaling [expr ((1.0)*($globalScaling + $zoomStepSlider))/(1.0*$globalScaling)]

   } else {

      # OK, it's a real box and we should compute how to zoom to the box
   
      # We want to scale the box so it "maximally" fits in visible screen;
      # so that the zoomed region still fits in the shape of the screen, we
      # calculate max scaling for each dimension x, y independently
      # and take the smallest one.
      set xscal [expr (1.0*$visibleWidth)/(1.0*$zoomWidth)]
      set yscal [expr (1.0*$visibleHeight)/(1.0*$zoomHeight)]

      # relScaling is how much "more" scaling we need to do, to do this zoom.
      set relScaling [min $xscal $yscal ]

      # back off this max scaling just a little to avoid getting too close
      # to the edges of visible region after actual zoom
      set relScaling [expr 0.9*$relScaling]

   }

   # next part is the  "zoom too big?" check -- to make sure we don't
   # scale anything off edge of the srollregion.

   # This zoom will scale (multiply) by relScaling the rightmost & bottommost
   # coords of the bounding box:  do these go off the canvas scrollregion?
   if { [expr $relScaling * $cbboxx] > $cregx } {
      # off edge in x direction.  reset x size to 5% bigger than current bbox x
      set cnewreg [.c cget -scrollregion]
      set cregx [expr 1.05 * $relScaling * $cbboxx]
      set cnewreg [lreplace $cnewreg 2 2 $cregx]
      .c configure -scrollregion $cnewreg
   }
   if { [expr $relScaling * $cbboxy] > $cregy } {
      # off edge in y direction.  reset y size to 5% bigger than current bbox y
      set cnewreg [.c cget -scrollregion]
      set cregy [expr 1.05 * $relScaling * $cbboxy]
      set cnewreg [lreplace $cnewreg 3 3 $cregy]
      .c configure -scrollregion $cnewreg
   }
   # note also that cregx and cregy are now  correctly holding
   # the bottom right coord for the scrollregion on the canvas .c
   # which we use in the calc of the scrollbar adjustment

   # now, to do the zoom has 2 parts"
   #   1. Actually zoom, by scaling all items on .c
   #   2. Adjust scrollbars to bring centerpoint of zoom box to
   #      the centerpoint of the visible screen

   # do the actual zoom by scaling all items on .c
   .c  scale scalable 0 0 $relScaling $relScaling

   # adjust the scrollbars:  
   #
   # this is where the center of the zoombox, on the underlying canvas
   # got scaled to as a result of our zoom
   set zcenx [expr $relScaling * $cenx]
   set zceny [expr $relScaling * $ceny]

   # this is the fraction of the canvas we want to left of left-edge of visible screen
   set xfrac [expr  ($zcenx - ($visibleWidth/2.0)) / (1.0 * $cregx) ]
   if {$xfrac < 0.0 } {
      # too small, reset
      set xfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to left can possibly be, given current
   # size of visible region and current canvas size
   set maxxfrac [expr ((1.0 * $cregx)-$visibleWidth) / (1.0*$cregx) ]
   if {$xfrac > $maxxfrac} {
      # too big, reset
      set xfrac $maxxfrac
   }

   # this is the fraction of the canvas we want to top of top-edge of visible screen
   set yfrac [expr  ($zceny - ($visibleHeight/2.0)) / (1.0 * $cregy) ]
   if {$yfrac < 0.0 } {
      #too small, reset
      set yfrac 0.0
   }
   # check for too big case
   # This is how big the fraction to top can possibly be, given current
   # size of visible region and current canvas size
   set maxyfrac [expr ((1.0 * $cregy)-$visibleHeight) / (1.0*$cregy) ]
   if {$yfrac > $maxyfrac} {
      # too big, reset
      set yfrac $maxyfrac
   }
   
   # adjust scrollbars
   .c xview moveto $xfrac
   .c yview moveto $yfrac

   # update global scaling
   set globalScaling [expr $relScaling * $globalScaling]

}

#------------------------------------------------------------------------
# CLICK & GRAB FUNCTION  -- globals and bindings
#
# Grab the layout and simply "slide" it around, directly, wo touching
# the scrollbar controls themselves
#------------------------------------------------------------------------

# middle button: grab and move layout
 bind .c <ButtonPress-2>   { doStartMoveLayout %x %y }
 bind .c <B2-Motion>       { doMoveLayout %x %y }
 bind .c <ButtonRelease-2> { .c config -cursor left_ptr }

# initialize mouse location history
set oldX 0
set oldY 0

proc doStartMoveLayout { x y } {
 
  # quick sanity check:  if the canvas is empty, we can't do any move calcs, so quit
  if { [llength [.c bbox all]] != 4 } {
      return
  }

 # changes the mouse cursor
 .c config -cursor hand2

 global oldX
 global oldY 
 set oldX  $x
 set oldY  $y

}

proc doMoveLayout { x y } {

 global oldX
 global oldY


 # quick sanity check:  if the canvas is empty, we can't do any move calcs, so quit
 if { [llength [.c bbox all]] != 4 } {
      return
 }

 # get current scrollregion boundaries
 set scr [.c cget -scrollregion]
 set scrollLeft  [lindex $scr 0]
 set scrollTop   [lindex $scr 1]
 set scrollRight [lindex $scr 2]
 set scrollBot   [lindex $scr 3]

 # get current scroll fraction (frac to left or top of visible)
 set xfrac [lindex [.cx get] 0]
 set yfrac [lindex [.cy get] 0]

 # Move the layout to make the current mouse drag-point move to x, y
 .c xview moveto [expr $xfrac - ( ($x - $oldX) / (1.0*($scrollRight- $scrollLeft)))]
 .c yview moveto [expr $yfrac - ( ($y - $oldY) / (1.0*($scrollBot - $scrollTop)))]

 # remember this drag point
 set oldX $x
 set oldY $y

}




#------------------------------------------------------------------------
# trackmouse {x y }
#
# USEFUL DEBUGGING ROUTINE TO TRACK MOUSE AND WRITE COORDS...
#------------------------------------------------------------------------
proc trackmouse {x y } {

    # primarily for debug

   global globalScaling
   global zboxXstart zboxYstart zboxXend zboxYend

   set cx [.c canvasx $x]
   set cy [.c canvasy $y]
   set wi [winfo width .c]
   set hi  [winfo height .c]
   set scr [.c cget -scrollregion]
   set scrx0 [lindex $scr 0]
   set scry0 [lindex $scr 1]
   set scrx [lindex $scr 2]
   set scry [lindex $scr 3]
   set foo [format "click(%.1f %.1f) canvas(%.1f %.1f) visib(wid %.1f hi %.1f) \n scrollreg(%.1f %.1f %.1f %.1f) zbox(%.1f -- %.1f)(%.1f -- %.1f)" \
                   $x $y $cx $cy $wi $hi $scrx0 $scry0 $scrx $scry \
                   $zboxXstart $zboxXend $zboxYstart $zboxYend]
   .msg configure -text $foo -font {time 6 }

}



#------------------------------------------------------------------------
#
# RULER BOX -- ruler-type measurement using a drawn box on .c canvas
#
#------------------------------------------------------------------------

#------------------------------------------------------------------------
# RULER BOX GLOBAL VARS STUFF
#------------------------------------------------------------------------
set RULERSCALE 1.0
set RULERUNITS "xxx"
set rxstart 0
set rxend 0
set rystart 0
set ryend 0
set inRulerNow 0

#------------------------------------------------------------------------
# RULER BOX GLOBAL FONT STUFF
#------------------------------------------------------------------------
set rulerfont [font create -family helvetica -size 12 -weight bold]

#------------------------------------------------------------------------
# RULERSTART
#
#   draw a degenerate 1pt box, with text.  be careful to transform the
#   click at (x,y) into underlying canvas coords, and to undo the effect
#   of scaling
#
#------------------------------------------------------------------------
proc rulerStart { x y } {
   global rxstart
   global rystart
   global globalScaling
   global RULERSCALE RULERUNITS rulerfont

   # quick sanity check:  if the canvas is empty, we can't do any ruler calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   set rxstart [.c canvasx $x]
   set rystart [.c canvasy $y]
   set xpoint [expr $rxstart/$globalScaling] 
   set xpoint [expr $RULERSCALE * $xpoint]
   set ypoint [expr $rystart/$globalScaling]
   set ypoint [expr $RULERSCALE * $ypoint]
   .c create rectangle $rxstart $rystart $rxstart $rystart -outline red -tag ruler
   .c create text [expr $rxstart ] [expr $rystart - 5]  -anchor s -fill red  -tag ruler\
       -font $rulerfont -text [format "dx %.3fu   dy %.3fu   diag %.3f %s " $xpoint $ypoint 0 $RULERUNITS]
}

#------------------------------------------------------------------------
# RULERMOVE
#
#   drag the box by deleting the prior box and redrawing it.
#   also draw a line to show the diagonal from start-end.
#   again, be careful abouts canvas coords and scaling
#------------------------------------------------------------------------
proc rulerMove { x y } {
   global rxstart rystart rxend ryend
   global globalScaling
   global RULERSCALE  RULERUNITS rulerfont

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   set rxend [.c canvasx $x]
   set ryend [.c canvasy $y]
   set rwidth [expr abs( $rxend - $rxstart )/$globalScaling ]
   set rwidth [expr $RULERSCALE * $rwidth]
   set rheight [expr abs( $ryend - $rystart)/$globalScaling ]
   set rheight [expr $RULERSCALE * $rheight]
   set rdiag [expr sqrt( ($rheight * $rheight) + ($rwidth * $rwidth) )]
   .c delete "ruler"
   .c create rectangle $rxstart $rystart $rxend $ryend -outline red -tag ruler
   .c create line $rxstart $rystart $rxend $ryend -fill red -tag ruler
   .c create text [expr ($rxstart + $rxend)/2.0] [expr $rystart - 5]  -anchor s -fill red -tag ruler\
       -font $rulerfont -text [format "dx %.3f  dy %.3f  diag %.3f %s " $rwidth $rheight $rdiag $RULERUNITS]

}

#------------------------------------------------------------------------
# RULEREND
#
#   kill the ruler box and its text
#   again, be careful abouts canvas coords and scaling
#------------------------------------------------------------------------
proc rulerEnd { x y } {

   # quick sanity check:  if the canvas is empty, we can't do any zoom calcs, so quit
   if { [llength [.c bbox all]] != 4 } {
      return
   }

   .c delete "ruler"

}

#------------------------------------------------------------------------
#
# DORULER callback for the ruler button
#
#   Note we have state:  if inRulerNow=0, we set it to 1, and make button
#   looked pressed in.  This means we override button1 on mouse 
#   and use it to do ruler boxes.  When we click here again,
#   if inRUlerNow=1, then we reset it to 0, pop button back out,
#   and  rebind button1 to the incremental zoomin
#------------------------------------------------------------------------
proc doRuler {} {

global inRulerNow

   if { $inRulerNow == 0 } {
      # ruler button not pressed, so "press" it

      set inRulerNow 1
      .bottom.ruler configure -relief sunken
      
      # rebind: left click == draw/drag a temp measure box with size annotated on it
      bind .c <ButtonPress-1>   { rulerStart %x %y }
      bind .c <B1-Motion>       { rulerMove  %x %y }
      bind .c <ButtonRelease-1> { rulerEnd   %x %y }
      return
   } 

   if { $inRulerNow == 1 } {

      # ruler button is pressed, so "UNpress" it

      set inRulerNow 0
      .bottom.ruler configure -relief raised

      # rebind: left click == incremental zoom in and zoom box
      bind .c <ButtonPress-1>   { ZoomBoxStart %x %y }
      bind .c <B1-Motion>       { ZoomBoxMove  %x %y }
      bind .c <ButtonRelease-1> { ZoomBoxEnd   %x %y }
   }
}



#------------------------------------------------------------------------
# MOVIE PLAY / REPLAY FRAME SLIDER  GLOBAL VARS
#
#------------------------------------------------------------------------

# Intepretation is this is num of seconds to wait between frames
set globalReplayDelay 0

# indicator for having pressed STOP button
set globalStopState 0

# WAITING FOR MULTIPLE FRAME DISPLAYS IN NONREPLAY MODE-- globals 
set nextwait 1

#------------------------------------------------------------------------
# MOVIE PLAY / REPLAY FRAME SLIDER
#
# We basically save each "frame" of drawing commands in a list movieFrame(i),
# updating a counter called frameCount.  The slider just grabs the list
# with the number on the slider, and then evals it to start drawing.
#------------------------------------------------------------------------

proc doReplay { frameIndex } {
global movieFrame autoZoomToFitState


   if { [info exists movieFrame($frameIndex)] == 1 } {

      eval $movieFrame($frameIndex) 
     
      # ok, we just drew the stuff in this frame.  If auto zoomtofit is
      # enabled in the OPTIONS menu, then we call the zoom-to-fit
      # routine right here, to effect the zoom.
      if { $autoZoomToFitState == 1 } {
        doZoomFIT
      }

   } else {
      notice_show "Whoops! Frame $frameIndex does not exist...  Error!" error
   }
}

#------------------------------------------------------------------------
# doSetDelay { svalue }
#
# RESET MOVIE PLAY SPEED, IE, DELAY BETWEEN FRAMES just 
#
#------------------------------------------------------------------------
proc doSetDelay { svalue } {

    global globalReplayDelay
 
    # turn this numnber, which is the value on the delay slider,
    # in seconds, into milli-seconds, since our delay loops will
    # be in terms of milliseconds later.
    set globalReplayDelay [expr 1000 * $svalue]
}


#------------------------------------------------------------------------
# doNext {}
#
# SEQUENCING THRU MULTIPLE FRAME DISPLAYS -- diff behavior depending on
#   whether movies are being played from file, or if this is live
#   thru a socket
#
#------------------------------------------------------------------------
proc doNext {} {

  global nextwait movieLive enableReplay  movieDone 

  # if we are live from a pipe, this doesn't do anything at the moment
  if { $movieLive == 1 } {
     return
  }
  
  # if we get here we are reading tcl from a file, but don't have replay
  # on, so we just update the global "nextwait" var and each "cmuframe"
  # command in the source stream just does a "tkwait variable nextwait" to
  # wait on this.  ALlows viewers to seq thru one frame at a time
  if { $enableReplay == 0 } {
     # modify the global variable nextwait
     set nextwait [expr $nextwait + 1]
     return
  }

  # if we get here, we are reading tcl from a file with replay on;
  # BUT, if the movie is not done reading yet, we just do nothing...yet...
  if { $movieDone == 0 } {
     return
  }

  # OK, if we get here, we are reading tcl from a file WITH replay enabled
  # AND, finally, the movie is all read into the movieFrame(i) lists.
  # We just control the replay slider to go to the next frame
  set currframe [.bottom.replay get ]
  set currframe [expr $currframe + 1]
  .bottom.replay set $currframe
}



#------------------------------------------------------------------------
# doPrev {}
#
# SEQUENCING THRU MULTIPLE FRAME DISPLAYS -- diff behavior depending on
#   whether movies are being played from file, or if this is live
#   thru a socket
#
#------------------------------------------------------------------------
proc doPrev {} {

  global nextwait movieLive enableReplay  movieDone 

  # if we are live from a pipe, this doesn't do anything at all
  if { $movieLive == 1 } {
     return
  }
  
  # if we get here we are reading tcl from a file, but don't have replay
  # on, we also do nothing.  No support for "Previous" frames in this mode
  if { $enableReplay == 0 } {
     return
  }

  # if we get here, we are reading tcl from a file with replay on;
  # BUT, if the movie is not done reading yet, we just do nothing...yet...
  if { $movieDone == 0 } {
     return
  }

  # OK, if we get here, we are reading tcl from a file WITH replay enabled
  # AND, finally, the movie is all read into the movieFrame(i) lists.
  # We just control the replay slider to go to the PREVIOUS frame
  set currframe [.bottom.replay get ]
  set currframe [expr $currframe - 1]
  .bottom.replay set $currframe
}

#------------------------------------------------------------------------
# doPlay {}
#
# AUT PLAY FOR MULTIPLE FRAME DISPLAYS -- diff behavior depending on
#   whether movies are being played from file, or if this is live
#   thru a socket
#
#------------------------------------------------------------------------
proc doPlay {} {

  global nextwait movieLive enableReplay movieDone 
  global frameCounter globalStopState globalReplayDelay 

  # if we are live from a pipe, this doesn't do anything at the moment
  if { $movieLive == 1 } {
     return
  }
  
  # if we get here we are reading tcl from a file, but don't have replay
  # on, so we just update the global "nextwait" var and each "cmuframe"
  # command in the source stream just does a "tkwait variable nextwait" to
  # wait on this.  Allows viewers to seq thru one frame at a time
  if { $enableReplay == 0 } {
     # modify the global variable nextwait
     set nextwait [expr $nextwait + 1]
     return
  }

  # if we get here, we are reading tcl from a file with replay on;
  # BUT, if the movie is not done reading yet, we just do nothing...yet...
  if { $movieDone == 0 } {
     return
  }

  # OK, if we get here, we are reading tcl from a file WITH replay enabled
  # AND, finally, the movie is all read into the movieFrame(i) lists.
  # We are just going to loop:  
  #     display the frame, wait, go to next frame, repeat.
  # 
  set playdone 0
  while { $playdone == 0 }  {

    # get the current frame being displayed.  
    # NOTE -- this should allow user to GRAB the slider
    # and move it, and we will still continue to play
    # more or less correctly, since we always GRAB
    # the current displayed frame ID, and use that to
    # rewind.
    set currframe [.bottom.replay get ]
    set currframe [expr $currframe + 1]

    # go forward one frame
    .bottom.replay set $currframe

    # AND, then we wait globalReplayDelay milliseconds of DELAY
    # So that the canvas doesnt go totally dead, we do this
    # in a loop, delaying for 50ms at a time, and after
    # each of these quantums, we do an update (to handle pending events).  
    # When the for loop goes past the num of 50ms quantums in the $movieDelay
    # global delay spec, we return. 
    # NOTE -- we also allow for 2 other conditions to get out of the wait loop
    #    1 if the STOP button is pressed, it will interrupt us,
    #      so we are checking for the globalStopState var being set
    #    2 if this is the LAST frame.  Its a bit dumb to put this in the loop,
    #      but it makes this easy.  LAST frame = $frameCounter
    update
    for {set md 0} \
        {($md <= $globalReplayDelay) && ($globalStopState != 1) && ($currframe != $frameCounter)}\
        {set md [expr $md + 50]} {
      after 50
      update
    }

    # if we trapped out on the global STOP, unset it now, and note that we can get
    # out of the overall play loop
    if { $globalStopState == 1} {
      set globalStopState 0
      set playdone 1
    }

    # if the frame was the LAST frame, we can also quit
    if { $currframe == $frameCounter} {
      set globalStopState 0
      set playdone 1
    }
  }
}


#------------------------------------------------------------------------
# doRewind {}
#
# AUTO REWIND FOR MULTIPLE FRAME DISPLAYS -- diff behavior depending on
#   whether movies are being played from file, or if this is live
#   thru a socket
#
#------------------------------------------------------------------------
proc doRewind {} {

  global nextwait movieLive enableReplay  movieDone 
  global frameCounter globalStopState globalReplayDelay 

  # if we are live from a pipe, this doesn't do anything at the moment
  if { $movieLive == 1 } {
     return
  }
  
  # if we get here we are reading tcl from a file, but don't have replay
  # on, so we just update the global "nextwait" var and each "cmuframe"
  # command in the source stream just does a "tkwait variable nextwait" to
  # wait on this.  Allows viewers to seq thru one frame at a time
  if { $enableReplay == 0 } {
     # modify the global variable nextwait
     set nextwait [expr $nextwait + 1]
     return
  }

  # if we get here, we are reading tcl from a file with replay on;
  # BUT, if the movie is not done reading yet, we just do nothing...yet...
  if { $movieDone == 0 } {
     return
  }

  # OK, if we get here, we are reading tcl from a file WITH replay enabled
  # AND, finally, the movie is all read into the movieFrame(i) lists.
  # We are just going to loop:  
  #     display the frame, wait, go to next frame, repeat.
  # 
  set rewinddone 0
  while { $rewinddone == 0 }  {

    # get the current frame being displayed.  
    # NOTE -- this should allow user to GRAB the slider
    # and move it, and we will still continue to play
    # more or less correctly, since we always GRAB
    # the current displayed frame ID, and use that to
    # rewind.
    set currframe [.bottom.replay get ]
    set currframe [expr $currframe - 1]

    # go back one frame
    .bottom.replay set $currframe

    # AND, then we wait globalReplayDelay milliseconds of DELAY
    # So that the canvas doesnt go totally dead, we do this
    # in a loop, delaying for 50ms at a time, and after
    # each of these quantums, we do an update (to handle pending events).  
    # When the for loop goes past the num of 50ms quantums in the $movieDelay
    # global delay spec, we return. 
    # NOTE -- we also allow for 2 other conditions to get out of the wait loop
    #    1 if the STOP button is pressed, it will interrupt us,
    #      so we are checking for the globalStopState var being set
    #    2 if this is the FIRST frame == 0.  Its a bit dumb to put this in the loop,
    #      but it makes this easy.
    update
    for {set md 0} \
        {($md <= $globalReplayDelay) && ($globalStopState != 1) && ($currframe != 0)} \
        {set md [expr $md + 50]} {
      after 50
      update
    }

    # if we trapped out on the global STOP, unset it now, and get out of overall loop
    if { $globalStopState == 1} {
      set globalStopState 0
      set rewinddone 1
    }

    # if the frame was the FIRST frame, we can also quit
    if { $currframe == 0} {
      set globalStopState 0
      set rewinddone  1
    }

  }
}

#------------------------------------------------------------------------
# doStop {}
#
# STOP button for aut PLAY, REWIND modes 
#
#------------------------------------------------------------------------
proc doStop {} {

  global globalStopState 
  set globalStopState 1

}




#------------------------------------------------------------------------
#
# BASIC CONFIGURATION & SETUP COMMANDS  FOR .c CANVAS
#
#   To allow for replay, we cannot support "naked" draw commands to .c,
#   so we wrapper the basic commands we need here, so that we can intercept
#   them and either do the drawin directly, or save the correct commands
#   in movieFrame(i) for later replay.
#------------------------------------------------------------------------

proc cmuconfig { width height  scrollxmin scrollymin  scrollxmax scrollymax } {

global SCROLLMAXX SCROLLMAXY   movieFrame frameCounter movieLive enableReplay movieDone

    # if we are in live mode 
    # OR not supporting replay, 
    # OR we are in replay, and we are now actually replaying a stored command,
    # then we just "do it"
    if {$movieLive==1 || $enableReplay==0 || ($movieDone==1 && $enableReplay==1)} {

       # configure the canvas .c for initial drawing
       .c configure -width $width -height $height  
       set scrollreg {}
       lappend scrollreg  $scrollxmin $scrollymin $scrollxmax $scrollymax 
       .c configure -scrollregion $scrollreg
       set SCROLLMAXX $scrollxmax 
       set SCROLLMAXY $scrollymax 

       # to be conservative, do an update to tcl nhandle pending events
       update
   
    } else {

       # we are supporting replay from a tcl file.  this is the first
       # time we have seen this command FROM this file.  Don't "do it", just
       # write the appropriate commands into the current movie frame

       append movieFrame($frameCounter)\
"cmuconfig $width $height $scrollxmin $scrollymin $scrollxmax $scrollymax ; "

   }

}

#------------------------------------------------------------------------
#
# CONFIGURATION FOR THE RULER
#
#   To allow for replay, we cannot support "naked" commands to set global vars,
#   so we wrapper the basic commands we need here, so that we can intercept
#   them and either do the right thing directly, or save the correct commands
#   in movieFrame(i) for later replay.
#------------------------------------------------------------------------


proc cmuruler { rulerSetup rulerSetUnits} {

global RULERSCALE RULERUNITS   movieLive enableReplay  movieDone movieFrame frameCounter


    # if we are in live mode 
    # OR not supporting replay, 
    # OR we are in replay, and we are now actually replaying a stored command,
    # then we just "do it"
    if {$movieLive==1 || $enableReplay==0 || ($movieDone==1 && $enableReplay==1)} {


       # configure the ruler
       # save the global scaling variable.  Intepretation is that
       #  rulerScale units of length in our drawin == 1 ruler-unit
       set RULERSCALE $rulerSetup 
       set RULERUNITS $rulerSetUnits
      
       # to be conservative we also do an update to let tcl process pending events
       update

    } else {

       # we are supporting replay from a tcl file.  This is the first time
       # we have seen this command FROM the file.  Don't "do it", just
       # write the appropriate commands into the current movie frame

       append movieFrame($frameCounter) "cmuruler $rulerSetup $rulerSetUnits; "
   }
}



#------------------------------------------------------------------------
#
# CLEAR CANVAS .c
#
#   To allow for replay, we cannot support "naked" draw commands to .c,
#   so we wrapper the basic commands we need here, so that we can intercept
#   them and either do the drawin directly, or save the correct commands
#   in movieFrame(i) for later replay.
#------------------------------------------------------------------------

proc cmuclear { } {

global movieLive enableReplay movieDone movieFrame frameCounter balloonNote


    # if we are in live mode 
    # OR not supporting replay, 
    # OR we are in replay, and we are now actually replaying a stored command,
    # then we just "do it"
    if {$movieLive==1 || $enableReplay==0 || ($movieDone==1 && $enableReplay==1)} {

       # clear the canvas .c of ALL drawn stuff
       .c delete all 

       # and, we also delete ALL the balloonNote() strings we may have set
       # so that they do NOT accumulate, frame to frame
       array unset balloonNote

       # also, to be conservative, we do an update to let tcl handle pending events
       update

    } else {

       # we are supporting replay from a tcl file.  we are reading this
       # command for the first time FROM the file.  Don't "do it", just
       # write the appropriate commands into the current movie frame

       append movieFrame($frameCounter) "cmuclear ; "
   }
}

#------------------------------------------------------------------------
#
# MOVIE SETUP
#
#   To understand if it is being used in a "live" thru-a-pipe mode,
#   or reading a saved tcl file of draw commands, and whether or not
#   we should save the drawn frames in a way that allows for "replay",
#   we need to config the drawing commands.  This proc just
#   sets a few global variables we need for this purpose:
#          movieLive   == 1 if thru a pipe,  == 0 if from a file
#          enableReplay == 0 if no replay allowed from file, else == 1
#          movieDone == 0 means we have not seen an "exit" cmd in source stream yet
#                    == 1 means we have seen "exit", mean movie frames done
#          movieDelay == how many milliseconds to wait if in LIVE mode, betw frames
#          frameCounter starts at 0, and increments to index each movie 
#               frame delimited by cmuframe commands
#------------------------------------------------------------------------

#define and set defaults on these global variables
set movieLive 1
set movieDone 0
set movieDelay 0
set enableReplay 0
set frameCounter 0
set movieFrame(0) {}

proc cmumovie { live replay mdelay } {

global movieLive movieDone movieDelay enableReplay frameCounter movieFrame

    if {$live != 0} {
       set movieLive 1
       # if movie is live, we enforce NO replay no matter what param was...
       set enableReplay 0
       # and the delay param gets saved globally
       set movieDelay $mdelay
    } else {
        set movieLive 0
        if { $replay != 0 } {
           set enableReplay 1
           set frameCounter 0
           set movieFrame(0) {}
        }
    }
}



#------------------------------------------------------------------------
#
# MOVIE FRAME BOUNDARY DEFINITION
#
#   To allow for replay, we have to know the boundaries between drawn
#   "frames" of the movie.  cmuframe command is this delimiter, it
#   marks the end of the previous frame, the start of the next frame.
#   NOTE that a frame is just the array movieFrame with an int index to
#   access ie  movieFrame($frameCounter), == movieFrame(0)  movieFrame(1)...
#------------------------------------------------------------------------

proc cmuframe { } {
global  nextwait  movieFrame  movieDelay frameCounter  movieLive movieDone enableReplay

   #cmuframe marks frame boundaries.  2 basic modes of op here:
   #
   # movieLive = 1  &&  enableReplay = xx
   #    We are live thru a pipe, so this means we don't save any 
   #    commands in movieFrame(i), we
   #    just update the canvas for redrawing, and return
   # movieLive = 0 && enableReplay = 0
   #    We are viewing commands from a file, but no replay is allowed,
   #    so we just wait here for a change in the "nextwait" variable that the "next" button
   #    incements in this  code.  THis is the "old" standard mode for
   #    viewing movies in sequential order only
   # movieLive = 0 && enableReplay = 1
   #    We are reading the source tcl stream for the first time, so this
   #    cmuframe command is the first time we have "seen" it, so we
   #    just increment the frame counter and make the new empty
   #    movieFrame().  We don't copy this command into the
   #    movieFrame, since we don't need it to do any "waiting" 
   #    behavior, but we DO force an update here, just to be conservative and
   #    let the tcl interpreter have a chance to process events; this
   #    helps when readinb a very long file to not make the drawing editor
   #    "go dead" for long periods of time 

   if {$movieLive == 1} {
      # we just delay until $movieDelay milliseconds, then return.
      # So that the canvas doesnt go totally dead, we do this
      # in a loop, delaying for 100ms at a time, and after
      # each of these quantums, we do an update (to handle pending events).  
      # When the for loop goes past the num of 100ms quantums in the $movieDelay
      # global delay spec, we return. 
      for {set md 0} {$md <= $movieDelay} {set md [expr $md + 100]} {
        after 100
        update
      }

   } elseif {$movieLive == 0 && $enableReplay == 0} {

      # reading from a file, but no replay is allowed, so just wait on
      # a change in the nextwait variable that the NEXT button increments
      update
      tkwait variable nextwait
      update
   } else {
      
      # we are reading tcl from a file, and we are allowing  replay, so,
      # make next (empty) movie frame, update frame counter
      set frameCounter [expr $frameCounter + 1]
      set movieFrame($frameCounter) {}

      # update replay slider label so user knows we just got another frame
      .bottom.replay configure -label "Reading movie frame $frameCounter..."

      # do an update so we make sure we can see this label string changing
      update

   }

}



#------------------------------------------------------------------------
#
# FONT GLOBALS FOR DRAWING ON .c CANVAS
#
#   we define a few "cmu" font objects, which gives us some flexibility
#   later in changing the appearance of text drawn with the following
#   commands
#------------------------------------------------------------------------
set cmufontwhite [font create -family helvetica -size 8]
set cmufontdark  [font create -family helvetica -size 8]


#------------------------------------------------------------------------
#
# DRAWING COMMANDS FOR .c CANVAS
#
#    Remember--  goal is for these to be SHORT
#    since animations generate a zillion lines of lines.
#
#    About the tags:  every object gets a "scalable" tag since this is
#    how we do zooms.  each object also gets a type, eg, "rectf" means
#    filled rectangle.  we need this for the zoom to fit, which
#    needs to calculate the "fit" for the objects is can actually resize
#    like rects, ovals, lines, but not for stuff whose location moves but
#    whoses size does not change under .c scale ...:  this means text.
#   
#    In addition, everything gets a 'color' tag, either "out<color>"
#    fill<color>, line<color> or text<color> to indicate what it is
#    and what color it is.  Used by the color palette to enable/disable
#    viewing of objects by color.
#
#    There are 2 versions of each command.  The regular version,
#    eg, "rf" for "draw filled rect", and  "rfb" for "draw filled
#    rect with a balloon help-style note string".  rfb is useful
#    for a FEW objects that you want to be able to highlight
#    when the cursor passes over them, and display an optional
#    note text string in a standard Balloon Help window
#
#------------------------------------------------------------------------


#------------------------------------------------------------------------
# ro {minx miny maxx maxy color}
#
# rectangle draw, outlined by not filled
#------------------------------------------------------------------------
proc ro { minx miny maxx maxy color} {
global globalScaling  palette$color  movieLive movieDone frameCounter  movieFrame  enableReplay

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     .c create rectangle [expr $globalScaling*$minx]c [expr $globalScaling*$miny]c \
                         [expr $globalScaling*$maxx]c [expr $globalScaling*$maxy]c \
            -outline $currentcolor -tags "recto scalable out$color"

   } elseif {$enableReplay==1} {
     
       #if we are allowing rewind/replay, but we are not done with all frames yet,
       #  save this drawing cmd into current frame
      append movieFrame($frameCounter) "ro $minx $miny $maxx $maxy $color ; "
   }
}


#------------------------------------------------------------------------
# rf {minx miny maxx maxy color}
#
# rectangle draw, outlined (in black) and filled
#------------------------------------------------------------------------
proc rf { minx miny maxx maxy color} {
global globalScaling  palette$color  frameCounter movieFrame enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }  
     .c create rectangle [expr $globalScaling*$minx]c [expr $globalScaling*$miny]c \
                         [expr $globalScaling*$maxx]c [expr $globalScaling*$maxy]c \
               -fill $currentcolor -tags "rectf scalable fill$color"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "rf $minx $miny $maxx $maxy $color ; "
   }
}



#------------------------------------------------------------------------
# ln {x1 y1 x2 y2 color}
#
# line draw,  filled
#------------------------------------------------------------------------
proc ln { x1 y1 x2 y2 color} {
global globalScaling  palette$color  frameCounter movieFrame enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }  
     .c create line [expr $globalScaling*$x1]c [expr $globalScaling*$y1]c \
                    [expr $globalScaling*$x2]c [expr $globalScaling*$y2]c \
               -fill $currentcolor -tags "line scalable line$color"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "ln $x1 $y1 $x2 $y2 $color ; "
   }
}



#------------------------------------------------------------------------
# fln {lwid x1 y1 x2 y2 color}
#
# FAT line draw,  filled, with an arbitrary line width lwid
#------------------------------------------------------------------------
proc fln { lwid x1 y1 x2 y2 color} {
global globalScaling  palette$color  frameCounter movieFrame enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }  
     .c create line [expr $globalScaling*$x1]c [expr $globalScaling*$y1]c \
                    [expr $globalScaling*$x2]c [expr $globalScaling*$y2]c \
              -width $lwid  -fill $currentcolor -tags "line scalable line$color"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "fln $lwid $x1 $y1 $x2 $y2 $color ; "
   }
}

#------------------------------------------------------------------------
# ar {minx miny maxx maxy color}
#
# arrow draw,  filled
#------------------------------------------------------------------------
proc ar { x1 y1 x2 y2 color} {
global globalScaling  palette$color  frameCounter  movieFrame enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     .c create line [expr $globalScaling*$x1]c [expr $globalScaling*$y1]c \
                    [expr $globalScaling*$x2]c [expr $globalScaling*$y2]c \
              -fill $currentcolor -arrow last -tags "arrow scalable line$color"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "ar $x1 $y1 $x2 $y2 $color ; "
   }
}

#------------------------------------------------------------------------
# ov {minx miny maxx maxy color}
#
# oval draw, outlined in black and  filled
#------------------------------------------------------------------------
proc ov { left bottom right top color} {
global globalScaling  palette$color  frameCounter  movieFrame  enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     .c create oval [expr $globalScaling*$left]c [expr $globalScaling*$bottom]c \
                    [expr $globalScaling*$right]c [expr $globalScaling*$top]c \
               -fill $currentcolor  -tags "oval scalable  fill$color"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame

      append movieFrame($frameCounter) "ov $left $bottom $right $top $color ; "
   }

}



#------------------------------------------------------------------------
# rob {minx miny maxx maxy color note}
#
# rectangle draw, outlined by not filled, with Highlights + Balloon Note
#------------------------------------------------------------------------
proc rob { minx miny maxx maxy color note} {
global globalScaling  palette$color  movieLive movieDone frameCounter  movieFrame  enableReplay 
global balloonNote

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     set id [.c create rectangle [expr $globalScaling*$minx]c [expr $globalScaling*$miny]c \
                         [expr $globalScaling*$maxx]c [expr $globalScaling*$maxy]c \
            -outline $currentcolor -tags "recto scalable out$color B"]
     set balloonNote($id)  $note

   } elseif {$enableReplay==1} {
     
       #if we are allowing rewind/replay, but we are not done with all frames yet,
       #  save this drawing cmd into current frame
      append movieFrame($frameCounter) "rob $minx $miny $maxx $maxy $color \"$note\"; "
   }
}


#------------------------------------------------------------------------
# rfb {minx miny maxx maxy color note}
#
# rectangle draw, outlined (in black) & filled, with Highlights + Balloon Note
#------------------------------------------------------------------------
proc rfb { minx miny maxx maxy color note} {
global globalScaling  palette$color  frameCounter movieFrame enableReplay movieLive movieDone
global balloonNote

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }  
     set id [.c create rectangle [expr $globalScaling*$minx]c [expr $globalScaling*$miny]c \
                         [expr $globalScaling*$maxx]c [expr $globalScaling*$maxy]c \
               -fill $currentcolor -tags "rectf scalable fill$color B"]
     set balloonNote($id) $note

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "rfb $minx $miny $maxx $maxy $color \"$note\"; "
   }
}



#------------------------------------------------------------------------
# lnb {x1 y1 x2 y2 color note}
#
# line draw,  filled, with Highlights + Balloon Note
#------------------------------------------------------------------------
proc lnb { x1 y1 x2 y2 color note} {
global globalScaling  palette$color  frameCounter movieFrame enableReplay movieLive movieDone
global balloonNote

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }  
     set id [.c create line [expr $globalScaling*$x1]c [expr $globalScaling*$y1]c \
                    [expr $globalScaling*$x2]c [expr $globalScaling*$y2]c \
              -fill $currentcolor -tags "line scalable line$color B"]
     set balloonNote($id) $note

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "lnb $x1 $y1 $x2 $y2 $color \"$note\"; "
   }
}

#------------------------------------------------------------------------
# arb {minx miny maxx maxy color note}
#
# arrow draw,  filled, with Highlights + Balloon Note
#------------------------------------------------------------------------
proc arb { x1 y1 x2 y2 color note} {
global globalScaling  palette$color  frameCounter  movieFrame enableReplay movieLive movieDone
global balloonNote

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     set id [.c create line [expr $globalScaling*$x1]c [expr $globalScaling*$y1]c \
                    [expr $globalScaling*$x2]c [expr $globalScaling*$y2]c \
              -fill $currentcolor -arrow last -tags "arrow scalable line$color B"]
     set balloonNote($id) $note

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame
      append movieFrame($frameCounter) "arb $x1 $y1 $x2 $y2 $color \"$note\"; "
   }
}

#------------------------------------------------------------------------
# ovb {minx miny maxx maxy color note}
#
# oval draw, outlined in black and  filled, with Highlights + Balloon Note
#------------------------------------------------------------------------
proc ovb { left bottom right top color note} {
global globalScaling  palette$color  frameCounter  movieFrame  enableReplay movieLive movieDone
global balloonNote

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      #get the palette color status
      eval "set col \$palette$color"

      #if the color is OFF for drawing, override the color setting
      set currentcolor $color
      if {$col == 0} {
         set currentcolor {}
      }
     set id [.c create oval [expr $globalScaling*$left]c [expr $globalScaling*$bottom]c \
                    [expr $globalScaling*$right]c [expr $globalScaling*$top]c \
               -fill $currentcolor  -tags "oval scalable  fill$color B"]
     set balloonNote($id) $note

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame

      append movieFrame($frameCounter) "ovb $left $bottom $right $top $color \"$note\"; "
   }

}
 



#------------------------------------------------------------------------
# tc {x y txt color}
#
# text draw, anchor=center
#------------------------------------------------------------------------
proc tc { x y txt  color} {
global globalScaling cmufontwhite cmufontdark  frameCounter  movieFrame 
global enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      # we track text only as to whether it is "white" or "dark"
      # where "dark" means != white
      set texttag textwhite
      set fonttag $cmufontwhite
      if {$color != "white" } {
         set texttag textdark
         set fonttag $cmufontdark
      }
      .c create text [expr $globalScaling*$x]c [expr $globalScaling*$y]c \
               -text $txt  -font $fonttag \
               -fill $color -anchor center -tags "text scalable $texttag"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame

      append movieFrame($frameCounter) "tc $x $y \"$txt\" $color ; "
   }
}

#------------------------------------------------------------------------
# tnw {x y txt color}
#
# text draw, anchor=northwest
#------------------------------------------------------------------------
proc tnw { x y txt  color} {
global globalScaling cmufontwhite cmufontdark  frameCounter  movieFrame   
global enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      # we track text only as to whether it is "white" or "dark"
      # where "dark" means != white
      set texttag textwhite
      set fonttag $cmufontwhite
      if {$color != "white" } {
         set texttag textdark
         set fonttag $cmufontdark
      }
      .c create text [expr $globalScaling*$x]c [expr $globalScaling*$y]c \
                -text $txt  -font $fonttag \
                -fill $color -anchor nw -tags "text scalable $texttag"

   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame

      append movieFrame($frameCounter) "tnw $x $y \"$txt\" $color ; "
   }

}


#------------------------------------------------------------------------
# tsw {x y txt color}
#
# text draw, anchor=southwest
#------------------------------------------------------------------------
proc tsw { x y txt  color} {
global globalScaling cmufontwhite cmufontdark  frameCounter  movieFrame  
global enableReplay movieLive movieDone

   # do we actually draw this and update state?  only if 
   #    1  we are live thru pipe
   #    2  or pulling draw cmds from a file,  with replay disabled
   #    3  or, pulling commands from a file, replay ON, and all movie frames loaded
   if { $movieLive==1 || $enableReplay==0 || ($enableReplay==1 && $movieDone==1) } {

      # we track text only as to whether it is "white" or "dark"
      # where "dark" means != white
      set texttag textwhite
      set fonttag $cmufontwhite
      if {$color != "white" } {
         set texttag textdark
         set fonttag $cmufontdark
      }
      .c create text [expr $globalScaling*$x]c [expr $globalScaling*$y]c \
                -text $txt  -font $fonttag \
               -fill $color -anchor sw -tags "text scalable $texttag"


   } elseif {$enableReplay==1} {

      #if we are allowing rewind/replay, AND we are not done readihg all frames yet,
      #save this drawing cmd into current frame

      append movieFrame($frameCounter) "tsw $x $y \"$txt\" $color ; "
   }


}


#-------------------------------------------------------------------
# BALLOON "HELP" STYLE NOTES + HIGHLIGHTS FOR DRAWN CANVAS OBJECTS
#    Basics:  we have 2 forms for each drawable object,
#    the basic form, eg  rf .... for a filled rect, and
#    the "balloon" form, eg  rfb .... for a filled rect that
#    has 2 additional, useful behaviors:
#      1.  It will highlight when the cursor touches it.
#      2.  A string, called a Balloon Note, will be displayed
#          (if a non-null string is provided), using the standard
#          balloon help mechanism
#
# Here are the Bindings for cursor entry/exit of objs on our canvas
#-------------------------------------------------------------------

# set up binding so that any entry/exit on the main
# drawing canvas gets the proper callback
.c bind all <Any-Enter> "scrollEnter .c"
.c bind all <Any-Leave> "scrollLeave .c"

#-------------------------------------------------------------------
# BALLOON "HELP" STYLE NOTES + HIGHLIGHTS FOR DRAWN CANVAS OBJECTS
#    Globals
#-------------------------------------------------------------------

# when we highlight a canvas object, this is where we save its old fill
# so we can restore it when cursor leaves the object
set oldFill ""

# when we highlight a canvas object, this is the default color for it
set globalHighlightColor "red"

# This is an array that stores the Balloon Note strings we use for each
# highlight-able object.  Thw array index is the id of the canvas
# object that is being highlighd
set balloonNote(0) {}
set balloonNoteVisible 0

#------------------------------------------------------------------------
# scrollEnter { nameOfCanvas}
#
#   invoked on binding callback anytime cursor passes INTO an
#   object drawn on the named canvas (which is just .c for us).
#   Mostly copied from tk8.3 widget demo -- Simple Scrollable Canvas,
#   and from the basic Ballon Help utility in our scripts directory
#------------------------------------------------------------------------
proc scrollEnter { canvas } {
    global oldFill  globalHighlightColor  
    global bhInfo  balloonNote balloonNoteVisible

    # find what cursor is over right now -- the object on TOP
    set id [$canvas find withtag current]
 
    # if this thing has a tag named "B", it is BALLOON highlight-able for us
    if {[lsearch [$canvas gettags current] "B" ] >= 0} { 

        # yes indeed -- save the old fill info in this object 
        set oldFill [lindex [$canvas itemconfig $id -fill] 4]

        # highlight it -- change its fill color
        if {[winfo depth $canvas] > 1} {
	      $canvas itemconfigure $id -fill $globalHighlightColor
        }

        # if it has a balloon note string, and Baloon Help is active, 
        # AND we dont already have a balloonNote visible, 
        # THEN its ok try to display a balloon note string
        
        if { $balloonNote($id) != "" && $bhInfo(active) && $balloonNoteVisible==0} {

            # reconfig the standard balloonhelp widget to the right text
            .balloonhelp.info configure -text $balloonNote($id)

            # get global location of cursor in the canvas 
            # then compute a pt a little to the right, below it to display
            set x [expr [winfo pointerx $canvas]+12]
            set y [expr [winfo pointery $canvas]+12]

            # deiconify balloon, make it visible, THEN move it to proper place;
            # doesn't seem to work to move the loc if it's not visible...
            wm deiconify .balloonhelp
            raise .balloonhelp
            wm geometry .balloonhelp +$x+$y

            # remember that the balloon note is VISIBLE.  THis means we
            # only try to drawn the balloon note ONCE, on entry to the object.
            # If the cursor slides around "inside" of the object, the balloon help
            # widget remains fixed.
            set balloonNoteVisible 1

        }
    }
}


#------------------------------------------------------------------------
# scrollLeave { nameOfCanvas}
#
#   invoked on binding callback anytime cursor passes OUT-OF an
#   object drawn on the named canvas (which is just .c for us).
#   Mostly copied from tk8.3 widget demo -- Simple Scrollable Canvas,
#   and from the basic Ballon Help utility in our scripts directory
#------------------------------------------------------------------------
proc scrollLeave { canvas } {
    global oldFill balloonNoteVisible

    # find what cursor is on right now
    set id [$canvas find withtag current]

    #if it has the tag "B" its balloon note highlight-able for us
    if {[lsearch [$canvas gettags current] "B"] >= 0} {

        # yup -- but we just LEFT it.  Restore its old fill info
        $canvas itemconfigure $id -fill $oldFill

        # and, lower the balloon help window if its there
        wm withdraw .balloonhelp
        set balloonNoteVisible 0
    }
}





#------------------------------------------------------------------------
# 
# ... and, that's it.  In the intended usage mode, this script will
#     get sourced first, then what will follow will be a large num
#     of the above drawing commands
# 
#-----------------------------------------------------------------------
