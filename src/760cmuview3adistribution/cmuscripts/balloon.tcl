# ----------------------------------------------------------------------
#  EXAMPLE: use "wm" commands to manage a balloon help window
# ----------------------------------------------------------------------
#  Effective Tcl/Tk Programming
#    Mark Harrison, DSC Communications Corp.
#    Michael McLennan, Bell Labs Innovations for Lucent Technologies
#    Addison-Wesley Professional Computing Series
# ======================================================================
#  Copyright (c) 1996-1997  Lucent Technologies Inc. and Mark Harrison
# ======================================================================

option add *Balloonhelp*background white widgetDefault
option add *Balloonhelp*foreground black widgetDefault
option add *Balloonhelp.info.wrapLength 3i widgetDefault
option add *Balloonhelp.info.justify left widgetDefault
option add *Balloonhelp.info.font \
    -*-lucida-medium-r-normal-sans-*-120-* widgetDefault

toplevel .balloonhelp -class Balloonhelp \
    -background black -borderwidth 1 -relief flat

label .balloonhelp.arrow -anchor nw \
   -bitmap @[file join $cmupath cmuimages arrow.xbm]

pack .balloonhelp.arrow -side left -fill y

label .balloonhelp.info
pack .balloonhelp.info -side left -fill y

wm overrideredirect .balloonhelp 1
wm withdraw .balloonhelp

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_for <win> <mesg>
#
#  Adds balloon help to the widget named <win>.  Whenever the mouse
#  pointer enters this widget and rests within it for a short delay,
#  a balloon help window will automatically appear showing the
#  help <mesg>.
# ----------------------------------------------------------------------
proc balloonhelp_for {win mesg} {
    global bhInfo
    set bhInfo($win) $mesg

    bind $win <Enter> {balloonhelp_pending %W}
    bind $win <Leave> {balloonhelp_cancel}
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_control <state>
#
#  Turns balloon help on/off for the entire application.
# ----------------------------------------------------------------------
set bhInfo(active) 1

proc balloonhelp_control {state} {
    global bhInfo

    if {$state} {
        set bhInfo(active) 1
    } else {
        balloonhelp_cancel
        set bhInfo(active) 0
    }
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_pending <win>
#
#  Used internally to mark the point in time when a widget is first
#  touched.  Sets up an "after" event so that balloon help will appear
#  if the mouse remains within the current window.
# ----------------------------------------------------------------------
proc balloonhelp_pending {win} {
    global bhInfo

    balloonhelp_cancel
    set bhInfo(pending) [after 1200 [list balloonhelp_show $win]]
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_cancel
#
#  Used internally to mark the point in time when the mouse pointer
#  leaves a widget.  Cancels any pending balloon help requested earlier
#  and hides the balloon help window, in case it is visible.
# ----------------------------------------------------------------------
proc balloonhelp_cancel {} {
    global bhInfo

    if {[info exists bhInfo(pending)]} {
        after cancel $bhInfo(pending)
        unset bhInfo(pending)
    }
    wm withdraw .balloonhelp
}

# ----------------------------------------------------------------------
#  USAGE:  balloonhelp_show <win>
#
#  Used internally to display the balloon help window for the
#  specified <win>.
# ----------------------------------------------------------------------
proc balloonhelp_show {win} {
    global bhInfo

    if {$bhInfo(active)} {
        .balloonhelp.info configure -text $bhInfo($win)


        # get global location of cursor in the CURRENT widget we entered
        # then compute a pt a little to the right, below it to display
        set x [expr [winfo pointerx $win]+12]
        set y [expr [winfo pointery $win]+12]

        # deiconify balloon, make it visible, THEN move it to proper place;
        # doesn't seem to work to move the loc if it's not visible...
        wm deiconify .balloonhelp
        raise .balloonhelp
        wm geometry .balloonhelp +$x+$y

    }
    unset bhInfo(pending)
}
