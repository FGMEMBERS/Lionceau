####  piston engine electrical system    #### 
####    Syd Adams    ####

var ammeter_ave = 0.0;
var outPut = "systems/electrical/outputs/";
var BattVolts = props.globals.getNode("systems/electrical/batt-volts",1);
var Volts = props.globals.getNode("/systems/electrical/volts",1);
var Amps = props.globals.getNode("/systems/electrical/amps",1);
var switch_list = [];
var breaker_list = [];
var output_list = [];
var serv_list = [];
var breakers_listeners = [];
var load = 0;

#var battery = Battery.new(switch-prop,volts,amps,amp_hours,charge_percent,charge_amps);
Battery = {
    new : func(swtch,vlt,amp,hr,chp,cha){
	m = { parents : [Battery] };
        m.switch = props.globals.getNode(swtch,1);
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        m.amp_hours = hr;
        m.charge_percent = chp; 
        m.charge_amps = cha;
	return m;
    },
    apply_load : func(load,dt) {
        if (! me.switch.getValue()) {
	    var amphrs_used = load * dt / 3600.0;
	    var percent_used = amphrs_used / me.amp_hours;
	    me.charge_percent -= percent_used;
	    if ( me.charge_percent < 0.0 )
		me.charge_percent = 0.0;
	    elsif ( me.charge_percent > 1.0 ) {
		me.charge_percent = 1.0;
		var output =me.amp_hours * me.charge_percent;
		return output;
	    }
	    else 
		return 0;
	}
    },

    get_output_volts : func {
        if(! me.switch.getValue()){
            var x = 1.0 - me.charge_percent;
            var tmp = -(3.0 * x - 1.0);
            var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
            var output =me.ideal_volts * factor;
            return output;
        }
	else 
	    return 0;
    },

    get_output_amps : func {
        if (! me.switch.getValue()) {
            var x = 1.0 - me.charge_percent;
            var tmp = -(3.0 * x - 1.0);
            var factor = (tmp*tmp*tmp*tmp*tmp + 32) / 32;
            var output =me.ideal_amps * factor;
            return output;
        }
	else 
	    return 0;
    }
};

# var alternator = Alternator.new(num,switch,rpm_source,rpm_threshold,volts,amps);
Alternator = {
    new : func (num,switch,src,thr,vlt,amp){
        m = { parents : [Alternator] };
        m.switch =  props.globals.getNode(switch,1);
        m.meter =  props.globals.getNode("systems/electrical/gen-load["~num~"]",1);
        m.meter.setDoubleValue(0);
        m.gen_output =  props.globals.getNode("engines/engine["~num~"]/amp-v",1);
        m.gen_output.setDoubleValue(0);
        m.meter.setDoubleValue(0);
        m.rpm_source =  props.globals.getNode(src,1);
        m.rpm_threshold = thr;
        m.ideal_volts = vlt;
        m.ideal_amps = amp;
        return m;
    },

    apply_load : func(load) {
	me.switch.getValue() or return;
        var cur_volt=me.gen_output.getValue();
        var cur_amp=me.meter.getValue();
        if (cur_volt >1) {
            var factor=1/cur_volt;
            gout = (load * factor);
            if(gout>1)gout=1;
        }
	else
            gout=0;
        if(cur_amp > gout)me.meter.setValue(cur_amp - 0.01);
        if(cur_amp < gout)me.meter.setValue(cur_amp + 0.01);
    },

    get_output_volts : func {
	me.switch.getValue() or return;
        var out = 0;
        if(me.switch.getBoolValue()){
            var factor = me.rpm_source.getValue() / me.rpm_threshold;
            if ( factor > 1.0 ) factor = 1.0;
            var out = (me.ideal_volts * factor);
        }
        me.gen_output.setValue(out);
        return out;
    },

    get_output_amps : func {
	me.switch.getValue() or return;
        var ampout =0;
        var factor = me.rpm_source.getValue() / me.rpm_threshold;
        if ( factor > 1.0 ) factor = 1.0;
        ampout = me.ideal_amps * factor;
        return ampout;
    }
};

var battery = Battery.new("/controls/switches/generator",24,30,34,1.0,7.0);
var alternator = Alternator.new(0,"/controls/switches/generator","/engines/engine[0]/rpm",100.0,28.0,60.0);

#####################################
setlistener("/sim/signals/fdm-initialized", func {
    BattVolts.setDoubleValue(0);
    init_switches();
    print("Electrical System ... ok");

});

init_switches = func() {
    breaker_list = [];
    append(breaker_list,"master");     #0
    append(breaker_list,"avionic-bus");#1
    append(breaker_list,"instruments");#2
    append(breaker_list,"flaps");      #3
    append(breaker_list,"starter");    #4
    append(breaker_list,"fuel-pump");  #5
    foreach (var breaker; breaker_list) {
	breaker = "/controls/circuit-breakers/" ~ breaker;
	props.globals.getNode(breaker,1).setBoolValue(1);
	append(breakers_listeners, setlistener(breaker, master_switch, 0, 0));
    }

    switch_list = [];
    append(switch_list,"generator");  #0
    append(switch_list,"master");     #1
    append(switch_list,"radio");      #2
    append(switch_list,"instruments");#3
    append(switch_list,"nav-lights"); #4
    append(switch_list,"fuel-pump");  #5
    foreach (var switch; switch_list)
	props.globals.getNode("/controls/switches/" ~ switch,1).setBoolValue(0);

    serv_list = [];
    append(serv_list,"heading-indicator");       #0
    append(serv_list,"turn-indicator");          #1
    append(serv_list,"attitude-indicator");      #2
    append(serv_list,"vertical-speed-indicator");#3
    append(serv_list,"gps");                     #4
    append(serv_list,"comm");                    #5
    append(serv_list,"nav");                     #6
    foreach (var serv; serv_list)
	props.globals.getNode("/instrumentation/" ~ serv ~ "/serviceable",1).setBoolValue(0);
    
    props.globals.getNode("/consumables/fuel/tank/selected",1).setBoolValue(0);
    load = 0;
}

var radio_switch = func () {
    var state = getprop("/controls/switches/radio") *
	        getprop("/controls/switches/master") *
		getprop("/controls/circuit-breakers/avionic-bus") *
		getprop("/controls/circuit-breakers/master");
    for (var i = 4; i <= 6; i += 1)
	setprop("/instrumentation/" ~ serv_list[i] ~ "/serviceable", state);
}

var instruments_switch = func () {
    var state = getprop("/controls/switches/instruments") *
		getprop("/controls/switches/master") *
		getprop("/controls/circuit-breakers/instruments") *
		getprop("/controls/circuit-breakers/master");
    for (var i = 0; i <= 3; i += 1)
	setprop("/instrumentation/" ~ serv_list[i] ~ "/serviceable", state);
}

var master_switch = func () {
    radio_switch();
    instruments_switch();
    pump_switch();
}

var pump_switch = func {
    var state = getprop("/controls/switches/fuel-pump") *
		getprop("/controls/switches/master") *
		getprop("/controls/circuit-breakers/master") *
		getprop("/controls/circuit-breakers/fuel-pump") *
		(getprop("/consumables/fuel/tank/level-gal_us") > 0.5) ? 1 : 0;
    setprop("/consumables/fuel/tank/selected", state);
    setprop("/engines/engine/out-of-fuel", (state) ? 0 : 1);
}

var flaps_load = func {
    #electric load depends of airspeed and flaps position
}
