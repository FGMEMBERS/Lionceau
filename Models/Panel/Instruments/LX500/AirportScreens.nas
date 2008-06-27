var screenAirportMain = {
    pos: nil,
    apt_coord: nil,
    right : func {
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
	page = 1;
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
    lines : func (searched = nil) {
	if (searched != nil)
	    apt = searched;
	else
	    apt = airportinfo();
	glide_slope_tunnel.complement_runways(apt);
	var rwy = glide_slope_tunnel.best_runway(apt);
	me.pos = geo.Coord.new(geo.aircraft_position());
	me.apt_coord = geo.Coord.new().set_latlon(rwy.lat, rwy.lon);
	var ac_to_apt = [me.pos.distance_to(me.apt_coord), me.pos.course_to(me.apt_coord)];
	var ete = ac_to_apt[0] / getprop("instrumentation/gps/indicated-ground-speed-kt") * 3600 * 1852;
	print(ete);
	display([
	sprintf("%s APT: %s", searched != nil ? "SEARCHED" : "NEAREST", apt.id),
	sprintf("ELEV: %d %s", apt.elevation * alt_conv[1][alt_unit],alt_unit_short_name[alt_unit]),
	sprintf("DIST: %d %s",ac_to_apt[0] * dist_conv[2][dist_unit],dist_unit_short_name[dist_unit]),
	sprintf("BRG: %d°    RWY: %02d",ac_to_apt[1], int(rwy.heading) / 10),
	sprintf("ETE: %s",seconds_to_string(ete))
	]);
    }
};

var screenAirportInfos = {
    page : 0,
    rwylist: [],
    right : func {
	me.page = 0;
	displayed_screen = 4;# screenAirportMain
    },
    left : func {
	np = int(size(me.rwylist) / 4) + (math.mod(size(me.rwylist),4) ? 1 : 0);
	me.page = cycle(np, me.page, arg[0]);
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

var screenSearchAirport = {
    oaci : ["-","-","-","-"],
    pointer: 0,
    value: 0,
    searched: nil,
    right : func {
	me.value = cycle(size(screenEdit.alphanum), me.value, arg[0]);
	me.oaci[me.pointer] = screenEdit.alphanum[me.value];
    },
    enter : func {
	if (me.pointer < 3) { 
	    me.pointer += 1;
	    me.value = 0;
	}
	else 
	    me.searched = airportinfo(me.oaci[0]~me.oaci[1]~me.oaci[2]~me.oaci[3]);
    },
    escape : func {
	me.oaci = ["-","-","-","-"];
	me.pointer = 0;
	me.searched = nil;
    },
    start : func {
    },
    lines : func {
	if (me.searched == nil)
	    display([
	    "SEARCH AIRPORT:",
	    sprintf("%s%s%s%s",me.oaci[0],me.oaci[1],me.oaci[2],me.oaci[3]),
	    "",
	    "",
	    ""
	    ]);
	else {
	    screenAirportMain.lines(me.searched);
	    me.right();
	}
    }
};


