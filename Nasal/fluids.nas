var oil_temp_eng = props.globals.getNode("/engines/engine/oil-temperature-degf", 1);
var fuel_press_eng = props.globals.getNode("/engines/engine/fuel-pressure-psi", 1);
var egt_eng = props.globals.getNode("/engines/engine/egt-degf-fix", 1);
var oatf = props.globals.getNode("/environment/temperature-degf", 1);

var oil_temp_inst = props.globals.getNode("/instrumentation/engine/oil-temp", 1);
var fuel_press_inst = props.globals.getNode("/instrumentation/engine/fuel-press", 1);
var cht_inst = props.globals.getNode("/instrumentation/engine/cht-degf", 1);

var initialise_temp = func {
    # all pressures initialized to 0.0
    fuel_press_inst.setDoubleValue(0.0);
    oil_temp_eng.setDoubleValue(0.0);

    #all temperatures initialized to environment temperature
    oil_temp_inst.setDoubleValue(oatf.getValue());
    cht_inst.setDoubleValue(oatf.getValue());

    #settimer(update_press, 0);
    update_temp ();
    print ("fluids system initialized");
}

var update_temp = func {
    if(getprop("/engines/engine/running") != 0){
        interpolate("/instrumentation/engine/cht-degf", oil_temp_eng.getValue()+50, 10);
        interpolate("/instrumentation/engine/oil-temp", oil_temp_eng.getValue(), 30);
    } else {
        interpolate("/instrumentation/engine/cht-degf", oatf.getValue(), 100);
        interpolate("/instrumentation/engine/oil-temp", oatf.getValue(), 600);
    }
    settimer(update_temp,0.1);
}

setlistener("/sim/signals/fdm-initialized", initialise_temp);
