"use strict";

import EventComponent from './event_component';

// plugin class (does it have to be an inner class in this case)
class Plugin extends EventComponent {
    // passing in the pointer
    constructor(address, size, read, write) {
        this.address = address;
        this.size = size;
        this.read_func = read;
        this.write_func = write;
    }

    get read() {
        return this.read;
    }

    get write() {
        return this.write;
    }
}

export default Plugin;
