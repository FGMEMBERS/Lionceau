# Only move flaps if voltage is sufficient

var flapsDown = controls.flapsDown;
controls.flapsDown = func(v){
  var volts = getprop("systems/electrical/outputs/flaps");
  #print("Flap Volts: ",volts);
        flapsDown(volts > 16 ? v : 0);
}

controls.adjMixture = func {
    var running = getprop("engines/engine[0]/running");
    var onground = getprop("gears/gear[0]/wow");
    if (onground and !running) {
        adjEngControl("mixture", arg[0]);
        var mixturelevel = getprop("/controls/engines/engine[0]/mixture");
        print ("Mixture level (0~1): ",mixturelevel);
    }
    else print ("mixture can't be adjusted for now");
}
