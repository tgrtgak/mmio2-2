"use strict";

import Tabs            from './tabs';
import Editor          from './editor';
import Toolbar         from './toolbar';
import Simulator       from './simulator';
import Assembler       from './assembler';
import Linker          from './linker';
import Disassembler    from './disassembler';
import Terminal        from './terminal';
import FileList        from './file_list';
import CodeListing     from './code_listing';
import RegisterListing from './register_listing';

class RARS {
    static load() {
        Tabs.load();
        Editor.load();
        RARS.toolbar  = new Toolbar(document.body);
        RARS.fileList = new FileList(document.body);
        RARS.fileList.loadItem(RARS.fileList.startupItem);
        RARS.codeListing = new CodeListing(document.body);
        RARS.registerListing = new RegisterListing(document.body);

        RARS.toolbar.on('click', (button) => {
            switch (button.getAttribute("id")) {
                case "assemble":
                    this.assemble();
                    break;
                default:
                    // Unknown button
                    break;
            }
        });
    }

    static assemble() {
        var text = window.editor.getValue();
        var terminal = new Terminal(document.body);

        RARS.codeListing.clear();
        RARS.codeListing.source = text;

        var linkerScript = "SECTIONS { . = 0x10000000; .text : { *(.text) } . = 0x40000000; .data : { *(.data) } }";

        var assembler = new Assembler();
        var annotations = [];
        assembler.on('error', (error) => {
            error.type = 'error';
            annotations.push(error);
        });

        var disassembler = new Disassembler();
        disassembler.on('instruction', (instruction) => {
            RARS.codeListing.add(instruction);
        });

        assembler.on('done', () => {
            window.editor.getSession().setAnnotations(annotations);
        });

        window.term.write("\x1b[0;40;37m\x1b[2J\x1b[0;0H");
        assembler.assemble("foo.s", text, terminal, (object) => {
            Linker.link(linkerScript, object, terminal, (binary) => {
                // On success, go to the run tab
                var runTab = document.body.querySelector("button[aria-controls=\"run-panel\"]");
                if (runTab) {
                    var strip = runTab.parentNode.parentNode;
                    strip.querySelectorAll(":scope > li.tab").forEach( (tab) => tab.classList.remove('active') );
                    runTab.parentNode.classList.add("active");

                    var tabPanels = strip.nextElementSibling;
                    if (tabPanels) {
                        tabPanels.querySelectorAll(":scope > .tab-panel").forEach( (tabPanel) => {
                            tabPanel.classList.remove("active");
                        });
                    }

                    var tabPanel = document.querySelector(".tab-panel#run-panel");
                    if (tabPanel) {
                        tabPanel.classList.add("active");
                    }
                }

                // Start the simulation
                let sim = new Simulator(32, "basic-riscv64.cfg", "kernel/kernel.bin", binary);
                sim.on("quit", () => {
                    RARS.registerListing.update(sim.registers);
                });

                sim.run();

                // Also, disassemble the binary
                disassembler.disassemble(binary, terminal, () => {
                });
            });
        });
    }
}

export default RARS;
