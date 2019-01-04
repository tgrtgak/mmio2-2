"use strict";

class Linker {
    static link(linkerScript, object, terminal, callback) {
        terminal.writeln("");
        terminal.writeln("Linking ------------------------------------------------------------------------");

        var worker = new Worker("js/riscv64-unknown-elf-ld.js");

        linkerScript = linkerScript + "\n";
        var fileData = new Blob([linkerScript], {'type': 'text/plain'});

        var blobs = [{
          name: "linker.ld",
          data: fileData
        }];

        var files = [object];

        worker.onmessage = function(e) {
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
                    terminal.writeln(msg.data);
                    break;
                case "exit":
                    break;
                case "done":
                    callback(msg.data.MEMFS[0]);
                    worker.terminate();
                    break;
                default:
                    break;
            }
        };
    }
}

export default Linker;
