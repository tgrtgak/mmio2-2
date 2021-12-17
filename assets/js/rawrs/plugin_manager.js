"use strict";

import EventComponent from './event_component';
import Plugin from './plugin';

class PluginManager extends EventComponent {
    //plugin_table
    constructor() {
        this.name = 'plugin manager';
        this.plugin_table = new Map();
    }

    check_overlap(new_address, new_size) {
        // for every plugin in the map, check for address overlap
        for(let [address, Plugin] of this.plugin_table) {
            // accomodate for very large size
            let address_end = BigInt(address) + BigInt(2) ** BigInt(Plugin.size);
            let new_address_end = BigInt(new_address) + BigInt(2) ** BigInt(new_size);

            // check if either end of both addresses lands within the address range of another plugin
            if(address <= new_address && new_address < address_end) {
                return true;
            }
            if(address < new_address_end && new_address_end <= address_end) {
                return true;
            }
            if(new_address <= address && address < new_address_end) {
                return true;
            }
            if(new_address < address_end && address_end <= new_address_end) {
                return true;
            }

        }
        // default return false when there is no overlap
        return false;
    }

    // Adds all plugins within a certain directory to a Plugin Map so when the _runtimeInitialized()
    // is called in simulator.js, the PluginManager's Map will be accessed and each plugin will be added
    // to the simulator accordingly. 
    // This all has to happen before the simulator itself starts, so this whole process must happen
    // before vm_start() is called within simulator.js
    register_plugins() {
        // TODO: Create a plugin based on plugins found in a directory
        // current pseudocode (?)
        // foreach (plugin_directory/my_plugin.js) {
        //     new_plugin = new my_plugin(my_plugin.MMIO_ADDRESS, my_plugin.MMIO_SIZE, 
        //                                 my_plugin.read, my_plugin.write);
        //     if(check_overlap == true) console.log("bad address");
        //     else this.plugin_table.set(new_plugin);
        // }

        const new_plugin = new Plugin(address, size, read, write);
        if(check_overlap(new_plugin.address, size) == true) {
            console.log("Error when adding plugin at address " + new_plugin.address + ", address space already occupied.");
        }
        // this address space request is valid so will be added to the map
        else {
            this.plugin_table.set(new_plugin.address, new_plugin);
        }
    }

    // get read function
    get read_func_manager() {
        return this.plugin_table.get(address).read(offset, size);
    }

    // get write function
    get write_func_manager() {
        return this.plugin_table.get(address).write(offset, size, val);
    }
}

export default PluginManager;
