"use strict";

import Plugin from '../rawrs/plugin';

class SimplePlugin extends Plugin {
    constructor() {
        super(SimplePlugin.MMIO_ADDRESS, SimplePlugin.MMIO_SIZE, read, write);
    }

    read(offset, size) {
        console.log("simple plugin read at " + offset.toString(16) + " for " + size + " bytes");
        return 29;
    }

    write(offset, size, value) {
        console.log("simple plugin write " + value + " at " + offset.toString(16) + " for " + size + " bytes");
    }
}

SimplePlugin.MMIO_ADDRESS = 0xb0000000;
SimplePlugin.MMIO_SIZE = 16;
