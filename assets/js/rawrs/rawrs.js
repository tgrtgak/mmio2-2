"use strict";

import Tabs            from './tabs';
import Console         from './console';
import Video           from './video';
import Editor          from './editor';
import Toolbar         from './toolbar';
import Simulator       from './simulator';
import Assembler       from './assembler';
import Linker          from './linker';
import Disassembler    from './disassembler';
import Debugger        from './debugger';
import Dumper          from './dumper';
import Terminal        from './terminal';
import FileList        from './file_list';
import CodeListing     from './code_listing';
import MemoryListing   from './memory_listing';
import LabelListing    from './label_listing';
import RegisterListing from './register_listing';
import Separator       from './separator';

class RAWRS {
    static load() {
        // Load all separators
        let separators = Array.from(
            document.querySelectorAll(".separator")
        ).map( (el) => {
            return new Separator(el);
        });

        // Determine the rootpath for any relative ajax calls later on
        let path = window.location.pathname;
        path = path.split("/");
        path = path.slice(0, path.length - 1);
        path = path.join("/");
        if (!path.startsWith("/")) {
            path = "/" + path;
        }
        if (!path.endsWith("/")) {
            path = path + "/";
        }
        let rootpath = window.location.origin + path;
        document.body.setAttribute('data-rootpath', rootpath);

        // Ensure we go to the indicated anchor
        if (window.location.hash) {
            let item = document.querySelector(window.location.hash);
            if (item) {
                item.scrollIntoView();
            }
        }

        this._console = new Console("#term_container", 29, 71, 15);
        this._video = new Video(640, 480, document.querySelector("#video canvas"));
        this._debugConsole = new Console("#gdb_container", 29, 71, 15);
        this._terminal = new Terminal(document.body);

        // TinyEMU looks for this:
        window.term = {
            write: (x) => {
                this._console.write(x);
            },
            getSize: (x) => {
                return [this._console.columns, this._console.rows];
            }
        };

        Tabs.load();
        this._tabs = Tabs.load(document.querySelector('#main-tabs'));
        Editor.initialize();
        RAWRS.toolbar  = new Toolbar(document.body);
        RAWRS.fileList = new FileList(document.body);

        var saveTimer = null;
        window.editor.getSession().on('change', () => {
            if (saveTimer) {
                window.clearTimeout(saveTimer);
            }

            saveTimer = window.setTimeout( () => {
                var data = window.editor.getValue();
                RAWRS.fileList.save(data);
            }, 500);
        });

        // Load local storage directory
        RAWRS.fileList.loadRoot().then( () => {
            RAWRS.fileList.revealPath(RAWRS.fileList.startupFile).then( () => {
                let item = RAWRS.fileList.startupItem;
                if (item) {
                    RAWRS.fileList.loadItem(item);
                }
            });
        });

        RAWRS.fileList.on('change', (item) => {
            let info = RAWRS.fileList.infoFor(item);
        });

        RAWRS.codeListing = new CodeListing(document.body);
        RAWRS.registerListing = new RegisterListing(document.body);
        RAWRS.memoryListing = new MemoryListing(document.body);
        RAWRS.labelListing = new LabelListing(document.body);
        RAWRS._simulator = null;

        RAWRS.codeListing.on("breakpoint-set", (address) => {
            if (RAWRS.simulator) {
                RAWRS.simulator.breakpointSet(address);
            }
            if (this._gdb) {
                this._gdb.breakpointSet(address);
            }
        });

        RAWRS.codeListing.on("breakpoint-clear", (address) => {
            if (RAWRS.simulator) {
                RAWRS.simulator.breakpointClear(address);
            }
            if (this._gdb) {
                this._gdb.breakpointClear(address);
            }
        });

        RAWRS.registerListing.on("change", (info) => {
            let regs = RAWRS.registerListing.registers;
            if (RAWRS.simulator) {
                RAWRS.simulator.registers = regs;
                RAWRS.registerListing.update(RAWRS.simulator.registers);
            }
        });

        RAWRS.memoryListing.on("change", (info) => {
            if(RAWRS.simulator) {
                let sim = RAWRS.simulator;
                sim.writeMemory(info.address, info.data);

                let numRows = RAWRS.memoryListing.numberOfRows;
                let addresses = RAWRS.memoryListing.addresses;
                RAWRS.memoryListing.clear();
                for (let i = 0; i < numRows; i++) {
                    let data = sim.readMemory(parseInt(addresses[i], 16), 32);
                    RAWRS.memoryListing.update(addresses[i], data);
                }
            }
        });

        RAWRS.toolbar.on('click', (button) => {
            switch (button.getAttribute("id")) {
                case "assemble":
                    RAWRS.toolbar.setStatus("run", "disabled");
                    RAWRS.toolbar.setStatus("assemble", "active");
                    this.runRequested = false;
                    this.assemble();
                    break;
                case "run":
                    RAWRS.toolbar.setStatus("step", "disabled");
                    RAWRS.toolbar.setStatus("run", "active");
                    this.runRequested = true;
                    if (RAWRS.toolbar.getStatus("assemble") === "success") {
                        this.run();
                    }
                    else {
                        RAWRS.toolbar.setStatus("run", "disabled");
                        RAWRS.toolbar.setStatus("assemble", "active");
                        this.assemble();
                    }
                    break;
                case "step":
                    if (RAWRS.simulator && RAWRS.simulator.running) {
                        // Pause, if still running
                        this.pause();
                    }
                    else {
                        // Otherwise, step
                        this.step();
                    }
                    break;
                default:
                    // Unknown button
                    break;
            }
        });
    }

    /**
     * Retrieves the current active Simulator instance.
     */
    static get simulator() {
        return this._simulator;
    }

    static run() {
        if (RAWRS.simulator && RAWRS.simulator.paused) {
            // Resume simulation
            RAWRS.toolbar.setStatus("step", "");
            RAWRS.toolbar.setStatus("run", "active");
            RAWRS.simulator.resume();
        }
        else {
            // Create and start the simulation (or restart, if it is running.)

            // Carry over last breakpoints
            let bp = undefined;
            if (RAWRS.simulator) {
                bp = RAWRS.simulator.breakpoints;
            }

            let basepath = document.body.getAttribute('data-basepath');
            let sim = new Simulator(32, "basic-riscv64.cfg", basepath + "kernel/kernel.bin", this._binary, this._console, this._video, bp);

            sim.on("quit", () => {
                // Update console
                this._terminal.writeln("Simulation ended.");
                this._terminal.writeln("");

                // Update the toolbar buttons
                RAWRS.toolbar.setStatus("run", "success");
                RAWRS.toolbar.setStatus("step", "disabled");

                // Dump the registers
                RAWRS.registerListing.update(sim.registers);

                // Update memory
                let numRows = RAWRS.memoryListing.numberOfRows;
                let addresses = RAWRS.memoryListing.addresses;
                RAWRS.memoryListing.clear();
                for (let i = 0; i < numRows; i++) {
                    let data = sim.readMemory(parseInt(addresses[i], 16), 32);
                    RAWRS.memoryListing.update(addresses[i], data);
                }

                // Tell debugger to stop
                RAWRS._gdb.showDisconnected();

                if (RAWRS._clearBreakpoint != false) {
                    sim.breakpointClear(RAWRS._clearBreakpoint);
                    RAWRS._clearBreakpoint = false;
                }
            });

            sim.on("breakpoint", () => {
                // Update console
                if (sim.ready) {
                    this._terminal.writeln("Simulation breakpoint reached.");
                }

                // Update the toolbar buttons
                RAWRS.toolbar.setStatus("step", "active");
                RAWRS.toolbar.setStatus("run", "");

                // Get register dump
                RAWRS.registerListing.unhighlight();
                RAWRS.registerListing.update(sim.registers);

                // Get updated memory
                let numRows = RAWRS.memoryListing.numberOfRows;
                let addresses = RAWRS.memoryListing.addresses;
                RAWRS.memoryListing.clear();
                for (let i = 0; i < numRows; i++) {
                    let data = sim.readMemory(parseInt(addresses[i], 16), 32);
                    RAWRS.memoryListing.update(addresses[i], data);
                }

                // Tell debugger to stop
                RAWRS._gdb.invoke("target remote /dev/serial");

                // Highlight code line and scroll to it
                RAWRS.codeListing.highlight(sim.pc.toString(16));

                if (RAWRS._clearBreakpoint != false) {
                    sim.breakpointClear(RAWRS._clearBreakpoint);
                    RAWRS._clearBreakpoint = false;
                }
            });

            sim.on("running", () => {
                // Update console
                this._terminal.writeln("Simulation started.");

                // When the simulator is running, unhighlight
                RAWRS.codeListing.unhighlight();

                // Tell the debugger the simulation is running
                // TODO: debugger call-in
            });

            sim.on("paused", () => {
                // Update console
                this._terminal.writeln("Simulation paused.");

                RAWRS.toolbar.setStatus("run", "paused");
                RAWRS.toolbar.setStatus("step", "active");

                // Get register dump
                RAWRS.registerListing.unhighlight();
                RAWRS.registerListing.update(sim.registers);

                // Get updated memory
                let numRows = RAWRS.memoryListing.numberOfRows;
                let addresses = RAWRS.memoryListing.addresses;
                RAWRS.memoryListing.clear();
                for (let i = 0; i < numRows; i++) {
                    let data = sim.readMemory(parseInt(addresses[i], 16), 32);
                    RAWRS.memoryListing.update(addresses[i], data);
                }

                // Tell debugger to stop
                RAWRS._gdb.invoke("target remote /dev/serial");

                // Highlight code line and scroll to it
                RAWRS.codeListing.highlight(sim.pc.toString(16));
            });

            sim.on("ready", () => {
                this._terminal.writeln("Simulation ready to run.");

                if (RAWRS.runRequested) {
                    RAWRS.toolbar.setStatus("step", "");
                    RAWRS.toolbar.setStatus("run", "active");
                    RAWRS.simulator.resume();
                }
            });

            sim.on("registers-change", () => {
                RAWRS.registerListing.update(sim.registers);
                RAWRS.codeListing.highlight(sim.pc.toString(16));
            });

            let framebufferRefresh = 0;
            sim.on("framebuffer-refresh", () => {
                // On the first refresh, switch to video
                if (framebufferRefresh == 0) {
                    let videoButton = document.querySelector("button[aria-controls=\"video\"]");
                    if (videoButton) {
                        videoButton.parentNode.parentNode.querySelectorAll("li.tab").forEach( (tabElement) => {
                            tabElement.classList.remove("active");
                        });
                        videoButton.parentNode.classList.add("active");
                    }

                    let videoPanel = document.querySelector(".tab-panel#video");
                    if (videoPanel) {
                        videoPanel.parentNode.querySelectorAll("li.tab-panel").forEach( (panelElement) => {
                            panelElement.classList.remove("active");
                        });
                        videoPanel.classList.add("active");
                    }

                }
                framebufferRefresh++;
            });

            RAWRS._simulator = sim;
            RAWRS._gdb.simulator = sim;
            RAWRS.simulator.run();
        }
    }

    static pause() {
        if (RAWRS.simulator) {
            RAWRS.simulator.pause();
        }
    }

    static step() {
        if (RAWRS.simulator) {
            // If the current instruction is an ecall... we want to breakpoint
            // to the following instruction instead of stepping.
            //
            // Since, if we step, we step into the kernel.
            var info = RAWRS.codeListing.highlightedLine;
            RAWRS.codeListing.unhighlight();
            if (info && info.code == "ecall") {
                let address = (window.BigInt("0x" + info.address) + window.BigInt(4)).toString(16);
                RAWRS.simulator.breakpointSet(address)
                RAWRS._clearBreakpoint = address;
                RAWRS.simulator.resume();
            }
            else {
                RAWRS.simulator.step();
            }
        }
    }

    static assemble() {
        var text = window.editor.getValue();

        RAWRS.codeListing.clear();
        RAWRS.codeListing.source = text;

        RAWRS.registerListing.clear();

        RAWRS.memoryListing.clear();

        RAWRS.labelListing.clear();

        var linkerScript = "SECTIONS { . = 0x00400000; .text : { *(.text) } . = 0x10010000; .data : { *(.data) } }";

        // Destroy the current simulator
        RAWRS._simulator = null;
        RAWRS._clearBreakpoint = false;

        // Pass the files to a new debugger (when it is ready)
        this._gdb = new Debugger(this._debugConsole);
        this._gdb.on("ready", () => {
            this._gdb.mount([{
                name: "/input/foo.s",
                data: text
            }]);

            RAWRS._gdb.invoke("target remote /dev/serial");
        });

        this._gdb.on("step", () => {
            if (!this._gdb.simulator.done) {
                this.step();
            }
        });

        this._gdb.on("continue", () => {
            if (!this._gdb.simulator.done) {
                this.run();
            }
        });

        this._gdb.on("breakpoint-set", (address) => {
            this.codeListing.check(address);
            if (RAWRS.simulator) {
                RAWRS.simulator.breakpointSet(address);
            }
        });

        this._gdb.on("breakpoint-clear", (address) => {
            this.codeListing.uncheck(address);
            if (RAWRS.simulator) {
                RAWRS.simulator.breakpointClear(address);
            }
        });

        var assembler = new Assembler();
        var linker    = new Linker();
        var annotations = [];
        assembler.on('error', (error) => {
            RAWRS.toolbar.setStatus("assemble", "failure");
            error.type = 'error';
            annotations.push(error);
        });

        linker.on('error', (error) => {
            RAWRS.toolbar.setStatus("assemble", "failure");
            error.type = 'error';
            annotations.push(error);
        });

        var disassembler = new Disassembler();
        disassembler.on('instruction', (instruction) => {
            RAWRS.codeListing.add(instruction);
        });

        var data_dumper = new Dumper();
        data_dumper.on('update', (row) => {
            RAWRS.memoryListing.update(row.address, row.data);
        });

        var label_dumper = new Dumper();
        var label_array = [];
        label_dumper.on('update', (row) => {
            label_array.push(row);
        });

        label_dumper.on('done', (row) => {
            label_array.sort((a, b) => parseInt(a.address, 16) - parseInt(b.address, 16));
            label_array.forEach((element) => RAWRS.labelListing.update(element.label, element.address));
        });

        assembler.on('done', () => {
            window.editor.getSession().setAnnotations(annotations);
        });

        linker.on('done', () => {
            window.editor.getSession().setAnnotations(annotations);
            this._terminal.writeHeader("Running");
        });

        // Reset the console and video
        this._console.clear();
        this._video.reset();

        assembler.assemble("foo.s", text, this._terminal, (object) => {
            linker.link(linkerScript, object, this._terminal, (binary) => {
                RAWRS.toolbar.setStatus("assemble", "success");
                RAWRS.toolbar.setStatus("run", "");
                this._binary = binary;

                // On success, go to the run tab
                this._tabs.select('run-panel');

                // Also, disassemble the binary
                disassembler.disassemble(binary, this._terminal, () => {
                });

                // And dump its memory (data segment)
                data_dumper.dump(binary, "-x", ".data", this._terminal, () => {
                });
                
                // Then retrieve the labels (.symtab)
                label_dumper.dump(binary, "-s", "", this._terminal, () => {
                });

                // Run
                this.run();
            });
        });
    }
}

export default RAWRS;
