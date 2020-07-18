"use strict";

import EventComponent from './event_component';

class Disassembler extends EventComponent {
    constructor() {
        super();
    }

    disassemble(binary, terminal, callback) {
        var worker = new Worker("js/riscv64-unknown-elf-objdump.js");

        var blobs = [];
        var files = [binary];

        worker.onmessage = (e) => {
            var msg = e.data;

            switch(msg.type) {
                case "ready":
                    worker.postMessage({
                        type: "run",
                        MEMFS: files,
                        mounts: [{
                            type: "WORKERFS",
                            opts: {
                                blobs: blobs
                            },
                            "mountpoint": "/input"
                        }],
                        arguments: [binary.name, "-d", "-l"]
                    });
                    break;
                case "stdout":
                    var matches = Disassembler.SOURCE_LINE_REGEX.exec(msg.data);
                    if (matches) {
                        this._currentSource = {
                            row: parseInt(matches[2]),
                            file: matches[1]
                        };
                    }

                    matches = Disassembler.INSTRUCTION_REGEX.exec(msg.data);
                    if (matches) {
                        this.trigger('instruction', {
                            address: matches[1],
                            machineCode: matches[2],
                            code: matches[3],
                            file: this._currentSource.file,
                            row: this._currentSource.row
                        });
                    }
                    break;
                case "stderr":
                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    this.trigger('done');
                    callback();
                    worker.terminate();
                    break;
                default:
                    break;
            }
        };
    }
}

/**
 * The regular expression that, when matched, denotes that the disassembly has
 * found a hint to the original line.
 */
Disassembler.SOURCE_LINE_REGEX = /^(\/[^:]+):(\d+)$/;

/**
 * This regular expression parses a disassembled line.
 */
Disassembler.INSTRUCTION_REGEX = /^\s+([0-9a-f]+):\s+([0-9a-f]+)\s+(.+)$/;

export default Disassembler;
