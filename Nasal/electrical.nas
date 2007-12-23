##
# Issoire-Aviation Lionceau electrical system (based on DHC2 electrical system)
# shamelessly copied from Grob-G115 and modified ;-)
##

# Initialize internal values
#

var battery = nil;
var alternator = nil;

var last_time = 0.0;

var vbus_volts = 0.0;
var main_bus_volts = 0.0;
var ammeter_ave = 0.0;

##
# Initialize the electrical system
#

init_electrical = func {
    battery = BatteryClass.new();
    alternator = AlternatorClass.new();

###
### Initialise electrical stuff ###
### (move to electric system init once electrical system exists complete) ###
###
    props.globals.getNode("/systems/electrical/volts", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/amps", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/alternator", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/outputs/start-ctrl", 1).setDoubleValue(0.0);
    props.globals.getNode("/systems/electrical/outputs/lo-volt-warning", 1).setDoubleValue(0.0);

    props.globals.getNode("instrumentation/warning-panel/lovolt-norm", 1).setDoubleValue(0.0);
    props.globals.getNode("instrumentation/warning-panel/fuel-norm", 1).setDoubleValue(0.0);

    props.globals.getNode("controls/circuit-breakers/starter", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/master", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/load", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/instruments", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/flaps", 1).setBoolValue(1);
    props.globals.getNode("controls/circuit-breakers/pump", 1).setBoolValue(1);

    props.globals.getNode("/controls/switches/master", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/lights", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/gyro", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/pump", 1).setBoolValue(0);
    props.globals.getNode("/controls/switches/radios", 1).setBoolValue(0);

    props.globals.getNode("/controls/electric/engine/generator", 1).setBoolValue(0);
    props.globals.getNode("/controls/electric/battery-switch", 1).setBoolValue(0);

    print("Nasal Electrical System : initialised");
    props.globals.getNode("/sim/signals/electrical-initialized", 1).setBoolValue(0);

    # Request that the update fuction be called next frame
    settimer(update_electrical, 0);
}

BatteryClass = {};

BatteryClass.new = func {
    obj = { parents : [BatteryClass],
            ideal_volts : 12.0,
            ideal_amps : 25.0,
            amp_hours : 24,
            charge_percent : 1.0,
            charge_amps : 7.0 };
    return obj;
}


BatteryClass.apply_load = func( amps, dt ) {
    amphrs_used = amps * dt / 3600.0;
    percent_used = amphrs_used / me.amp_hours;
    me.charge_percent -= percent_used;
    if ( me.charge_percent < 0.0 ) {
        me.charge_percent = 0.0;
    } elsif ( me.charge_percent > 1.0 ) {
        me.charge_percent = 1.0;
    }
    # print( "battery percent = ", me.charge_percent);
    return me.amp_hours * me.charge_percent;
}


BatteryClass.get_output_volts = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_volts * factor;
}


BatteryClass.get_output_amps = func {
    x = 1.0 - me.charge_percent;
    tmp = -(3.0 * x - 1.0);
    factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
    return me.ideal_amps * factor;
}


AlternatorClass = {};

AlternatorClass.new = func {
    obj = { parents : [AlternatorClass],
            rpm_source : "/engines/engine[0]/rpm",
            rpm_threshold : 600.0,
            ideal_volts : 12.0,
            ideal_amps : 30.0 };
    setprop( obj.rpm_source, 0.0 );
    return obj;
}


AlternatorClass.apply_load = func( amps, dt ) {
    # Scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", me.ideal_amps * factor );
    available_amps = me.ideal_amps * factor;
    return available_amps - amps;
}


AlternatorClass.get_output_volts = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator volts = ", me.ideal_volts * factor );
    return me.ideal_volts * factor;
}


AlternatorClass.get_output_amps = func {
    # scale alternator output for rpms < 600.  For rpms >= 600
    # give full output.  This is just a WAG, and probably not how
    # it really works but I'm keeping things "simple" to start.
    rpm = getprop( me.rpm_source );
    factor = rpm / me.rpm_threshold;
    if ( factor > 1.0 ) {
        factor = 1.0;
    }
    # print( "alternator amps = ", ideal_amps * factor );
    return me.ideal_amps * factor;
}


update_electrical = func {
    time = getprop("/sim/time/elapsed-sec");
    dt = time - last_time;
    last_time = time;

    update_virtual_bus( dt );
    # Request that the update fuction be called again next frame
    settimer(update_electrical, 0);
}


update_virtual_bus = func( dt ) {
    battery_volts = battery.get_output_volts();
    alternator_volts = alternator.get_output_volts();
    external_volts = 0.0;
    load = 0.0;

    # switch state
    master_alt = getprop("/controls/switches/generator");

    # determine power source
    bus_volts = 0.0;
    power_source = "none";
    if ( getprop("/controls/electric/battery-switch") ) {
        bus_volts = battery_volts;
        power_source = "battery";
    }
    if ( getprop("/controls/switches/generator") and
         getprop("/controls/circuit-breakers/gen") and
         (alternator_volts > bus_volts) ) {
        bus_volts = alternator_volts;
        power_source = "alternator";
    }
    if ( external_volts > bus_volts ) {
        bus_volts = external_volts;
        power_source = "external";
    }
    # print( "virtual bus volts = ", bus_volts );

    # starter
    if (getprop("/systems/electrical/outputs/start-ctrl") > 16 ) {
        setprop("/systems/electrical/outputs/starter[0]", bus_volts);
        if (getprop("/controls/switches/starter")==1) {
            load += 10.0;
        }
    } else {
        setprop("/systems/electrical/outputs/starter[0]", 0.0);
    }

    # flaps
    if ( getprop("/controls/circuit-breakers/flaps") ) {
        setprop("/systems/electrical/outputs/flaps", bus_volts);
    } else {
        setprop("/systems/electrical/outputs/flaps", 0.0);
    }

    # bus network (1. these must be called in the right order, 2. the
    # bus routine itself determins where it draws power from.)
    load = main_bus();

    # system loads and ammeter gauge
    ammeter = 0.0;
    if ( bus_volts > 1.0 ) {

        # ammeter gauge
        if ( power_source == "battery" ) {
            ammeter = -load;
        } else {
            ammeter = battery.charge_amps;
        }
    }
    # print( "ammeter = ", ammeter );

    # charge/discharge the battery
    if ( power_source == "battery" ) {
        battery.apply_load( load, dt );
    } elsif ( bus_volts > battery_volts ) {
        battery.apply_load( -battery.charge_amps, dt );
    }

    # filter ammeter needle pos
    ammeter_ave = 0.8 * ammeter_ave + 0.2 * ammeter;

    # outputs
    setprop("/systems/electrical/amps", ammeter_ave);
    setprop("/systems/electrical/volts", bus_volts);
    setprop("/systems/electrical/alternator", alternator_volts);
    vbus_volts = bus_volts;

    return load;
}

main_bus = func() {

    # fed from the "virtual" bus via the main bus breaker (25A)
    if ( getprop("/controls/circuit-breakers/main-bus") ) {
        main_bus_volts = vbus_volts;
    } else {
        main_bus_volts = 0.0;
        return 0.0;
    }

    load = 0.0;

    # Start Ctrl (7.5A)
    if ( getprop("/controls/circuit-breakers/starter") ) {
        setprop("/systems/electrical/outputs/start-ctrl", main_bus_volts);
        load += 0.5;
    } else {
        setprop("/systems/electrical/outputs/start-ctrl", 0.0);
    }

    # Gen Ctrl (3A)
    if ( getprop("/controls/circuit-breakers/gen-ctrl") ) {
        setprop("/systems/electrical/outputs/gen-ctrl", main_bus_volts);
        load += 0.25;
    } else {
        setprop("/systems/electrical/outputs/gen-ctrl", 0.0);
    }

    # Fuel Pump (5A)
    if ( getprop("/controls/circuit-breakers/pump") and
         getprop("/controls/engines/engine/fuel-pump") ) {
        setprop("/systems/electrical/outputs/fuel-pump", main_bus_volts);
        load += 3;
    } else {
        setprop("/systems/electrical/outputs/fuel-pump", 0.0);
    }

    # lights
    if ( getprop("/controls/circuit-breakers/lights") ) {
        setprop("/systems/electrical/outputs/lights", main_bus_volts);
        load += 0.12;
    } else {
        setprop("/systems/electrical/outputs/lights", 0.0);
    }

    if ( getprop("/controls/circuit-breakers/flaps") ) {
        setprop("/systems/electrical/outputs/flaps", main_bus_volts);
        load += 0.12;
    } else {
        setprop("/systems/electrical/outputs/flaps", 0.0);
    }

    if ( getprop("/controls/circuit-breakers/instruments") ) {
        setprop("/systems/electrical/outputs/instruments", main_bus_volts);
        load += 0.12;
    } else {
        setprop("/systems/electrical/outputs/instruments", 0.0);
    }

    # pop breaker if over current
    if ( load>25.0 ) {
        setprop("/controls/circuit-breakers/main-bus",0);
    }

    # return cumulative load
    if ( getprop("/controls/circuit-breakers/main-bus") ) {
        setprop("/systems/electrical/debug/main-load", load);
        setprop("/systems/electrical/debug/main-volts", main_bus_volts);
        return load;
    } else {
        return 0.0;
    }
}

# Setup a timer based call to initialized the electrical system as
# soon as possible.
setlistener("/sim/signals/fdm-initialized",init_electrical);
