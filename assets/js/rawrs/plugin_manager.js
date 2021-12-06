"use strict";

import EventComponent from './event_component';

// plugin class (does it have to be an inner class in this case)
class plugin extends EventComponent{
    // passing in the pointer
    constructor(address,size, read_func, write_func) {
        this.address = address;
        this.size = size;
        this.read_func = read_func(address, size);
        this.write_func = write_func(address, size, data);
    }

    get get_readfunc() {
        return this.read_func;
    }

    get get_writefunc() {
        return this.write_func;
    }
}

class plugin_manager extends EventComponent{
    plugin_table
    address_set
    constructor() {
        this.name = 'plugin manager';
        this.plugin_table = new Map();
        this.address_set = new Set();
    }

    check_overlap(address, size) {
       for(let i = address; i<address+size ; i++) {
            if(this.address_set.has(i)) {
                return true;
            }
       }
       return false;
    }

    register_new_plugin() {
        const new_plugin = new plugin(address, size, read_func, write_func);
        if(check_overlap(new_plugin.address, size) == true) {
            console.log(new_plugin.address);
        }
        else {
            this.plugin_table.set(new_plugin.address, new_plugin);
            for(let i = new_plugin.address; i<new_plugin.address+size; i++) {
                this.address_set.add(i);
            }
        }
    }

    // get read function
    get get_readfunc_manager(address) {
        return this.plugin_table.get(address).get_readfunc();
    }

    // get write function
    get get_writefunc_manager(address) {
        return this.plugin_table.get(address).get_writefunc();
    }
}
export default plugin_manager;


