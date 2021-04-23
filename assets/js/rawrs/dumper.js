"use strict";

import EventComponent from './event_component';

class Dumper extends EventComponent {
    constructor() {
        super();
    }

    dump(binary, mode, section, terminal, callback) {
        let basepath = document.body.getAttribute('data-basepath');
        var worker = new Worker(basepath + "js/riscv64-unknown-elf-readelf.js");

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
                        arguments: [mode + section, binary.name]
                    });
                    break;
                case "stdout":
                    switch(mode){
                        // Returns memory in .data section
                        case "-x":
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
                        // Returns labels
                        case "-s":
                            var matches = Dumper.LABEL_REGEX.exec(msg.data);
                            if (matches) {
                                let symString = matches.splice(1).join('');
                                let address = symString.match(/^00000000([0-9a-f]+)/)[1];
                                let label = symString.match(/2 (\w+)/)[1];

                                let symbol = {
                                    address: address,
                                    label:   label
                                };
                                this.trigger('update', symbol);
                            }
                            break;
                        default:
                            break;
                    }
                    break;
                case "stderr":
                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    if (lastRow) {
                        this.trigger('update', lastRow);
                    }
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

Dumper.HEX_LINE_REGEX = /^\s+(?:0x)?([0-9a-f]+)\s+([0-9a-f]+)\s(?:([0-9a-f]+)\s)?(?:([0-9a-f]+)\s)?(?:([0-9a-f]+)\s)?\s*.+$/;
Dumper.LABEL_REGEX = /([0-9a-f]+\s+[0-9][\w ]+2 \w+)/;

export default Dumper;
