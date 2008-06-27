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
    ["-","-","-","-","-"],                 #id
    ["-","-","-"],			   #desired course
    ],
    edited: [0,0,0,0],
    step: 0,
    value: 0,
    set_wp: func {
	gps_wp.getNode("wp/latitude-deg",1).setValue(gps_data.getNode("indicated-latitude-deg",1).getValue());
	gps_wp.getNode("wp/longitude-deg",1).setValue(gps_data.getNode("indicated-longitude-deg",1).getValue());
    },
    right: func {
	me.edited[me.pointedline] = 1;
	if (me.pointedline < 2) {
	    if (me.step == 0) {
		me.value = cycle(2, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.numeric[me.value];
	    }
	    elsif (me.step == 8) {
		me.value = cycle(2, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.card[me.value + (me.pointedline * 2)];
	    }
	    elsif (me.step == 3 or me.step == 5) {
		me.value = cycle(6, me.value, arg[0]);
		me.map[me.pointedline][me.step] = me.numeric[me.value];
	    }
	    else {
		me.value = cycle(size(numeric), me.value, arg[0]);
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
		    me.value = cycle(4, me.value, arg[0]);
		else
		    me.value = cycle(3, me.value, arg[0]);
	    }
	    elsif (me.step == 1 and me.map[me.pointedline][0] == '3')
		me.value = cycle(6, me.value, arg[0]);
	    else
		me.value = cycle(size(me.numeric), me.value, arg[0]);
	    me.map[me.pointedline][me.step] = me.numeric[me.value];
	}
    },
    left: func {
	me.pointer = [" ", " ", " ", " "];
	me.pointedline = cycle(size(me.map), me.pointedline, arg[0]);
	me.pointer[me.pointedline] = ">";
    },
    enter: func {
	me.step = cycle(size(me.map[me.pointedline]), me.step, 1);
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

