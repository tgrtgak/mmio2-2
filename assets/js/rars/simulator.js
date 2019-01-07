"use strict";

import EventComponent from './event_component';

class Simulator extends EventComponent {
    /**
     * Constructs a new simulation with the given parameters.
     *
     * @param {number} memorySize The size of memory in MiB.
     * @param {string} configurationURL The URL of the simulation configuration.
     */
    constructor(memorySize, configurationURL, kernelBinaryOrURL, appBinaryOrURL) {
        super();

        this._memorySize = memorySize;
        this._loaded = false;
        this._started = false;
        this._module = {};
        this._startRequested = false;
        this._canStart = false;

        window.update_downloading = () => {
        };

        configurationURL = (new URL(configurationURL, window.location.href)).toString();
        configurationURL = "config.cfg";

        this._configurationURL = configurationURL;
        this._kernelBinary = {
            name: "kernel.bin",
            data: []
        };
        this._appBinaryOrURL = appBinaryOrURL;

        var kernelURL = (new URL(kernelBinaryOrURL, window.location.href)).toString();
        fetch(kernelURL, {
            credentials: 'include'
        }).then((response) => {
            return response.arrayBuffer();
        }).then((buffer) => {
            this._kernelBinary.data = buffer;
            this._canStart = true;
            if (this._canStart && this._startRequested) {
                this._load();
            }
        });

        this._appBinary = {
            name: "test.elf",
            data: appBinaryOrURL.data
        };

        this._initialize();
    }

    /*
     * Called internally to set up the simulator.
     */
    _initialize() {
        var Module = this._module;

        Module.locateFile = function(url) { return 'js/tinyemu/' + url; };

        var alloc_size = this.memorySize;
        /* frame buffer memory */
        /*if (graphic_enable) {
            alloc_size += (width * height * 4 + 1048576 - 1) >> 20;
        }*/

        alloc_size += 32; /* extra space (XXX: reduce it ?) */
        alloc_size = (alloc_size + 15) & -16; /* align to 16 MB */

        // Convert to bytes and set it in the runtime.
        Module.TOTAL_MEMORY = alloc_size << 20;

        var config = "\n{\n    version: 1,\n    machine: \"riscv64\",\n    memory_size: 256,\n    bios: \"kernel.bin\",    kernel: \"test.elf\"\n}";

        // Action to happen on quit.
        Module.quit = (status, ex) => {
            this._quit();
            throw ex;
        };

        Module.preRun = () => {
            this._initializeFS([
                {
                    type: "MEMFS",
                    file: {
                        name: "config.cfg",
                        data: config
                    }
                },
                {
                    type: "MEMFS",
                    file: this._kernelBinary
                },
                {
                    type: "MEMFS",
                    file: this._appBinary
                }
            ]);
            this._start();
        };

        Module.onRuntimeInitialized = () => {
            this._runtimeInitialized();
        };
    }

    /*
     * Called internally to set up the filesystem.
     */
    _initializeFS(mounts) {
        var FS = this._module.FS;

        // Borrowed a lot from Kagami, here. They are a veritable superhero.
        mounts.forEach( (mount) => {
            if (mount.type === "MEMFS") {
                return;
            }

            var fs = FS.filesystems[mount.type];
            if (!fs) {
                throw new Error("Bad mount type");
            }

            var mountpoint = mount.mountpoint;
            // NOTE(Kagami): Subdirs are not allowed in the paths to simplify
            // things and avoid ".." escapes.
            if (!mountpoint.match(/^\/[^\/]+$/) ||
                  mountpoint === "/." ||
                  mountpoint === "/.." ||
                  mountpoint === "/tmp" ||
                  mountpoint === "/home" ||
                  mountpoint === "/dev" ||
                  mountpoint === "/work") {
                throw new Error("Bad mount point");
            }

            FS.mkdir(mountpoint);
            FS.mount(fs, mount.opts, mountpoint);
        });

        FS.mkdir("/work");
        FS.chdir("/work");

        mounts.forEach( (mount) => {
            if (mount.type === "MEMFS") {
                if (mount.file.name.match(/\//)) {
                    throw new Error("Bad file name");
                }
                var fd = FS.open(mount.file.name, "w+");
                var data = this.__utils_toU8(mount.file.data);
                FS.write(fd, data, 0, data.length);
                FS.close(fd);
            }
        });
    }

    /*
     * Called internally when the simulator starts.
     */
    _start() {
        var Module = this._module;

        this._console_write1      = Module.cwrap('console_queue_char', null, ['number']);
        this._fs_import_file      = Module.cwrap('fs_import_file', null, ['string', 'number', 'number']);
        this._display_key_event   = Module.cwrap('display_key_event', null, ['number', 'number']);
        this._display_mouse_event = Module.cwrap('display_mouse_event', null, ['number', 'number', 'number']);
        this._display_wheel_event = Module.cwrap('display_wheel_event', null, ['number']);
        this._net_write_packet    = Module.cwrap('net_write_packet', null, ['number', 'number']);
        this._net_set_carrier     = Module.cwrap('net_set_carrier', null, ['number']);
        this._vm_start            = Module.cwrap('vm_start', null, ["string", "number", "string", "string", "number", "number", "number", "string"]);
        this._cpu_get_regs        = Module.cwrap('cpu_get_regs', null, ["number"]);
    }

    _runtimeInitialized() {
        if (this._started) {
            return;
        }

        this._started = true;
        this._vm_start(this.configurationURL,
                       this.memorySize,
                       "",   // cmdline
                       "",   // password
                       0,    // width
                       0,    // height
                       0,    // net_state
                       "");  // drive_url
                      //*/
    }

    /*
     * Called internally when the simulator ends.
     */
    _quit() {
        this.dump();
        this.trigger("quit");
    }

    /*
     * Internal function to convert various JS arrays into a Uint8Array.
     */
    __utils_toU8(data) {
        if (typeof data === 'string' || data instanceof String) {
            data = data.split("").map( (c) => c.charCodeAt(0) );
        }

        if (Array.isArray(data) || data instanceof ArrayBuffer) {
            data = new Uint8Array(data);
        }
        else if (!data) {
            // `null` for empty files.
            data = new Uint8Array(0);
        }
        else if (!(data instanceof Uint8Array)) {
            // Avoid unnecessary copying.
            data = new Uint8Array(data.buffer);
        }
        return data;
    }

    /**
     * Returns the established memory size for this simulation.
     *
     * @returns {number} The size of RAM in MiB.
     */
    get memorySize() {
        return this._memorySize;
    }

    /**
     * Returns the configuration URL for this simulation.
     *
     * @returns {string} The configuration URL designated for this simulation.
     */
    get configurationURL() {
        return this._configurationURL;
    }

    /**
     * Returns the value in the PC register.
     *
     * @returns {bigint} The value of the PC register as an integer.
     */
    get pc() {
        if (!this._loaded) {
            return window.BigInt(0);
        }
        return this.registers[0];
    }

    /**
     * Returns an integer array for the values in the registers.
     *
     * @returns {BigUint64Array} An array of unsigned 64-bit numbers.
     */
    get registers() {
        if (!this._loaded) {
            let ret = [];
            for (let i = 0; i < 32; i++) {
                ret[i] = window.BigInt(0);
            }
            return window.BigUint64Array(ret);
        }

        // The items are PC, followed by registers 1 through 32.
        // The 'zero' register is omitted, of course.
        var buf_len = 32*8;
        var buf = this._module._malloc(buf_len);

        this._cpu_get_regs(buf);

        /* Since we have a 64-bit CPU, the buffer is a 64-bit integer array */
        let ret = [];
        for (let i = 0; i < 32; i++) {
            var values = new Uint32Array([this._module.getValue(buf+(8*i)+4, 'i32'),
                                          this._module.getValue(buf+(8*i)+0, 'i32')]);
            values = [values[0].toString(16), values[1].toString(16)];
            values = "00000000".slice(values[0].length) + values[0] +
                     "00000000".slice(values[1].length) + values[1];

            var num = window.BigInt(0);
            if (num.shiftLeft) {
                // We are using the bigInt polyfill, which isn't exactly the same
                values = values.split("").map( (c) => ((c >= "0" && c <= "9") ? c.charCodeAt(0) - "0".charCodeAt(0) : c.charCodeAt(0) - "a".charCodeAt(0) + 10) );
                num = window.BigInt.fromArray(values, 16);
            }
            else {
                // We are using a native BigInt
                num = window.BigInt("0x" + values);
            }
            ret[i] = num;
        }

        /* Free the buffer. */
        this._module._free(buf);

        ret = new window.BigUint64Array(ret);

        return ret;
    }
    
    /**
     * Add a breakpoint.
     *
     * @param {number} address The address is break upon reaching.
     */
    addBreakpoint(address) {
    }

    /**
     * Removes a previously attached breakpoint via its address.
     *
     * @param {number} address The address of the breakpoint to remove.
     */
    removeBreakpoint(address) {
    }

    /**
     * Prints out the CPU state to the console.
     */
    dump() {
        this.registers.forEach(function(reg, i) {
            var str = reg.toString(16);
            str = "0000000000000000".slice(str.length) + str;
            window.console.log(Simulator.REGISTER_NAMES[i] + ": 0x" + str);
        });
    }

    /**
     * Start or resume the simulation.
     */
    run() {
        if (this._canStart) {
            this._load();
        }
        this._startRequested = true;
    }

    _load() {
        if (this._loaded || this._loadStarted) {
            return;
        }
        // Clear the terminal
        window.term.write("\x1b[2J\x1b[0;0H");
        this._loadStarted = true;
        window.TinyEmu(this._module).then( (Module) => {
            this._loaded = true;
            this._module = Module;
        });
    }

    /**
     * Pause the simulation.
     */
    pause() {
    }
}

/**
 * The URL of the simulator's JavaScript compiled code to use.
 */
Simulator.VM_URL = "tinyemu/riscvemu64-wasm.js";

/**
 * A mapping of register names to the register vector.
 *
 * The zero register is replaced with the name of the pc register for
 * convenience.
 */
Simulator.REGISTER_NAMES = [
    "pc", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1",
    "a2", "a3", "a4", "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
];

export default Simulator;
