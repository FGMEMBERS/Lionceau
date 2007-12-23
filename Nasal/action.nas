##
#  action-sim.nas   Updates various simulated features including:
#                    egt, fuel pressure, oil pressure every frame
##
# shamelessly copied from the excellent Dave's PA24-250 action-sim.nas file
# and slightly modified to suit Lionceau's specs

#   Initialize local variables
var rpm = nil;
var fuel_pres = 0.0;
var oil_pres = 0.0;
var ias = nil;
var fuel_flow = nil;
var egt = nil;

# set up filters for these actions

var fuel_pres_lowpass = aircraft.lowpass.new(0.5);
var oil_pres_lowpass = aircraft.lowpass.new(0.5);
var egt_lowpass = aircraft.lowpass.new(0.95);

var init_actions = func {
    setprop("engines/engine[0]/fuel-flow-gph", 0.0);
    setprop("/surface-positions/flap-pos-norm", 0.0);
    setprop("/instrumentation/airspeed-indicator/indicated-speed-kt", 0.0);
    setprop("/instrumentation/airspeed-indicator/pressure-alt-offset-deg", 0.0);
    setprop("/accelerations/pilot-g", 1.0);

    # Request that the update fuction be called next frame
    settimer(update_actions, 0);
}


var update_actions = func {
##
#  This is a convenient cludge to model fuel pressure and oil pressure
##
    rpm = getprop("/engines/engine/rpm");
    if (rpm > 600.0) {
        fuel_pres = 6.8-3000/rpm;
        oil_pres = 62-12600/rpm;
    } else {
        fuel_pres = 0.0;
        oil_pres = 0.0;
    }

    if (getprop("/controls/engines/engine/fuel-pump")) {
        fuel_pres += 1.5;
    }

##
#  Simulate egt from pilot's perspective using fuel flow and rpm
##
    fuel_flow = getprop("engines/engine[0]/fuel-flow-gph");
    egt = 325 - abs(fuel_flow - 12)*20;
    if (egt < 20) { egt = 20; }
    egt = egt*(rpm/2400)*(rpm/2400);

##
# outputs
##
    setprop("/engines/engine[0]/egt-degf-fix", egt_lowpass.filter(egt));
    setprop("/engines/engine/fuel-pressure-psi", fuel_pres_lowpass.filter(fuel_pres));
    setprop("/engines/engine/oil-pressure-psi", oil_pres_lowpass.filter(oil_pres));

    settimer(update_actions, 0);
}

# Setup listener call to start update loop once the fdm is initialized
#
setlistener("/sim/signals/fdm-initialized", init_actions);
