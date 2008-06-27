var mode = 0;
var displayed_screen = 0; #screenModeAndSettings
var page = 0;
var isOn = 0;
var freq = 1;
var screen = [];
var line = [];
var routes = [];
var alt_unit_full_name = ["Feet", "Meters"];
var dist_unit_full_name = ["Nautic Miles", "Kilometers"];
var spd_unit_full_name = ["Knots", "KM/H"];
var alt_unit_short_name = ["ft", "m"];
var dist_unit_short_name = ["nm", "km"];
var spd_unit_short_name = ["kt", "km/h"];
var spd_unit = 0;
var dist_unit = 0;
var alt_unit = 0;
var apt = nil;
var startpos = nil;
var waypointindex = 0;
var thresold_alert = [120, 60, 30, 15];
var thresold_alert_index = 1;
var thresold_next_waypoint = 5;
NOT_YET_IMPLEMENTED = [
    "",
    "    NOT",
    "    YET",
    "IMPLEMENTED",
    ""
];
var page = 0;
var page_list = [
    [0,0,0,0,0,0],      # ModeAndSettings: 1 page for mode, 5 pages for settings
    [1,2,3],            # PositionMain, Odometers, WindInfos
    [5,4,1,2,3,6,7],    # AirportMain, NavigationMain, PositionMain, Odometers, WindInfos, AirportInfos, SearchAirport
    [8,4,1,2,3,9],      # TurnpointSelect, NavigationMain, PositionMain, Odometers, WindInfos, TurnpointInfos
    [10,4,1,2,3,11,12], # TaskSelect, NavigationMain, PositionMain, Odometers, WindInfos, WaypointInfos, WaypointsList
    [13]	        # Edit (special mode for editing waypoint, called from other modes)
];

             #to ft      m
var alt_conv = [[1.0000,0.3048],  #from ft
                [3.2808,1.0000]]; #from m

	      #to nm      km     m
var dist_conv = [[1.00000   ,1.852, 1852],  #from nm
                 [0.53996   ,1.000, 1000],  #from km
	         [0.00053996,0.001, 1.00]]; #from m

var gps_data = props.globals.getNode("/instrumentation/gps",1);
var gps_wp = gps_data.getNode("wp",1);

#### warps for buttons and knobs ########################################"
var right_knob = func(dir) {
    isOn == 1 or return;
    screen[displayed_screen].right(dir);
    refresh_display();
}

var enter_button = func() {
    isOn == 1 or return;
    screen[displayed_screen].enter();
    refresh_display();
}

var escape_button = func() {
    isOn == 1 or return;
    screen[displayed_screen].escape();
    refresh_display();
}

var start_button = func() {
    isOn == 1 or return;
    screen[displayed_screen].start();
    refresh_display();
}

var left_knob = func(dir) {
    isOn == 1 or return;
    page = cycle(size(page_list[mode]), page, dir);
    if (displayed_screen != 0) displayed_screen = page_list[mode][page];
    refresh_display();
}

var select_mode = func(dir) {
    isOn == 1 or return;
    if (displayed_screen != 0) {
	displayed_screen = 0; #screenModeAndSettings
	page = 0;
	screen[displayed_screen].changemode(0);
    }
    else
	screen[displayed_screen].changemode(dir);
    refresh_display();
}

var switch_ON_OFF = func() {
    if (isOn) {
	isOn = 0;
	for (var i = 0; i < 5; i += 1) line[i].setValue("");
    }
    else {
	isOn = 1;
	screenTaskSelect.n = list_routes();
	screenTurnpointSelect.n = load_bookmarks();
	refresh_display();
    }
    props.globals.getNode("/instrumentation/gps/serviceable",1).setBoolValue(isOn);
}

### useful funcs #########################################################
var display = func () {
    for (var i = 0; i < 5; i += 1) line[i].setValue(arg[0][i]);
}

var browse = func (entries_nbr, index_pointer, index_page,dir) {
    nl = entries_nbr - (index_page * 5) > 5 ? 5 : math.mod(entries_nbr - (index_page * 5), 5);
    if (index_pointer + 1 == nl) {
       np = int(entries_nbr / 5) + (math.mod(entries_nbr,5) ? 1 : 0);
       index_page = cycle(np, index_page, dir);
    }
    index_pointer = cycle(nl, index_pointer, dir);
    return [index_pointer, index_page];
}

var cycle = func (entries_nbr, actual_entrie, dir) {   
    entries_nbr -= 1;
    if (dir == 1 and actual_entrie == entries_nbr) return 0;
    elsif (dir == -1 and actual_entrie == 0) return entries_nbr;
    else return actual_entrie + dir;
}

var refresh_display = func() {
    screen[displayed_screen].lines();
    if (isOn and 0 < displayed_screen < 5 ) settimer(func { refresh_display() }, freq, 1);
}

var seconds_to_string = func (time) {
    var hh = int(time / 3600);
    if (hh > 100) return "--:--:--";
    var mm = int((time - (hh * 3600)) / 60);
    var ss = int(time - (hh * 3600 + mm * 60));
    return sprintf("%02d:%02d:%02d", hh, mm, ss);
}

### route management ######################################################
var list_routes = func {
    routes = [];
    var path = getprop("/sim/fg-home") ~ "/Routes";
    var s = io.stat(path);
    if (s != nil and io.isdir(s[2])) {
	foreach (var file; directory(path)) 
	    if (file[0] != 46) append(routes, file);
#	size(routes) != 0 or return;
#	routes = sort(routes, func(a,b) {
#	    num(a[1]) == nil or num(b[1]) == nil ? cmp(a[1], b[1]) : a[1] - b[1];
#	});
#	print(size(routes));
#	foreach (var r; routes) print (r ~ ":" ~ r[0]);
    }
    return size(routes);
}

var waypointAlert = func {
    mode > 0 or return; 
    var ttw = gps_wp.getNode("wp[1]/TTW",1).getValue();
    var ttw_secs = num(substr(ttw,0,2))*3600 + num(substr(ttw,3,2))*60 + num(substr(ttw,6,2));
    
    if (ttw_secs < thresold_alert[thresold_alert_index])
        gps_data.getNode("waypoint-alert",1).setBoolValue(1);
    else
        gps_data.getNode("waypoint-alert",1).setBoolValue(0);
    
    if (mode == 3 and ttw_secs < thresold_next_waypoint)
        screenNavigationMain.nextWaypoint();	
}

### turnpoints management ######################################################
var load_bookmarks = func {
    var n = 0;
    gps_data.getNode("bookmarks",1).removeChildren("bookmark");
    var file = getprop("/sim/fg-home") ~ "/bookmarks.xml";
    var s = io.stat(file);
    if (s != nil) {
	fgcommand("loadxml", props.Node.new({
	    "filename": file,
	    "targetnode": "/instrumentation/gps/bookmarks"
	}));
	foreach (var c ;props.globals.getNode("/instrumentation/gps/bookmarks").getChildren("bookmark")) n += 1;
    }
    return n;
}

var save_bookmarks = func {
    var path = getprop("/sim/fg-home") ~ "/bookmarks.xml";
    var args = props.Node.new({ filename : path });
    var export = args.getNode("/instrumentation/gps/bookmarks", 1);
    foreach (var c; props.globals.getNode("/instrumentation/gps/bookmarks").getChildren("bookmarks")) {
	var b = export.getChild("bookmark",1);
	b.getNode("ID", 1).setValue(c.getNode("ID").getValue());
	b.getNode("latitude-deg", 1).setValue(c.getNode("latitude-deg").getValue());
	b.getNode("longitude-deg", 1).setValue(c.getNode("longitude-deg").getValue());
	b.getNode("altitude-ft", 1).setValue(c.getNode("altitude-ft").getValue());
	#b.getNode("infos", 1).setValue(c.getNode("infos").getValue());
    }
    fgcommand("savexml", args);
}

### initialisation stuff ###################################################
var init = func() {
    for (var i = 0; i < 5; i += 1) {
	append(line, props.globals.getNode("/instrumentation/lx500/line[" ~ i ~ "]", 1));
	line[i].setValue("");
    }
    props.globals.getNode("/instrumentation/gps/serviceable",1).setBoolValue(0);
    append(screen, lx500.screenModeAndSettings); #0
    append(screen, lx500.screenPositionMain);    #1
    append(screen, lx500.screenOdometers);	 #2
    append(screen, lx500.screenWindInfos);	 #3
    append(screen, lx500.screenNavigationMain);  #4
    append(screen, lx500.screenAirportMain);     #5
    append(screen, lx500.screenAirportInfos);    #6
    append(screen, lx500.screenSearchAirport);   #7
    append(screen, lx500.screenTurnpointSelect); #8
    append(screen, lx500.screenTurnpointInfos);  #9
    append(screen, lx500.screenTaskSelect);      #10
    append(screen, lx500.screenWaypointInfos);   #11
    append(screen, lx500.screenWaypointsList);   #12
    append(screen, lx500.screenEdit);		 #13
    aircraft.light.new("/sim/model/gps/redled", [0.1, 0.1, 0.1, 0.7], "/instrumentation/gps/waypoint-alert");
    aircraft.light.new("/sim/model/gps/greenled", [0.6, 0.3], "/instrumentation/gps/message-alert");
    startpos = geo.Coord.new(geo.aircraft_position());
    screenPositionMain.begin_time = props.globals.getNode("/sim/time/elapsed-sec",1).getValue();
    setlistener("/instrumentation/gps/wp/wp[1]/TTW", waypointAlert, 0, 0);
    print("GPS... initialized");
}

setlistener("/sim/signals/fdm-initialized",init);
