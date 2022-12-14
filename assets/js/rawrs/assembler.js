"use strict";

import EventComponent from './event_component';

class Assembler extends EventComponent {
    constructor() {
        super();
    }

    assemble(filename, source, terminal, callback) {
        let basepath = document.body.getAttribute('data-basepath');
        var worker = new Worker(basepath + "js/binutils/riscv64-unknown-elf-as.js");
        terminal.clear();
        terminal.writeHeader("Assembling");

        source = source + "\n";
        var fileData = new Blob([source], {'type': 'text/plain'});

        var blobs = [{
          name: filename,
          data: fileData
        }];

        let basename = filename.match(/([^/]+)[.].+$/)[1]

        worker.onmessage = (e) => {
            var msg = e.data;

            switch(msg.type) {
                case "ready":
                    worker.postMessage({
                        type: "run",
                        MEMFS: [],
                        mounts: [{
                            type: "WORKERFS",
                            opts: {
                                blobs: blobs
                            },
                            "mountpoint": "/input"
                        }],
                        arguments: ["/input/" + filename, "-o", basename + ".o", "-g"]
                    });
                    break;
                case "stdout":
                    terminal.writeln(msg.data);
                    break;
                case "stderr":
                    // Check for error statements
                    var matches = Assembler.ERROR_REGEX.exec(msg.data);
                    if (matches) {
                        this.trigger('error', {
                            row: parseInt(matches[1]) - 1,
                            column: 0,
                            text: matches[2]
                        });
                    }

                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    if (msg.data.MEMFS[0]) {
                        terminal.write("Assembly successful.");
                    }
                    else {
                        terminal.write("Assembly failed.");
                    }

                    this.trigger('done');
                    if (msg.data.MEMFS[0]) {
                        callback(msg.data.MEMFS[0]);
                    }
                    worker.terminate();
                    break;
                default:
                    break;
            }
        };
    }
}

Assembler.ERROR_REGEX = /^\S+:(\d+):\s+Error:\s+(.+)$/;

export default Assembler;
