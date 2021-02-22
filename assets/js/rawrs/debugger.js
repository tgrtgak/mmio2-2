"use strict";

import EventComponent from './event_component';
import Console from './console';

class Debugger extends EventComponent {
    constructor() {
        super();

        console.log("loading gdb");
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
                return data;
            },
            serialInLength: () => {
                return this._serialin.byteLength;
            },
            serialOut: (ch, exit) => {
                this._packet += String.fromCharCode(ch);
                if (this._packet.length > 3 && this._packet[this._packet.length - 3] == '#') {
                    let packet = this._packet;
                    this._packet = "";
                    this.parse(packet);
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

    /**
     * Sets the current simulator.
     */
    set simulator(value) {
        this._simulator = value;
        this.invoke("target remote /dev/serial");
    }

    /**
     * Returns the attached Simulator.
     */
    get simulator() {
        return this._simulator;
    }

    _load() {
        // TODO: throw up a loading graphic in the debugger pane
        window.GDB(this._module).then( (Module) => {
            // TODO: remove loading graphic as the app loads
            console.log("GDB LOADED");
            this._console.clear();
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
        this._jsinvoke = Module.cwrap('jsinvoke', null, ['string', 'number']);

        // Call jsmain with the given command-line arguments

        // jsmain() is (int argc, char* argv) where argv is a list of strings
        // delimited by null bytes instead of an array of char* pointers.

        // This is to avoid building such a list in gdb's memory space ourselves
        // and just let emscripten do its thing. We build argv out of this
        // longer string in the jsmain implementation.
        let args = ['/usr/bin/gdb',
                    '--eval-command', 'set architecture riscv:rv64'];
        this._jsmain(args.length, args.join('\0'));
    }

    /**
     * Invokes a gdb command in the running gdb instance.
     */
    invoke(command) {
        if (this._jsinvoke) {
            this._jsinvoke(command, 0);
        }
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
        let realsum = this.checksum(data)

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

        // Interpret packet
        console.log("Debugger: packet:", payload, checksum, realsum);
        let response = this.interpret(payload);

        // Send the response
        this.write(response, true);
    }

    checksum(data) {
        if ((typeof data === 'string') || data instanceof String) {
            data = Buffer.from(data, 'utf-8');
        }

        return data.reduce( (a, e) => (a + e), 0) % 256;
    }

    encode(data, prefix = "") {
        let ret = new Uint8Array(prefix.length + (data.length * 2));
        let count = prefix.length;

        ret.set(Buffer.from(prefix, 'utf-8'), 0);

        if ((typeof data === 'string') || data instanceof String) {
            data = Buffer.from(data, 'utf-8');
        }

        // We have to encode such that we escape the ASCII characters gdb uses
        // to parse the packet names and arguments and checksums, etc.
        for (let i = 0; i < data.length; i++) {
            let b = data[i];
            if (b == 0x7d || b == 0x23 || b == 0x24 || b == 0x2a) {
                // An escaped byte is 0x7d followed by the original byte
                // XOR'd by 0x20
                ret[count] = 0x7d;
                count++;

                // XOR
                b ^= 0x20;
            }

            // Add the byte to the stream and increment count
            ret[count] = b;
            count++;
        }

        ret = ret.slice(0, count);
        return ret;
    }

    /**
     * Writes data to the serial connection.
     */
    write(data, ack = false) {
        if ((typeof data === 'string') || data instanceof String) {
            data = Buffer.from(data, 'utf-8');
        }

        // Form a new stdin buffer
        let serialin = new Uint8Array(this._serialin.byteLength + 1 + data.length + 3 + (ack ? 1 : 0));

        // Keep existing data in the stdin stream
        serialin.set(this._serialin, 0);

        let position = this._serialin.byteLength;

        if (ack) {
            serialin[position] = '+'.charCodeAt(0);
            position++;
        }

        // Write '$' to begin
        serialin[position] = '$'.charCodeAt(0);
        position++;

        // Write packet data
        serialin.set(data, position);
        position += data.length;

        // Write '#' to start the checksum
        serialin[position] = '#'.charCodeAt(0);
        position++;

        // Write checksum
        let sum = this.checksum(data).toString(16).padStart(2, '0');
        serialin[position] = sum.charCodeAt(0);
        serialin[position + 1] = sum.charCodeAt(1);

        // Establish this stdin
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
        // Try our best to get the packet name
        let name = packet.match(/^\?|^[a-zA-Z]+/)[0]

        // Issue the command (if we have an implementation)
        let result = "";
        if (name == "?") {
            result = this.stopReply(packet);
        }
        else {
            while (name.length > 0) {
                if (this[name]) {
                    try {
                        result = this[name].bind(this)(packet) || "";
                    }
                    catch (e) {
                        console.log(e);
                        throw e;
                    }
                    break;
                }

                name = name.substring(0, name.length - 1);
            }
        }

        return result;
    }

    /**
     * Responds to the '?' packet.
     *
     * This packet is asking why the process has stopped.
     *
     * @param {string} packet - The '?' packet data, which is just '?'.
     */
    stopReply(packet) {
        // Say we halted via SIGTRAP (breakpoint)
        return "S05";
    }

    /**
     * Responds to a qSupported packet.
     *
     * @param {string} packet - The qSupported packet data.
     */
    qSupported(packet) {
        return "PacketSize=256;swbreak+;hwbreak+;qXfer:exec-file:read+;vFile:open+";
    }

    vFile(packet) {
        let parts = packet.split(':');

        switch(parts[1]) {
            // Select the filesystem on the target.
            case "setfs":
                // Returns 0 on success.
                return "F 0";

            // Opens the given file and returns a file descriptor or -1 on error.
            case "open":
                if (parts[2][0] == "6") {
                    return "F -1";
                }

                return "F 1";
            case "pread":
                let args = parts[2].split(',');
                let fd = parseInt(args[0], 16);
                let count = parseInt(args[1], 16);
                let offset = parseInt(args[2], 16);

                if (this.simulator) {
                    let data = this.simulator.binary.data;
                    let bytes = data.slice(offset, offset + count);
                    return this.encode(bytes, "F " + bytes.length.toString(16) + ";");
                }
                else {
                    // Return error
                    return "F -1";
                }
                break;
        }
    }

    qXfer(packet) {
        let parts = packet.split(':');

        switch (parts[1]) {
            case "exec-file":
                switch (parts[2]) {
                    case "read":
                        return "l" + "/rawrs.elf";
                }
                break;
        }
    }

    /**
     * Responds to a qAttached packet to query the process info.
     *
     * This will respond with '1' if we are using an existing process or '0' if
     * we are using a created process.
     *
     * @param {string} packet - The qAttached packet data.
     */
    qAttached(packet) {
        return '1';
    }

    /**
     * Responds to the query current thread packet.
     *
     * @param {string} packet - The qC packet data.
     */
    qC(packet) {
        return 'QC 1';
    }

    /**
     * Responds to the query trace status packet.
     *
     * This would be used by GDB to know about some existing running trace at
     * our remote.
     *
     * @param {string} packet - The qTStatus packet data.
     */
    qTStatus(packet) {
        return "T0;tnotrun:0";
    }

    /**
     * Responds to a thread info query.
     *
     * This responds by sending a list of thread ids. GDB will keep asking
     * until it sees a response of 'l' by itself via the qsThreadInfo query.
     *
     * @param {string} packet - The qfThreadInfo packet data.
     */
    qfThreadInfo(packet) {
        return "1";
    }

    /**
     * Responds to a register-get packet.
     *
     * @param {string} packet - The g packet data.
     */
    g(packet) {
        // Get the registers from the simulator
        let values = [];

        if (this.simulator) {
            values = this.simulator.registers;
        }
        else {
            values = (new Array(32)).fill(BigInt(0));
        }

        // The 'pc' register is first in the list and needs to be the last.
        let regs = new BigUint64Array(33);
        regs[0] = BigInt(0);          // zero register
        regs.set(values.slice(1), 1); // general registers 1-32
        regs.set([values[0]], 32);    // pc

        // Turn every register value into a string that is its little-endian
        // representation in hexadecimal.
        let strs = [];
        regs.forEach( (v) => {
            // Render it as a little-endian hex string
            let bytes = new Uint8Array(8);
            let view = new DataView(bytes.buffer);

            // Write the little-endian value to the data view
            view.setBigInt64(0, BigInt(v), true);

            // Return the byte-string
            let result = "";
            bytes.forEach( (b) => {
                result += b.toString(16).padStart(2, '0');
            });
            strs.push(result);
        });

        // Return the 'zero' register and the registers from the simulator
        return strs.join('');
    }

    /**
     * Responds to a register-set packet.
     *
     * @param {string} packet - The G packet data.
     */
    G(packet) {
        packet = packet.slice(1);

        // Ignore the $zero register value
        packet = packet.slice(16);

        // Unpack register values

        // The registers are a set of hexadecimal, little-endian 64-bit values
        // sent as strings. There are 32 of them. The 31 general-purpose
        // registers are first (no $zero), followed by the $pc register.
        let regs = new BigUint64Array(32);
        regs.forEach( (v, i) => {
            // Prepare a byte array for the register value
            let bytes = new Uint8Array(8);
            let view = new DataView(bytes.buffer);

            // For each byte hex pair, decode the byte value
            bytes.forEach( (b, i) => {
                bytes[i] = parseInt(packet.slice(i * 2, (i * 2) + 2), 16);
            });
            packet = packet.slice(16);

            // Get the 'little-endian' value in the native endian by pulling it
            // from the view.
            let value = view.getBigInt64(0, true);

            // the $pc is first in the emulator but last in gdb, so map 33 -> 0,
            // but increment every other index
            let index = (i + 1) % 32;
            regs[index] = value;
        });

        // Set the register values
        if (this.simulator) {
            this.simulator.registers = regs;
        }

        // Return "" to simply ACK the message
        return "";
    }

    /**
     * Responds to a memory-read packet.
     *
     * @param {string} packet - The m packet data.
     */
    m(packet) {
        packet = packet.slice(1);
        let address = packet.split(',')[0];
        let length = packet.split(',')[1];
        console.log("examining memory at", address, "for", length, "bytes");

        address = parseInt(address, 16);
        length = parseInt(length, 16);
        return "ab".padStart(length * 2, '0');
    }

    /**
     * Responds to a memory-write packet.
     *
     * @param {string} packet - The M packet data.
     */
    M(packet) {
        packet = packet.slice(1);
        let address = packet.split(',')[0];
        let length = packet.split(',')[1];
        let value = packet.split(',')[2];
        console.log("writing memory at", address, "for", length, "bytes", "with", value);

        address = parseInt(address, 16);
        length = parseInt(length, 16);
        return "";
    }

    /**
     * Responds to a step packet.
     *
     * @param {string} packet - The s packet data.
     */
    s(packet) {
        // Step
        //sim.step();
        // Respond by saying we hit a breakpoint again.
        return "S05";
    }

    /**
     * Responds to a continue packet.
     *
     * @param {string} packet - The c packet data.
     */
    c(packet) {
        //sim.run();
        return "";
    }

    /**
     * Responds to a Hc packet.
     *
     * @param {string} packet - The Hc packet data.
     */
    Hc(packet) {
        return "OK"
    }

    /**
     * Responds to a Hg packet.
     *
     * @param {string} packet - The Hg packet data.
     */
    Hg(packet) {
        return "OK"
    }
}

export default Debugger;
