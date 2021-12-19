"use strict";

class PluginManager {
    constructor() {
        this.pluginTable = new Map();
    }

    checkOverlap(new_address, new_size) {
        // for every plugin in the map, check for address overlap
        // for (let [address, pluginObject] of this.pluginTable) {
        //     let address_end = pluginObject.address + 2 ** pluginObject.size;
        //     let new_address_end = new_address + 2 ** new_size;

        //     // check if either end of both addresses lands within the address range of another plugin
        //     if (address <= new_address && new_address < address_end) {
        //         return true;
        //     }
        //     if (address < new_address_end && new_address_end <= address_end) {
        //         return true;
        //     }
        //     if (new_address <= address && address < new_address_end) {
        //         return true;
        //     }
        //     if (new_address < address_end && address_end <= new_address_end) {
        //         return true;
        //     }
        // }
        // default return false when there is no overlap
        return false;
    }

    // Adds all plugins within a certain directory to a Plugin Map so when the _runtimeInitialized()
    // is called in simulator.js, the PluginManager's Map will be accessed and each plugin will be added
    // to the simulator accordingly. 
    // This all has to happen before the simulator itself starts, so this whole process must happen
    // before vm_start() is called within simulator.js
    registerPlugin(pluginObject) {
        if (this.checkOverlap(pluginObject.address, pluginObject.size)) {
            console.log("Error when adding plugin at address " + pluginObject.address + ", address space already occupied.");
        } else {
            this.pluginTable.set(pluginObject.address, pluginObject);
        }
    }

    readFuncManager(address, offset, size) {
        return this.pluginTable.get(address).read(offset, size);
    }

    writeFuncManager(address, offset, val, size) {
        this.pluginTable.get(address).write(offset, val, size);
    }

    resetTable() {
        this.pluginTable.clear();
    }
}

export default PluginManager;
