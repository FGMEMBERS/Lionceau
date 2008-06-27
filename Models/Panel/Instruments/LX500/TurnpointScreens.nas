var screenTurnpointSelect = {
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
	if (me.n > 0)
	    for (var l = 0; l < 5; l += 1) {
		if ((me.page * 5 + l) < me.n) {
		    name = gps_data.getNode("bookmarks/bookmark["~((me.page * 5) + l)~"]/ID").getValue();
		    line[l].setValue(sprintf("%s %s",me.pointer == l ? ">" : " ", name));
		}
		else
		    line[l].setValue("");
	    }
	else
	    display([
	    " ",
	    " ",
	    " NO BOOKMARKS",
	    " ",
	    " "
	    ]);
    }
};

var screenTurnpointInfos = {
    right : func {
    },
    enter : func {
    },
    escape : func {
    },
    start : func {
    },
    lines : func {
	display(NOT_YET_IMPLEMENTED);
    }
};
