# Only move flaps if voltage is sufficient

var flapsDown = controls.flapsDown;
controls.flapsDown = func(v){
	var volts = getprop("systems/electrical/outputs/flaps");
	print("Flap Volts: ",volts);
        flapsDown(volts > 16 ? v : 0);
}

