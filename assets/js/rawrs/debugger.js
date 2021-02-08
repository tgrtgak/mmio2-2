"use strict";

import EventComponent from './event_component';
import Console from './console';

class Debugger extends EventComponent {
    constructor() {
        super();

        this._stdin = new Uint8Array([]);
        this._serialin = new Uint8Array([]);

        this._console = new Console("#gdb_container", 28, 71, 15);

        this._console.on("data", (bytes) => {
            let data = Buffer.from(bytes, 'utf-8');
            let stdin = new Uint8Array(this._stdin.byteLength + data.byteLength)
            stdin.set(this._stdin, 0);
            stdin.set(data, this._stdin.byteLength);
            this._stdin = stdin;

            // Flush
            while(this._stdin.byteLength) {
                this._jsstep();
            }
        });

        this._loaded = false;
        this._started = false;
        this._packet = "";
        var Module = {
            stdout: (ch, exit) => {
                this._console.write(String.fromCharCode(ch));
            },
            stderr: (ch, exit) => {
                this._console.write(String.fromCharCode(ch));
            },
            stdin: () => {
                let data = this._stdin[0] || 0;
                this._stdin = this._stdin.slice(1);
                return data;
            },
            stdinLength: () => {
                return this._stdin.byteLength;
            },
            serialIn: () => {
                let data = this._serialin[0] || 0;
                this._serialin = this._serialin.slice(1);
                console.log("serialin; returning", data);
                return data;
            },
            serialInLength: () => {
                return this._serialin.byteLength;
            },
            serialOut: (ch, exit) => {
                this._packet += String.fromCharCode(ch);
                if (this._packet.length > 3 && this._packet[this._packet.length - 3] == '#') {
                    this.parse(this._packet);
                    this._packet = "";
                }
            },
            quit: (status, ex) => {
                console.log("done");
            }
        };

        Module.locateFile = function(url) { return 'js/' + url; };

        // Should be aligned to 16MiB
        var alloc_size = 16;

        // Convert to bytes and set it in the runtime.
        Module.INITIAL_MEMORY = alloc_size << 20;

        this._module = Module;
        this._load();
    }

    _load() {
        // TODO: throw up a loading graphic in the debugger pane
        window.GDB(this._module).then( (Module) => {
            // TODO: remove loading graphic as the app loads
            console.log("GDB LOADED");
            this._running = true;
            this._loaded = true;
            this._module = Module;

            // Create '/dev/serial'
            var FS = this._module.FS;
            FS.createDevice("/dev", "serial", this._module['serialIn'], this._module['serialOut']);

            // Call jsmain() and initialize
            this._start();
        });
    }

    _start() {
        // Import symbols
        var Module = this._module;
        this._jsmain = Module.cwrap('jsmain', null, ['number', 'string']);
        this._jsstep = Module.cwrap('jsstep', null, []);

        // Call jsmain with the given command-line arguments

        // jsmain() is (int argc, char* argv) where argv is a list of strings
        // delimited by null bytes instead of an array of char* pointers.

        // This is to avoid building such a list in gdb's memory space ourselves
        // and just let emscripten do its thing. We build argv out of this
        // longer string in the jsmain implementation.
        let args = ['/usr/bin/gdb'];
        this._jsmain(args.length, args.join('\0'));
    }

    /**
     * Parses a gdb packet.
     *
     * @param {string} packet - The full packet including payload and checksum.
     */
    parse(packet) {
        // Ignore acks and such until we see a packet head ($)
        while (packet[0] != '$') {
            packet = packet.substring(1);
        }

        // Check for invalid packets
        if (packet.length <= 3) {
            // Throw away packet
            console.log("Debugger: error: invalid packet", packet)
            return;
        }

        // A packet is in the form of $data#cs where `data` is a string of
        // characters (bytes with values less than 127) and `cs` is a two-digit
        // checksum in base 16.
        let data = packet.substring(1, packet.length - 3);

        // Checksum is the modulo 256 sum of all characters in the packet data
        let checksum = parseInt(packet.substring(packet.length - 2), 16);
        let realsum = data.split('')
                          .map( (e) => e.charCodeAt(0) )
                          .reduce( (e, a) => { return a + e; }) % 256;

        // Check for invalid checksum
        if (checksum != realsum) {
            // Warn but otherwise accept the packet. We aren't expecting this to
            // matter since our connections are reliable since they are local.
            console.log("Debugger: warning: checksum mismatch", packet,
                        "expected:", checksum,
                        "calculated:", realsum);
        }

        // Unpack packet
        let payload = "";
        let last = data[0];
        let state = 0;
        data.split('').forEach( (chr) => {
            if (state == 0) {
                if (chr == '*') {
                    // Run-length encoded: represents repeated bytes
                    // The next character is the repeated value + 29
                    state = 1;
                }
                else if (chr == '}') {
                    // Escape character
                    // The byte after the 0x7d ('}') character is XOR'd by 0x20
                    state = 2;
                }
                else {
                    payload += chr;
                }
            }
            else if (state == 1) { // Run-length encoded count
                let count = chr.charCodeAt(0) - 29;
                payload += "".padStart(count + 1, last);
                state = 0;
            }
            else if (state == 2) { // Escape character
                payload += String.fromCharCode(chr.charCodeAt(0) ^ 0x20);
                state = 0;
            }
            last = chr;
        });

        // Acknowledge
        this.write('+');

        // Interpret packet
        console.log("Debugger: packet:", payload, checksum, realsum);
        this.interpret(payload);
    }

    /**
     * Writes data to the serial connection.
     */
    write(data) {
        if ((typeof data === 'string') || data instanceof String) {
            data = Buffer.from(data, 'utf-8');
        }
        console.log("serial write");
        let serialin = new Uint8Array(this._serialin.byteLength + data.length);
        serialin.set(this._serialin, 0);
        serialin.set(data, this._serialin.byteLength);
        this._serialin = serialin;
    }

    /**
     * Interprets and responds to the given packet.
     *
     * This takes the packet in its unpacked form (unescaped and uncompressed)
     * and interprets the query. It eventually returns its response.
     *
     * @param {string} packet - An unpacked packet data payload.
     */
    interpret(packet) {
    }

    /**
     * Responds to a qSupported packet.
     *
     * @param {string} packet - The qSupported packet data.
     */
    qSupported(packet) {
    }
}

/**
 * An empty gdb packet.
 */
Debugger.EMPTY_PACKET = "$#00";

export default Debugger;
