var screenTaskSelect = {
    page : 0,
    pointer: 0,
    n: 0,
    right : func {
	var t = browse(size(routes), me.pointer, me.page, arg[0]);
	me.pointer = t[0];
	me.page = t[1];
    },
    load : func {
        screenWaypointsList.n = 0;
	gps_data.getNode("route",1).removeChildren("Waypoint");
	fgcommand("loadxml", props.Node.new({
            "filename": getprop("/sim/fg-home") ~ "/Routes/" ~ routes[(me.page * 5) + me.pointer],
            "targetnode": "/instrumentation/gps/route"
        }));
	foreach (var c; gps_data.getNode("route").getChildren("Waypoint"))
	    screenWaypointsList.n += 1;
	gps_wp.getNode("wp/latitude-deg",1).setValue(gps_data.getNode("indicated-latitude-deg",1).getValue());
	gps_wp.getNode("wp/longitude-deg",1).setValue(gps_data.getNode("indicated-longitude-deg",1).getValue());
	gps_wp.getNode("wp/altitude-ft",1).setValue(gps_data.getNode("indicated-altitude-ft",1).getValue());
	gps_wp.getNode("wp/ID").setValue("startpos");

	gps_wp.getNode("wp[1]/latitude-deg",1).setValue(gps_data.getNode("route/Waypoint/latitude-deg",1).getValue());
	gps_wp.getNode("wp[1]/longitude-deg",1).setValue(gps_data.getNode("route/Waypoint/longitude-deg",1).getValue());
	gps_wp.getNode("wp[1]/altitude-ft",1).setValue(gps_data.getNode("route/Waypoint/altitude-ft",1).getValue());
	gps_wp.getNode("wp[1]/ID").setValue(gps_data.getNode("route/Waypoint/ID",1).getValue());

	waypointindex = 0;
	left_knob(1);
	#displayed_screen = 1; #screenNavigationMain
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

var screenWaypointsList = {
    n: 0,
    page: 0,
    pointer: 0,
    right : func {
	var t = browse(me.n, me.pointer, me.page, arg[0]);
	me.pointer = t[0];
	me.page = t[1];
    },
    enter : func {
    },
    escape : func {
    },
    start : func {
    },
    lines : func {
	for (var l = 0; l < 5; l += 1) {
	   if ((me.page * 5 + l) < me.n) {
		name = gps_data.getNode("route/Waypoint["~((me.page*5) + l)~"]/ID").getValue();
		line[l].setValue(sprintf("%s %s",me.pointer == l ? ">" : " ", name));
	    }
	    else
		line[l].setValue("");
	}
    }
};

var screenWaypointInfos = {
    info: 0,
    wp_list_page: 0,
    index: 0,
    content: 0,
    list: ["", "", "", "", ""],
    displayed_lines: -1,
    right : func {
	if (me.content == 2) {
	    if (arg[0] > 0 and me.index < me.displayed_lines)
		me.index += 1;
	    elsif (arg[0] > 0 and me.index == me.displayed_line) {
		if (gps_data.getNode("route/Waypoint["~(me.page+1)*5~"]") != nil) {
		    me.page += 1;
		    me.index = 0;
		}
		else {
		    me.page = 0;
		    me.index = 0;
		}
		me.displayed_lines = -1;
	    }
	    elsif (arg[0] < 0 and me.index > 0)
		me.index -= 1;
	    elsif (arg[0] < 0 and me.page > 0) {
		me.page -= 1;
		me.index = 4;
	    }
	}
    },
    left: func {
	if (me.content == 3) {
	    me.content = 0;
	    displayed_screen = 1; #screenNavigationMain
	}
	else
	    me.content = cycle(3, me.content, arg[0]);
    },
    enter: func {
    },
    escape: func {
    },
    start: func {
    },
    lines: func {
	if (me.content == 0) { #route infos
	    display(NOT_YET_IMPLEMENTED);
	}
	elsif (me.content == 1) { #leg infos
	    display(NOT_YET_IMPLEMENTED);
	}
	elsif (me.content == 2) { #waypoint list
	    for (var i = me.page * 5; i < (me.page+1)*5; i += 1) {
		var id = gps_data.getNode("route/Waypoint["~i~"]/ID",1);
		if (id != nil) {
		    me.list[i-(me.page*5)] = (i-(me.page*5) == me.index ? ">" : " ") ~ id.getValue();
		    me.displayed_lines += 1;
		}
		else
		    me.list[i-(me.page*5)] = "";
	    }
	    display(me.list);
	}
	elsif (me.content == 3) { #waypoint infos
	    display(NOT_YET_IMPLEMENTED);
	}
    }
};



