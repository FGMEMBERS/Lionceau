# set the timer for the selected function

var UPDATE_PERIOD = 0;

var instrumenttimers = func {
    settimer(func {radiodisplay("comm[0]")}, UPDATE_PERIOD);
    settimer(func {radiodisplay("nav[0]")}, UPDATE_PERIOD);
    settimer(func {radiodisplay("nav[1]")}, UPDATE_PERIOD);
}

# =============================== end timer stuff ===========================================

# ==================== Radio Frequency Display =========================

var radiodisplay = func(radio) {
    var selected=getprop("/instrumentation/"~radio~"/frequencies/selected-mhz");
    var formatted=sprintf("%.02f",selected);

    var digit1=substr(formatted,0,1);
    var digit2=substr(formatted,1,1);
    var digit3=substr(formatted,2,1);
    var digit4=substr(formatted,4,1);
    var digit5=substr(formatted,5,1);

    setprop("instrumentation/"~radio~"/selected/digit1",digit1);
    setprop("instrumentation/"~radio~"/selected/digit2",digit2);
    setprop("instrumentation/"~radio~"/selected/digit3",digit3);
    setprop("instrumentation/"~radio~"/selected/digit4",digit4);
    setprop("instrumentation/"~radio~"/selected/digit5",digit5);

    var standby=getprop("/instrumentation/"~radio~"/frequencies/standby-mhz");
    var formatted=sprintf("%.02f",standby);

    digit1=substr(formatted,0,1);
    digit2=substr(formatted,1,1);
    digit3=substr(formatted,2,1);
    digit4=substr(formatted,4,1);
    digit5=substr(formatted,5,1);

    setprop("instrumentation/"~radio~"/standby/digit1",digit1);
    setprop("instrumentation/"~radio~"/standby/digit2",digit2);
    setprop("instrumentation/"~radio~"/standby/digit3",digit3);
    setprop("instrumentation/"~radio~"/standby/digit4",digit4);
    setprop("instrumentation/"~radio~"/standby/digit5",digit5);

}

####################### Initialise ##############################################

initialize = func {

    ### Initialise Radios ###
    props.globals.getNode("instrumentation/uhf/commvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("instrumentation/kn53/navvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("instrumentation/kx155a/commvol-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("instrumentation/kx155a/navvol-norm", 1).setDoubleValue(0.0);

    instrumenttimers();
    # Finished Initialising
    print ("Instruments : initialised");
    var initialized = 1;

} #end func

######################### Fire it up ############################################
setlistener("/sim/signals/electrical-initialized",initialize);
