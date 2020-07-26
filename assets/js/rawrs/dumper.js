"use strict";

import EventComponent from './event_component';

class Dumper extends EventComponent {
    constructor() {
        super();
    }

    dump(binary, section, terminal, callback) {
        var worker = new Worker("js/riscv64-unknown-elf-readelf.js");

        var blobs = [];
        var files = [binary];

        var lastRow = null;

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
                        arguments: ["-x" + section, binary.name]
                    });
                    break;
                case "stdout":
                    var matches = Dumper.HEX_LINE_REGEX.exec(msg.data);
                    if (matches) {
                        // Convert the hexdump to a byte array
                        // Each segment in the hexdump is a 4 byte little-endian word
                        let dataString = matches.slice(2).join('');
                        let data = new Uint8Array(dataString.match(/.{1,2}/g).map( (byte) => parseInt(byte, 16)));

                        if (lastRow) {
                            lastRow.data.set(data, lastRow.length)
                            lastRow.length = lastRow.data.byteLength;
                            this.trigger('update', lastRow);
                            lastRow = null;
                        }
                        else {
                            let row = new Uint8Array(data.length * 2);
                            row.set(data, 0);
                            lastRow = {
                                address: matches[1],
                                length:  data.byteLength,
                                data:    row
                            };
                        }
                    }
                    break;
                case "stderr":
                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    this.trigger('done');
                    if (lastRow) {
                        this.trigger('update', lastRow);
                    }
                    callback();
                    worker.terminate();
                    break;
                default:
                    break;
            }
        };
    }
}

Dumper.HEX_LINE_REGEX = /^\s+(?:0x)?([0-9a-f]+)\s+([0-9a-f]+)\s(?:([0-9a-f]+)\s)?(?:([0-9a-f]+)\s)?(?:([0-9a-f]+)\s)?\s*.+$/;

export default Dumper;
