"use strict";

class KsimPlugin {
    constructor() {
        this.address = 0xffff0000;
        this.size = 16;

	this.r1 = 1;
	this.r2 = 2;
	this.r3 = 3;
	this.r4 = 4;
    }

    loadPanel(selector) {
	this.pluginDiv = document.createElement('div');
        var x = document.createElement('div');
        var y = document.createElement('div');

        var j = document.createElement("TEXTAREA");
        var k = document.createElement("TEXTAREA");
	j.id = "ksim_display"
	k.id = "ksim_keyboard"

	j.style.resize = "none";
	j.readOnly = true;
	k.style.resize = "none";

        j.style.width="640px"
        j.style.height="235px"
        k.style.width="640px"
        k.style.height="235px"


        k.addEventListener('keydown', (event) => {
               	this.r1 = 1;
		this.r2 = ((event.key).charCodeAt(0));
                });

        x.appendChild(j);
        y.appendChild(k);
	this.pluginDiv.appendChild(x);
        this.pluginDiv.appendChild(y);

	document.querySelector(selector).appendChild(this.pluginDiv);
    }

    read(offset, size) {
        console.log("simple plugin read at " + offset.toString(16) + " for " + size + " bytes");

	switch(offset) {
	case 0:
		return this.r1;
		break;
	case 4:
		this.r1 = 0;
		return this.r2;
		break;
	case 8:
		return this.r3;
		break;
	case 12:
		return this.r4;
		break;
	default:
		return 0;
		break;
	}
    }

    write(offset, val, size) {
        console.log("simple plugin write " + val + " at " + offset.toString(16) + " for " + size + " bytes");

	switch(offset) {
	case 0:
		break;
	case 4:
		break;
	case 8:
		this.r3 = val;
		break;
	case 12:
		this.r4 = val;
		if (this.r3 == 1)
		{
			var temp = String.fromCharCode(this.r4);
			document.getElementById("ksim_display").value += '' + temp;
			this.r3 = 0;
		}
		break;
	default:
		break;
	}
    }
}

export default KsimPlugin;
