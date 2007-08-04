# Only move flaps if voltage is sufficient
controls.flapsDown = func(down){

	volts = getprop("systems/electrical/outputs/flaps");
	if (down > 0 and volts > 8){setprop("controls/flight/flaps",1);}
	elsif (down < 0 and volts > 8){setprop("controls/flight/flaps",0);}

}
