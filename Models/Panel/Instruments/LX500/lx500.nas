var mode = 0;
var displayed_screen = 6; #screenModeAndSettings
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

             #to ft      m
var alt_conv = [[1.0000,0.3048],  #from ft
                [3.2808,1.0000]]; #from m

	      #to nm      km     m
var dist_conv = [[1.00000   ,1.852, 1852],  #from nm
                 [0.53996   ,1.000, 1000],  #from km
	         [0.00053996,0.001, 1.00]]; #from m


var gps_data = props.globals.getNode("/instrumentation/gps",1);
var gps_wp = gps_data.getNode("wp",1);


### screens definitions ################################################

var screenModeAndSettings = { # screen for changing the GPS mode and settings
    help : 0,
    settings : 0,
    mode_: 0,
    quit_help : func {
	me.help = 0;
	me.lines;
    },
    nav_ud : func {
	me.settings = cycle_entries(6, me.settings, arg[0]);
    },
    nav_rl : func {
	if (me.settings == 1)
	    alt_unit = cycle_entries(2, alt_unit, arg[0]);
	elsif (me.settings == 2)
	    dist_unit = cycle_entries(2, dist_unit, arg[0]);
	elsif (me.settings == 3)
	    spd_unit = cycle_entries(2, spd_unit, arg[0]);
	elsif (me.settings == 4)
	    thresold_alert_index = cycle_entries(size(thresold_alert), thresold_alert_index, arg[0]);
	elsif (me.settings == 5)
	    thresold_next_waypoint = cycle_entries(10, thresold_next_waypoint, arg[0]);
    },
    mode : func {
	if (me.settings == 0) me.mode_ = cycle_entries(4, me.mode_, arg[0]);
    },
    enter : func {
	if (!me.help) {
	    display ([
	    "HERE THERE WILL SEAT",
	    "A SIMPLE EXPLANATION",
	    "TEXT ABOUT USE OF GPS",
	    "PRESS ANY OF THE",
	    "THREE BUTTONS"
	    ]);
	    me.help = 1;
	}
	else me.quit_help();
    },
    escape : func {
	if (me.help) me.quit_help();
    },
    start : func {
	if (me.help) me.quit_help();
	else {
	    mode = me.mode_;
	    if    (mode == 0) displayed_screen = 0; #screenPositionMain
	    elsif (mode == 1) displayed_screen = 4; #screenAirportMain
	    elsif (mode == 2) displayed_screen = 7; #screenWaypointEdit
	    else              displayed_screen = 2; #screenTaskSelect
	me.settings = 0;
	}
    },
    lines : func {
	if (me.settings == 0) {
	    if    (me.mode_ == 0) mode_str = "POSITION";
	    elsif (me.mode_ == 1) mode_str = "AIRPORT";
	    elsif (me.mode_ == 2) mode_str = "TURNPOINT";
	    else		 mode_str = "TASK";
	    l0 = "  -- GPS STATUS : --";
	    l1 = sprintf("MODE: %s", mode_str);
	}
	else {
	    if (me.settings < 4)
		l0 = "  -- SET UNITS --";
	    else
		l0 = "- SET TIME THRESOLDS -";
	    if (me.settings == 1) 
		l1 = sprintf("ALT: %s", alt_unit_full_name[alt_unit]);
	    elsif (me.settings == 2)
		l1 = sprintf("DIST: %s", dist_unit_full_name[dist_unit]);
	    elsif (me.settings == 3)
		l1 = sprintf("SPEED: %s", spd_unit_full_name[spd_unit]);
	    elsif (me.settings == 4)
		l1 = sprintf("ALERT: %d s", thresold_alert[thresold_alert_index]);
	    elsif (me.settings == 5)
		l1 = sprintf("NEXT WAYPOINT: %d s", thresold_next_waypoint);
	}
	display ([
	l0,
	l1,
	"",
	"ENTER -> HELP",
	"START -> ENTER MODE"
	]);
    }
};

var screenPositionMain = { # screens for POSITION mode
    page : 0,
    begin_time : 0,
    elapsed : 0,
    nav_rl : func {
	me.page = 0;
	if (mode == 3) displayed_screen = 1; #screenNavigationMain
    },
    nav_ud : func {
	me.page = cycle_entries(3, me.page, arg[0]);
    },
    enter : func {
    },
    escape : func {
	if (me.page == 1) {
	    startpos = geo.Coord.new(geo.aircraft_position());
	    me.begin_time = props.globals.getNode("/sim/time/elapsed-sec",1).getValue();
	    gps_data.getNode("odometer",1).setDoubleValue(0.0);
	}
    },
    start : func {
    },
    odotime : func {
	me.elapsed = props.globals.getNode("/sim/time/elapsed-sec",1).getValue() - me.begin_time;
        seconds_to_string(me.elapsed);
    },
    lines : func {
	if (me.page == 0)
	    display ([
	    sprintf("LAT: %s", 
	        props.globals.getNode("/position/latitude-string",1).getValue()),
	    sprintf("LON: %s", 
		props.globals.getNode("/position/longitude-string",1).getValue()),
	    sprintf("ALT: %d %s", 
		gps_data.getNode("indicated-altitude-ft").getValue() * alt_conv[0][alt_unit],
		alt_unit_short_name[alt_unit]),
	    sprintf("HDG: %d *", 
		gps_data.getNode("indicated-track-true-deg").getValue()),
	    sprintf("SPD: %d %s", 
		gps_data.getNode("indicated-ground-speed-kt").getValue() * dist_conv[0][spd_unit],
		spd_unit_short_name[spd_unit]
		)
	    ]);
	elsif (me.page == 1)
	    display ([
	    sprintf("ODO: %d %s", 
	        gps_data.getNode("odometer",1).getValue() * dist_conv[0][dist_unit],
		dist_unit_short_name[dist_unit]),
	    sprintf("TRIP: %d %s", 
		gps_data.getNode("trip-odometer",1).getValue() * dist_conv[0][dist_unit],
		dist_unit_short_name[dist_unit]),
	    sprintf("TIME: %s", 
		me.odotime()),
	    sprintf("AVG HDG: %03d*", 
		startpos.course_to(geo.aircraft_position())),
	    sprintf("AVG SPD: %d %s",
		gps_data.getNode("odometer",1).getValue() / me.elapsed * 3600 * dist_conv[0][spd_unit],
		spd_unit_short_name[spd_unit])
	    ]);
	elsif (me.page == 2) {
	    if (gps_data.getNode("indicated-ground-speed-kt").getValue() > 10)
		display ([
		"WIND INFOS",
	    	sprintf("SPEED: %d %s", 
		    props.globals.getNode("/environment/wind-speed-kt",1).getValue() * dist_conv[0][dist_unit],
		    spd_unit_short_name[spd_unit]),
		sprintf("FROM: %d*",
		    props.globals.getNode("/environment/wind-from-heading-deg",1).getValue()),
		"", 
		"" 
	    ]);
	    else
		display ([
		"WIND INFOS",
	    	sprintf("SPEED: --- %s", spd_unit_short_name[spd_unit]),
		"FROM: ---*",
		"", 
		"" 
	    ]);
	}
    }
};

var screenAirportMain = {
    pos: nil,
    apt_coord: nil,
    nav_rl : func {
	displayed_screen = 5; #screenAirportInfos
    },
    nav_ud : func {
	displayed_screen = 3; #screenATCInRange
    },
    apt_to_waypoint : func {
	gps_wp.getNode("wp/longitude-deg",1).setValue(me.pos.lat());
	gps_wp.getNode("wp/latitude-deg",1).setValue(me.pos.lon());
	gps_wp.getNode("wp/altitude-ft",1).setValue(me.pos.alt()*alt_conv[1][0]);
	gps_wp.getNode("wp/ID",1).setValue("STARTPOS");
	gps_wp.getNode("wp/name",1).setValue("start position");
 
	gps_wp.getNode("wp[1]/longitude-deg",1).setValue(me.apt_coord.lat());
	gps_wp.getNode("wp[1]/latitude-deg",1).setValue(me.apt_coord.lon());
	gps_wp.getNode("wp[1]/altitude-ft",1).setValue(me.apt_coord.alt()*alt_conv[1][0]);
	gps_wp.getNode("wp[1]/ID",1).setValue(apt.id);
	gps_wp.getNode("wp[1]/name",1).setValue(apt.name);
	mode = 2;
	displayed_screen = 1; #screenNavigationMain
    },
    enter : func {
	me.apt_to_waypoint();
    },
    escape : func {
    },
    start : func {
	me.apt_to_waypoint();
    },
    lines : func {
	apt = airportinfo();
	glide_slope_tunnel.complement_runways(apt);
	var rwy = glide_slope_tunnel.best_runway(apt);
	me.pos = geo.Coord.new(geo.aircraft_position());
	me.apt_coord = geo.Coord.new().set_latlon(rwy.lat, rwy.lon);
	var ac_to_apt = [me.pos.distance_to(me.apt_coord), me.pos.course_to(me.apt_coord)];
	var ete = ac_to_apt[0] / getprop("instrumentation/gps/indicated-ground-speed-kt") * 3600 * 1852;
	display([
	sprintf("NEAREST AIRPORT: %s", apt.id),
	sprintf("ELEV: %d %s", apt.elevation * alt_conv[1][alt_unit],alt_unit_short_name[alt_unit]),
	sprintf("DIST: %d %s",ac_to_apt[0] * dist_conv[2][dist_unit],dist_unit_short_name[dist_unit]),
	sprintf("BRG: %d*    RWY: %02d",ac_to_apt[1], int(rwy.heading) / 10),
	sprintf("ETE: %s",seconds_to_string(ete))
	]);
    }
};

var screenAirportInfos = {
    page : 0,
    rwylist: [],
    nav_rl : func {
	me.page = 0;
	displayed_screen = 4;# screenAirportMain
    },
    nav_ud : func {
	np = int(size(me.rwylist) / 4) + (math.mod(size(me.rwylist),4) ? 1 : 0);
	me.page = cycle_entries(np, me.page, arg[0]);
    },
    enter : func {
    },
    escape : func {
    },
    start : func {
    },
    lines : func {
	me.rwylist = [];
	foreach (var r; keys(apt.runways))
	    append(me.rwylist, [r, apt.runways[r].length, apt.runways[r].width]);
	line[0].setValue(sprintf("%s", apt.name)); #TODO check length to truncate if too long
	rwyindex = me.page * 4;
	for (var l = 1; l < 5; l += 1) {
	    rwyindex += 1;
	    if (rwyindex < size(me.rwylist))
		line[l].setValue(sprintf("R:%s L:%dm W:%dm", 
					me.rwylist[rwyindex][0],
					me.rwylist[rwyindex][1], 
					me.rwylist[rwyindex][2]));
	    else
		line[l].setValue("");
	}
    }
};

var screenATCinRange = {
    nav_rl : func {
	displayed_screen = 4;# screenAirportMain
    },
    nav_ud : func {
    },
    enter : func {
    },
    escape : func {
    },
    start : func {
    },
    lines : func {
	fgcommand("ATC-freq-search");
	display(NOT_YET_IMPLEMENTED);
    }
};

var screenNavigationMain = {
    nextWaypoint : func {
	waypointindex += 1;
	next = gps_data.getNode("route/Waypoint[" ~ waypointindex ~ "]/",1);
	if (next != nil) {
	    gps_wp.getNode("wp/longitude-deg",1).setValue(gps_wp.getNode("wp[1]/longitude-deg",1).getValue());
	    gps_wp.getNode("wp/latitude-deg",1).setValue(gps_wp.getNode("wp[1]/latitude-deg",1).getValue());
	    gps_wp.getNode("wp/altitude-ft",1).setValue(gps_wp.getNode("wp[1]/altitude-ft",1).getValue());
	    gps_wp.getNode("wp/ID",1).setValue(gps_wp.getNode("wp[1]/ID",1).getValue());
	    #gps_wp.getNode("wp/name",1).setValue(gps_wp.getNode("wp[1]/name",1).getValue());
 
	    gps_wp.getNode("wp[1]/longitude-deg",1).setValue(next.getNode("longitude-deg",1).getValue());
	    gps_wp.getNode("wp[1]/latitude-deg",1).setValue(next.getNode("latitude-deg",1).getValue());
	    gps_wp.getNode("wp[1]/altitude-ft",1).setValue(next.getNode("altitude-ft",1).getValue());
	    gps_wp.getNode("wp[1]/ID",1).setValue(next.getNode("ID",1).getValue());
	    #gps_wp.getNode("wp[1]/name",1).setValue(next.getNode("name",1).getValue());
	}
	else {
	    displayed_screen = 2; #screenTaskSelect
	    refresh_display();
	}
    },
    nav_rl : func {
	displayed_screen = 0; #screenPositionMain
    },
    nav_ud : func {
	#displayed_screen = ; #screenWPInfos
    },
    enter : func {
	if (mode == 3) me.nextWaypoint();
    },
    escape : func {
    },
    start : func {
    },
    lines : func {
	me.waypoint = gps_wp.getNode("wp[1]",1);
	crs_deviation = gps_wp.getNode("leg-course-deviation-deg").getValue();
	if (crs_deviation > 5)
	    me.graph = "[- - - - - T > > > > >]";
	elsif (crs_deviation < -5)
	    me.graph = "[< < < < < T - - - - -]";
	else {
	    me.graph = "[+ + + + + T + + + + +]";
	    cursor = int((crs_deviation * 2) + 11);
	    me.graph = substr(me.graph,0, cursor) ~ "i" ~ substr(me.graph, cursor+1, size(me.graph));
	}
	display ([
	sprintf("ID: ",
	    me.waypoint.getNode("ID").getValue() != nil ? me.waypoint.getNode("ID").getValue() : "WP NOT NAMED!"),
	sprintf("BRG: %d* DST: %d %s",
	    me.waypoint.getNode("bearing-mag-deg",1).getValue(),
	    me.waypoint.getNode("distance-nm",1).getValue() * dist_conv[0][dist_unit],
	    dist_unit_short_name[dist_unit]),
	sprintf("XCRS: %d* (%.1f %s)",
	    gps_wp.getNode("leg-course-deviation-deg").getValue(), 
	    gps_wp.getNode("leg-course-error-nm").getValue() * dist_conv[0][dist_unit],
	    dist_unit_short_name[dist_unit]),
	sprintf("TTW: %s", 
	    me.waypoint.getNode("TTW").getValue()),
	me.graph
	]);

    }
};

var screenTaskSelect = {
    page : 0,
    pointer: 0,
    n: 0,
    nav_ud : func {
	nl = size(routes) - (me.page * 5) > 5 ? 5 : math.mod(size(routes) - (me.page * 5), 5);
	me.pointer = cycle_entries(nl, me.pointer, arg[0]);
    },
    nav_rl : func {
	me.pointer = 0;
	np = int(size(routes) / 5) + (math.mod(size(routes),5) ? 1 : 0);
	me.page = cycle_entries(np, me.page, arg[0]);
    },
    load : func {
        props.globals.getNode("/instrumentation/gps/route").removeChildren("Waypoint");
	fgcommand("loadxml", props.Node.new({
            "filename": getprop("/sim/fg-home") ~ "/Routes/" ~ routes[(me.page * 5) + me.pointer],
            "targetnode": "/instrumentation/gps/route"
        }));
	gps_wp.getNode("wp/latitude-deg",1).setValue(gps_data.getNode("indicated-latitude-deg",1).getValue());
	gps_wp.getNode("wp/longitude-deg",1).setValue(gps_data.getNode("indicated-longitude-deg",1).getValue());
	gps_wp.getNode("wp/altitude-ft",1).setValue(gps_data.getNode("indicated-altitude-ft",1).getValue());
	gps_wp.getNode("wp/ID").setValue("startpos");

	gps_wp.getNode("wp[1]/latitude-deg",1).setValue(gps_data.getNode("route/Waypoint/latitude-deg",1).getValue());
	gps_wp.getNode("wp[1]/longitude-deg",1).setValue(gps_data.getNode("route/Waypoint/longitude-deg",1).getValue());
	gps_wp.getNode("wp[1]/altitude-ft",1).setValue(gps_data.getNode("route/Waypoint/altitude-ft",1).getValue());
	gps_wp.getNode("wp[1]/ID").setValue(gps_data.getNode("route/Waypoint/ID",1).getValue());

	waypointindex = 0;
	displayed_screen = 1; #screenNavigationMain
    },
    enter : func {
	if (me.n > 0) me.load();
    },
    escape : func {
    },
    start : func {
	if (me.n > 0) me.load();
    },
    lines : func {
	if (me.n == 0) {
	    display([
	    "",
	    "",
	    "NO ROUTE FOUND",
	    "",
	    ""
	    ]);
	}
	else for (var l = 0; l < 5; l += 1) {
	    if ((me.page * 5 + l) < me.n) {
		#var essai = me.page + l;
		#print("total " ~ me.n ~ " - page " ~ me.page ~ " - index " ~ essai ~ " - name: " ~ routes[me.page + l]);
		name = routes[me.page * 5 + l];
		if (substr(name, -4) == ".xml") name = substr(name, 0, size(name) - 4);
		name = string.uc(name);
		line[l].setValue(sprintf("%s %s",me.pointer == l ? ">" : " ", name));
	    }
	    else
		line[l].setValue("");
	}
    }
};

var screenWaypointEdit = {
    alphanum: ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P",
	       "Q","R","S","T","U","V","W","X","Y","Z",
	       "0","1","2","3","4","5","6","7","8","9"],
    numeric: ["0","1","2","3","4","5","6","7","8","9"],
    card: ["N","S","E","W"],
    pointer: [">", " ", " ", " "],
    pointedline: 0,
    map: [
    ["-","-","-","-","-","-","-","-","-"], #lat
    ["-","-","-","-","-","-","-","-","-"], #lon
    ["-","-","-","-","-"],                  #id
    ["-","-","-"],			   #desired course
    ],
    edited: [0,0,0,0],
    step: 0,
    value: 0,
    set_wp: func {
	gps_wp.getNode("wp/latitude-deg",1).setValue(gps_data.getNode("indicated-latitude-deg",1).getValue());
	gps_wp.getNode("wp/longitude-deg",1).setValue(gps_data.getNode("indicated-longitude-deg",1).getValue());
    },
    nav_rl: func {
	me.edited[me.pointedline] = 1;
	if (me.pointedline < 2) {
	    if (me.step == 0) {
		me.value = cycle_entries(2, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.numeric[me.value];
	    }
	    elsif (me.step == 8) {
		me.value = cycle_entries(2, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.card[me.value + (me.pointedline * 2)];
	    }
	    elsif (me.step == 3 or me.step == 5) {
		me.value = cycle_entries(6, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.numeric[me.value];
	    }
	    else {
		me.value = cycle_entries(size(numeric), me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.numeric[me.value];
	    }
	}
	elsif (me.pointedline == 2) {
	    me.value = cycle_entrie(size(me.alphanum), me.value, arg[0]);
	    me.map[me.pointedline][me.step] = me.alphanum[me.value];
	}
	else {
	    if (me.step == 0) {
		if (me.map[me.pointedline][1] < `6` or me.map[me.pointedline][1] == `-`)
		    me.value = cycle_entries(4, me.value, arg[0]);
		else
		    me.value = cycle_entries(3, me.value, arg[0]);
	    }
	    elsif (me.step == 1 and me.map[me.pointedline][0] == '3')
		me.value = cycle_entries(6, me.value, arg[0]);
	    else
		me.value = cycle_entries(size(me.numeric), me.value, arg[0]);
	    me.map[me.pointedline][me.step] = me.numeric[me.value];
	}
    },
    nav_ud: func {
	me.pointer = [" ", " ", " ", " "];
	me.pointedline = cycle_entries(size(me.map), me.pointedline, arg[0]);
	me.pointer[me.pointedline] = ">";
    },
    enter: func {
	me.step = cycle_entries(size(me.map[me.pointedline]), me.step, 1);
	if (me.map[me.pointedline][me.step] == '-')
	    me.value = 0;
	else
	    me.value = me.map[me.pointedline][me.step] - string.isdigit(me.map[me.pointedline][me.step]) ? `0` : `A`;
    },
    escape: func {
	me.set_wp();
	#fgcommand("dialog-show", "gps");
	displayed_screen = 1; #screenNavigationMain
    },
    start: func {
	var coord = [];
	var id = "";
	var dc = "";
	if (me.edited[0] ==1 and me.edited[1] == 1) {
	    for (var i = 0; i < 2; i += 1) {
		coord[i] = num(me.map[i][0]~me.map[i][1]~me.map[i][2]) 
		         + num(me.map[i][3]~me.map[i][4]) * 0.0166667
			 + (num(me.map[i][5]~me.map[i][6]) + num(me.map[i][7])/10) * 0.000166667;
	    }
	    gps_wp.getNode("wp[1]/latitude-deg",1).setValue(coord[0] * (me.map[0][8] == `N` ? 1 : -1));
	    gps_wp.getNode("wp[1]/longitude-deg",1).setValue(coord[1] * (me.map[1][8] == `E` ? 1 : -1));
	    gps_data.getNode("leg-mode",1).setBoolValue(1);
	    gps_data.getNode("obs-mode",1).setBoolValue(0);
	}
	if (me.edited[2] == 1) {
	    for (var i = 0; i < 5; i += 1) id ~= me.map[2][i] != `-` ? me.map[2][i] : "";
	    gps_wp.getNode("wp[1]/ID",1).setValue(id);
	}
	if (me.edited[3] ==1 ) {
	    for (var i = 0; i < 3; i += 1) dc ~= me.map[3][i];
	    gps_wp.getNode("wp[1]/desired-course",1).setValue(num(dc));
	    gps_data.getNode("leg-mode",1).setBoolValue(0);
	    gps_data.getNode("obs-mode",1).setBoolValue(1);
	}
	me.set_wp();
	displayed_screen = 1; #screenNavigationMain
    },
    lines: func {
	display([
	sprintf("%sLAT: %s%s%s*%s%s %s%s.%s %s",
	    me.pointer[0], me.map[0][0], me.map[0][1], me.map[0][2], me.map[0][3], me.map[0][4],
	    me.map[0][5], me.map[0][6], me.map[0][7], me.map[0][8]),
	sprintf("%sLON: %s%s%s*%s%s %s%s.%s %s",
	    me.pointer[1], me.map[1][0], me.map[1][1], me.map[1][2], me.map[1][3], me.map[1][4],
	    me.map[1][5], me.map[1][6], me.map[1][7], me.map[1][8]),
	sprintf("%sID: %s%s%s%s%s",
	    me.pointer[2], me.map[2][0], me.map[2][1], me.map[2][2], me.map[2][3], me.map[2][4]),
	sprintf("%sDESIRED COURSE:%s%s%s*", 
	    me.pointer[3], me.map[3][0], me.map[3][1], me.map[3][2]),
	""
	]);
    }
};

var display = func () {
    for (var i = 0; i < 5; i += 1) line[i].setValue(arg[0][i]);
}

var cycle_entries = func (entries_nbr, actual_entrie, dir) {   
    entries_nbr -= 1;
    if (dir == 1 and actual_entrie == entries_nbr) return 0;
    elsif (dir == -1 and actual_entrie == 0) return entries_nbr;
    else return actual_entrie + dir;
}

#### warps for buttons and knobs ########################################"

var nav_ud = func(dir) {
    isOn == 1 or return;
    screen[displayed_screen].nav_ud(dir);
    refresh_display();
}

var nav_rl = func(dir) {
    isOn == 1 or return;
    screen[displayed_screen].nav_rl(dir);
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

var select_mode = func(dir) {
    isOn == 1 or return;
    if (displayed_screen != 6) {
	displayed_screen = 6; #screenModeAndSettings
	screen[displayed_screen].mode(0);
    }
    else
	screen[displayed_screen].mode(dir);
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
	refresh_display();
    }
    props.globals.getNode("/instrumentation/gps/serviceable",1).setBoolValue(isOn);
}

var refresh_display = func() {
    screen[displayed_screen].lines();
    if (isOn and displayed_screen < 2) 
	settimer(func { refresh_display() }, freq, 1);
    if (mode > 2)
	settimer(func {
	}, freq, 1);
}

var seconds_to_string = func (time) {
    var hh = int(time / 3600);
    if (hh > 100) return "--:--:--";
    var mm = int(time - (hh * 3600)) / 60;
    var ss = int(time - (hh * 3600) - (mm * 60));
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

### initialisation stuff ###################################################

var init = func() {
    for (var i = 0; i < 5; i += 1) {
	append(line, props.globals.getNode("/instrumentation/lx500/line[" ~ i ~ "]", 1));
	line[i].setValue("");
    }
    props.globals.getNode("/instrumentation/gps/serviceable",1).setBoolValue(0);
    append(screen, screenPositionMain);    #0
    append(screen, screenNavigationMain);  #1
    append(screen, screenTaskSelect);      #2
    append(screen, screenATCinRange);      #3
    append(screen, screenAirportMain);     #4
    append(screen, screenAirportInfos);    #5
    append(screen, screenModeAndSettings); #6
    append(screen, screenWaypointEdit);    #7
    aircraft.light.new("/sim/model/gps/redled", [0.1, 0.1, 0.1, 0.7], "/instrumentation/gps/waypoint-alert");
    aircraft.light.new("/sim/model/gps/greenled", [0.6, 0.3], "/instrumentation/gps/message-alert");
    startpos = geo.Coord.new(geo.aircraft_position());
    screenPositionMain.begin_time = props.globals.getNode("/sim/time/elapsed-sec",1).getValue();
    setlistener("/instrumentation/gps/wp/wp[1]/TTW", func {
	mode > 0 or return; 
	var ttw = gps_wp.getNode("wp[1]/TTW",1).getValue();
	var ttw_secs = num(substr(ttw,0,2))*3600 + num(substr(ttw,3,2))*60 + num(substr(ttw,6,2));
	if (ttw_secs < thresold_alert[thresold_alert_index])
	    gps_data.getNode("waypoint-alert",1).setBoolValue(1);
	else
	    gps_data.getNode("waypoint-alert",1).setBoolValue(0);
	if (mode == 3 and ttw_secs < thresold_next_waypoint) {
	    screenNavigationMain.nextWaypoint();
	}	
    },0,0);
    print("GPS... initialized");
}

setlistener("/sim/signals/fdm-initialized",init);
