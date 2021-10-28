"use strict";

import EventComponent from './event_component';

class Linker extends EventComponent {
    constructor() {
        super();
    }

    link(linkerScript, object, terminal, callback) {
        terminal.writeln("");
        terminal.writeHeader("Linking");

        // Initially, there are no errors
        this._errors = [];

        let basepath = document.body.getAttribute('data-basepath');
        var worker = new Worker(basepath + "js/binutils/riscv64-unknown-elf-ld.js");

        linkerScript = linkerScript + "\n";
        var fileData = new Blob([linkerScript], {'type': 'text/plain'});

        var blobs = [{
          name: "linker.ld",
          data: fileData
        }];

        var files = [object];

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
                        arguments: [object.name, "-T", "/input/linker.ld", "-o", "foo.elf", "-g"]
                    });
                    break;
                case "stdout":
                    terminal.writeln(msg.data);
                    break;
                case "stderr":
                    // Check for error statements
                    var matches = Linker.ERROR_REGEX.exec(msg.data);
                    if (matches) {
                        var error = {
                            row: parseInt(matches[1]) - 1,
                            column: 0,
                            text: matches[2]
                        };
                        this._errors.push(error);
                        this.trigger('error', error);
                    }

                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    if (msg.data.MEMFS[0] && this._errors.length == 0) {
                        terminal.write("Linking successful.");
                    }
                    else {
                        terminal.write("Linking failed.");
                    }

                    this.trigger('done');
                    if (msg.data.MEMFS[0] && this._errors.length == 0) {
                        callback(msg.data.MEMFS[0]);
                    }
                    worker.terminate();
                    break;
                default:
                    break;
            }
        };
    }

    /**
     * Retrieves the errors gathered in the last link.
     */
    get errors() {
        return this._errors.slice();
    }
}

Linker.ERROR_REGEX = /^\S+:(\d+):\s+(.+)$/;

export default Linker;
