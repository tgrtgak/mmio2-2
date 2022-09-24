"use strict";

class SimplePlugin {
    constructor() {
        this.address = 0xb0000000;
        this.size = 16;
    }

    loadPanel(selector) {
    }

    read(offset, size) {
        console.log("simple plugin read at " + offset.toString(16) + " for " + size + " bytes");
        return 29;
    }

    write(offset, val, size) {
        console.log("simple plugin write " + val + " at " + offset.toString(16) + " for " + size + " bytes");
    }
}

export default SimplePlugin;
