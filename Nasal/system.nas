# This file is part of FlightGear, the free flight simulator
# http://www.flightgear.org/
#
# Copyright (C) 2010 Dave Perry, skidavem (at) mindspring _dot_ com#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# Based on Pa24 nas file

var value = 0;
var test = 0;
var toggle = 0;
var baggageLoaded = props.globals.getNode("sim/model/baggage/loaded",0);
# baggageLoaded.setBoolValue(0);
var baggageWt_lb = props.globals.getNode("sim/weight[4]/weight-lb",0);
# baggageWt_lb.setValue(0);
var leftVisorDown = props.globals.getNode("sim/model/visor-positions/leftVisorDown",0);
# leftVisorDown.setBoolValue(0);
var rightVisorDown = props.globals.getNode("sim/model/visor-positions/rightVisorDown",0);
# rightVisorDown.setBoolValue(0);
var click = props.globals.getNode("controls/switches/click",0);
# click.setBoolValue(0);
var prime = props.globals.getNode("sim/sound/prime",0);
# prime.setBoolValue(0);

var fuel_switch = func(rotDir) {
  node = props.globals.getNode("consumables/fuel/tank[0]/selected",0);
  #node.setBoolValue(0);
  node = props.globals.getNode("consumables/fuel/tank[1]/selected",0);
  #node.setBoolValue(0);
  node = props.globals.getNode("consumables/fuel/tank[2]/selected",0);
  #node.setBoolValue(0);
  node = props.globals.getNode("consumables/fuel/tank[3]/selected",0);
  #node.setBoolValue(0);

  val = getprop("controls[1]/fuel/switch-position");
  test = rotDir + val;
  if(test > 4){test=0};
  if(test < 0){test=4};
  setprop("controls[1]/fuel/switch-position",test);
  if(test == 1){
    node = props.globals.getNode("consumables/fuel/tank[0]/selected",0);
    node.setBoolValue(1);
    if(getprop("consumables/fuel/tank[0]/level-gal_us")>0.01){
      node = props.globals.getNode("engines/engine/out-of-fuel",1);
      node.setBoolValue(0);
    } 
  }
  if(test == 2){
    node = props.globals.getNode("consumables/fuel/tank[1]/selected",0);
    node.setBoolValue(1);
    if(getprop("consumables/fuel/tank[1]/level-gal_us")>0.01){
      node = props.globals.getNode("engines/engine/out-of-fuel",1);
      node.setBoolValue(0);
    } 
  }
  if(test == 3){
    node = props.globals.getNode("consumables/fuel/tank[2]/selected",0);
    node.setBoolValue(1);
    if(getprop("consumables/fuel/tank[2]/level-gal_us")>0.01){
      node = props.globals.getNode("engines/engine/out-of-fuel",1);
      node.setBoolValue(0);
    } 
  }
  if(test == 4){
    node = props.globals.getNode("consumables/fuel/tank[3]/selected",0);
    node.setBoolValue(1);
    if(getprop("consumables/fuel/tank[3]/level-gal_us")>0.01){
      node = props.globals.getNode("engines/engine/out-of-fuel",1);
      node.setBoolValue(0);
    } 
  }
}

setprop("controls[1]/fuel/switch-position", -1);
fuel_switch(1);

var baggageToggle = func {
  toggle=baggageLoaded.getValue();
  toggle=1-toggle;
  baggageLoaded.setBoolValue(toggle);
  if (toggle) {
     baggageWt_lb.setValue(122);
  } else {
     baggageWt_lb.setValue(0);
  }
}

var LeftVisorDown = func {
  toggle=leftVisorDown.getValue();
  toggle=1-toggle;
  leftVisorDown.setBoolValue(toggle);
}

var RightVisorDown = func {
  toggle=rightVisorDown.getValue();
  toggle=1-toggle;
  rightVisorDown.setBoolValue(toggle);
}

var master_switch = func {
  toggle=getprop("controls/electric/battery-switch");
  toggle=1-toggle;
  setprop("controls/electric/battery-switch",toggle);
  click.setBoolValue(1);
}

var f_pump_switch = func {
  toggle=getprop("controls/engines/engine/fuel-pump");
  toggle=1-toggle;
  setprop("controls/engines/engine/fuel-pump",toggle);
  click.setBoolValue(1);
}

var panel_light_switch = func(c) {
  var factor = getprop("controls/switches/panel-lights-factor");
  if ( (c > 0) and ( factor > 1 )) { factor = 1; return; } 
  if ( (c < 0) and ( factor < 0 )) { factor = 0; return; }
  factor = c*0.01 + factor;
  setprop("controls/switches/panel-lights-factor",factor);
  if (factor > 0.0001 ) { toggle = 1; }
  else { toggle = 0; }
  var lastToggle = getprop("controls/switches/nav-lights");
  if ( toggle != lastToggle ) {
     setprop("controls/switches/nav-lights",toggle);
     click.setBoolValue(1);
  }
}

var landing_light_switch_left = func {
  toggle=getprop("controls/switches/landing-light-L");
  toggle=1-toggle;
  setprop("controls/switches/landing-light-L",toggle);
  click.setBoolValue(1);
}

var landing_light_switch_right = func {
  toggle=getprop("controls/switches/landing-light-R");
  toggle=1-toggle;
  setprop("controls/switches/landing-light-R",toggle);
  click.setBoolValue(1);
}

var landing_light_switch_both = func {
#    SLAVE the Right switch to the Left switch
  toggle=getprop("controls/switches/landing-light-L");
  toggle=1-toggle;
  setprop("controls/switches/landing-light-L",toggle);
  setprop("controls/switches/landing-light-R",toggle);
  click.setBoolValue(1);
}

var turn_bank_switch = func {
  toggle = getprop("controls/switches/turn-indicator");
  toggle=1-toggle;
  setprop("controls/switches/turn-indicator",toggle);
  click.setBoolValue(1);
}

var rot_beacon_switch = func {
  toggle=getprop("controls/switches/flashing-beacon");
  toggle=1-toggle;
  setprop("controls/switches/flashing-beacon",toggle);
  click.setBoolValue(1);
}

var pitot_heat_switch = func {
  toggle=getprop("controls/anti-ice/pitot-heat");
  toggle=1-toggle;
  setprop("controls/anti-ice/pitot-heat",toggle);
  click.setBoolValue(1);
}

var strobe_light_switch = func {
  toggle=getprop("controls/switches/strobe-lights");
  toggle=1-toggle;
  setprop("controls/switches/strobe-lights",toggle);
  click.setBoolValue(1);
}

var avionics_master_switch = func {
  toggle=getprop("controls/switches/master-avionics");
  toggle=1-toggle;
  setprop("controls/switches/master-avionics",toggle);
  click.setBoolValue(1);
}

var carb_heat = func {
  toggle=getprop("controls/anti-ice/engine/carb-heat");
  toggle=1-toggle;
  setprop("controls/anti-ice/engine/carb-heat",toggle);
}

var primer = func {
  toggle=getprop("controls/engines/engine/primer-pump");
  toggle=1-toggle;
  setprop("controls/engines/engine/primer-pump",toggle);
  prime.setBoolValue(1);
}

var map_light_switch = func {
  toggle=getprop("controls/switches/map-lights");
  toggle=1-toggle;
  setprop("controls/switches/map-lights",toggle);
}

var cabin_light_switch = func {
  toggle=getprop("controls/switches/cabin-lights");
  toggle=1-toggle;
  setprop("controls/switches/cabin-lights",toggle);
}

var oat_switch = func {
  val = getprop("controls/switches/oat-switch");
  test = 1 + val;
  if(test > 2){test=0};
  setprop("controls/switches/oat-switch",test);
  settimer(oat_off, 300);
}

var oat_off = func {
  setprop("controls/switches/oat-switch",0);
}

#Engine sensors class 
# ie: var Eng = Engine.new(engine number);
var Engine = {
    new : func(eng_num){
        m = { parents : [Engine]};
        m.air_temp = props.globals.initNode("environment/temperature-degc");
        m.oat = m.air_temp.getValue() or 0;
        m.ot_target=60;
        m.eng = props.globals.initNode("engines/engine["~eng_num~"]");
        m.running = 0;
        m.mp = m.eng.initNode("mp-inhg");
        m.cutoff = props.globals.initNode("controls/engines/engine["~eng_num~"]/cutoff");
        m.mixture = props.globals.initNode("engines/engine["~eng_num~"]/mixture");
        m.mixture_lever = props.globals.initNode("controls/engines/engine["~eng_num~"]/mixture",1,"DOUBLE");
        m.rpm = m.eng.initNode("rpm",1);
        m.oil_temp=m.eng.initNode("oil-temp-c",m.oat,"DOUBLE");
        m.carb_temp=m.eng.initNode("carb-temp-c",m.oat,"DOUBLE");
        m.oil_psi=m.eng.initNode("oil-pressure-psi",0.0,"DOUBLE");
        m.smoke=m.eng.initNode("smoke",0,"BOOL");
        m.firing=m.eng.initNode("firing",0.0,"DOUBLE");
        m.fuel_psi=m.eng.initNode("fuel-psi-norm",0,"DOUBLE");
        m.fuel_out=m.eng.initNode("out-of-fuel",0,"BOOL");
        m.fuel_switch=props.globals.initNode("controls/fuel/switch-position",1,"INT");
        m.hpump=props.globals.initNode("systems/hydraulics/pump-psi["~eng_num~"]",0,"DOUBLE");

        m.smk0=0.0;
        m.smk1=0.0;

        m.Lrunning = setlistener("engines/engine["~eng_num~"]/running",func (rn){m.running=rn.getValue();},1,0);
    return m;
    },
    #### update ####
    update : func{
    var mx =me.mixture_lever.getValue();
    me.mixture.setValue(mx);
    var hpsi =me.rpm.getValue();
    var fpsi =me.fuel_psi.getValue();
    var oilpsi=hpsi * 0.001;
    if(oilpsi>0.7)oilpsi =0.7;
        me.oil_psi.setValue(oilpsi);
    if(hpsi>60)hpsi = 60;
        me.hpump.setValue(hpsi);
    var rpm = me.rpm.getValue();
    var mp=me.mp.getValue();
    var OT= me.oil_temp.getValue();
    var cooling=(getprop("velocities/airspeed-kt") * 0.1) *2;
    cooling+=(mx * 5);
    var tgt=me.ot_target + mp;
    var tgt-=cooling;
    if(me.running){
        if(OT < tgt) OT+=rpm * 0.00001;
        if(OT > tgt) OT-=cooling * 0.001;
        }else{
        if(OT > me.air_temp.getValue()) OT-=0.001; 
    }
        me.oil_temp.setValue(OT);
        var fpVolts =getprop("systems/electrical/outputs/fuel-pump");
    if(fpVolts==nil)fpVolts=0;
    var ctemp=me.air_temp.getValue();
    ctemp -= (rpm * 0.007);
    me.carb_temp.setValue(ctemp);
        if(fpVolts>5){
            if(fpsi<0.5000)fpsi += 0.01;
        }else{
            if(fpsi>0.000) fpsi -= 0.01;
        }
        me.fuel_psi.setValue(fpsi);
        if(fpsi < 0.2){
            me.mixture.setValue(fpsi);
        }
        var idlesnd=(rpm-500)*0.001;
        if(idlesnd>1)idlesnd=1;
        idlesnd=1-idlesnd;
        idle_volume.setValue(idlesnd);

    me.smk1=me.firing.getValue();
    if((me.smk1 - me.smk0)>0.000000)me.smoke.setValue(1) else me.smoke.setValue(0);
    me.smk0=me.smk1;
    },

    fuel_select : func (sw){
        var position=me.fuel_switch.getValue();
        position +=sw;
        if(position > 2)position -=4;
        if(position < -1)position +=4;
        me.fuel_switch.setValue(position);
        setprop("/consumables/fuel/tank[0]/selected",0);
        setprop("/consumables/fuel/tank[1]/selected",0);
        setprop("/consumables/fuel/tank[2]/selected",0);
        if(position >= 0){
            setprop("/consumables/fuel/tank[" ~ position ~ "]/selected",1);
        };
        me.fuel_out.setValue(0);
    },

};
##################################
var WaspJr = Engine.new(0);

##
#  Substitute controls.flapsDown taken from b29.nas.  Gives smooth flap motion
#  as long as the flap switch is closed.
##

controls.flapsDown = func(switchPosition) {
    setprop("controls/switches/flaps", switchPosition);
#    print("switchPosition = ", switchPosition);
    if(getprop("systems/electrical/outputs/flaps") < 8.0) { return; }
    if (switchPosition == 1) {
        if ( getprop('/controls/flight/flaps') < 1 ) {
            interpolate('/controls/flight/flaps', 1, (5*(1-getprop('/controls/flight/flaps'))));
        # } else {
            # check for motor burnout
        }
    } elsif (switchPosition == -1) {
        if ( getprop('/controls/flight/flaps') > 0 ) {
            interpolate('/controls/flight/flaps', 0, (5*getprop('/controls/flight/flaps')));
        # } else {
            # check for motor burnout
        }
    } else {
        interpolate('/controls/flight/flaps');
    }
}
