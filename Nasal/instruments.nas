# set the timer for the selected function

var UPDATE_PERIOD = 0;
var freq = 0;
var formatted = 0;

var digit1 = 0;
var digit2 = 0;
var digit3 = 0;
var digit4 = 0;
var digit5 = 0;

var gps_display = [];

var instrumenttimer = func {
    settimer(func {
        radiodisplay();
  instrumenttimer()
    }, UPDATE_PERIOD);
}

# =============================== end timer stuff ===========================================

# ==================== Radio Frequency Display =========================
var displaysegments = func (radio, selected) {
    var freq=getprop("/instrumentation/"~radio~"/frequencies/"~selected~"-mhz");
    var formatted=sprintf("%.02f",freq);

    digit1=substr(formatted,0,1);
    digit2=substr(formatted,1,1);
    digit3=substr(formatted,2,1);
    digit4=substr(formatted,4,1);
    digit5=substr(formatted,5,1);

    setprop("instrumentation/"~radio~"/"~selected~"/digit1",digit1);
    setprop("instrumentation/"~radio~"/"~selected~"/digit2",digit2);
    setprop("instrumentation/"~radio~"/"~selected~"/digit3",digit3);
    setprop("instrumentation/"~radio~"/"~selected~"/digit4",digit4);
    setprop("instrumentation/"~radio~"/"~selected~"/digit5",digit5);
}

var radiodisplay = func() {
    displaysegments ("nav[0]", "selected");
    displaysegments ("nav[0]", "standby");

    displaysegments ("comm[0]", "selected");
    displaysegments ("comm[0]", "standby");
}

####################### Initialise ##############################################

initialize = func {

    ### Initialise Radios ###
    props.globals.getNode("/instrumentation/uhf/commvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("/instrumentation/kn53/navvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("/instrumentation/kx155a/commvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("/instrumentation/kx155a/navvol-norm", 1).setDoubleValue(0.0);

 
    instrumenttimer();
    # Finished Initialising
    print ("Instruments : initialised");
    var initialized = 1;

} #end func

######################### Fire it up ############################################
setlistener("/sim/signals/fdm-initialized",initialize);
