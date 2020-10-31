"use strict";

class Editor {
    static load() {
        // Create an Ace Editor instance
        var editor = window.ace.edit("editor");
        window.editor = editor;

        // Set theme
        editor.setTheme("ace/theme/monokai");

        // Add the margins
        editor.setShowPrintMargin(false);

        // Enable autocomplete
        editor.setOptions({
            enableBasicAutocompletion: true,
            enableLiveAutocompletion: true,
        });

        // Set the 'mode' for highlighting
        editor.session.setMode("ace/mode/assembly_riscv");

        // We want to populate these with the instruction documentation
        Editor._instructionTable = {};
        Editor._instructionsList = [];

        // We want to populate these with the known labels/globals
        // TODO: keep track of or parse the labels in the current file.
        Editor._labelList = ["_testLabel", "_fooLabel"];

        // Loads the Instructions tab
        Editor.loadInstructionsTab().then( () => {
            // Get the instruction listing
            Editor._instructionTable = document.getElementById("instruction-table-p").nextElementSibling;

            for (const row of Editor._instructionTable.rows) {
                let dict = {};
                dict["name"] = row.cells[0].innerText;
                dict["value"] = row.cells[0].innerText;
                dict["score"] = 100;
                dict["meta"] = 'instruction';
                Editor._instructionsList.push(dict);
            };
        });

        // Assign the completer
        var langTools = window.ace.require("ace/ext/language_tools");
        let completer = {
            getCompletions: (editor, session, pos, prefix, callback) => {
                // Based on the context, we should either show the instructions
                // listing or the label listing.
                let line = session.getLine(pos.row);
                let linePrefix = line.substring(0, pos.column - prefix.length).trim();

                // Get the first word on the line and assume it is an instruction
                let instruction = linePrefix.split(" ")[0];

                // Get the last character on the line before the current word
                let lastCharacter = linePrefix[linePrefix.length - 1];

                // Determine if it should be a label
                let instructions = ["la", "bge"];
                let isLabel = (instructions.indexOf(instruction) >= 0 && lastCharacter == ",");

                if (isLabel) {
                    // Return a list of relevant labels
                    callback(null, Editor._labelList.map( (label) => {
                        return {
                            name: label,
                            value: label,
                            score: 100,
                            meta: 'label'
                        };
                    }));
                }
                else if (!instruction) {
                    // Return a list of relevant instructions
                    callback(null, Editor._instructionsList);
                }
            },
            getDocTooltip: (item) => {
                let result = Editor.getDefinitionFromTable(item.name);

                if (result !== null) {
                    item.docHTML = "<code>" + item.name + "</code>: " + result;  // Adjusts the formatting of the output
                }
            }
        };

        // Set the completer to our completer
        editor.completers = [completer];

        // Now, we look at supporting instruction 'popovers'
        // Hook into the mousemove event to track the mouse position:
        editor.on("mousemove", (event) => {
            // Get the position within the document
            var pos = event.getDocumentPosition();

            // Get the word at this position
            var wordRange = editor.session.getWordRange(pos.row, pos.column);
            var word = editor.session.getTextRange(wordRange);

            // Get word screen position (relative to top-left of editor)
            var point = editor.renderer.$cursorLayer.getPixelPosition(
                wordRange.start, false // Ace does not seem to use this boolean.
            );                         // We will keep it false just in case.

            // Get editor position
            let editorNode = document.querySelector("pre.ace_editor");
            let editorBounds = editorNode.getBoundingClientRect();
            let left = point.left + editorBounds.x;
            let top = point.top + editorBounds.y;

            // We need to account for the gutter
            left += editor.renderer.gutterWidth;

            // We need to account for the editor scroll
            top -= editor.renderer.scrollTop;

            // If the word is an instruction (and not within a comment) then
            // popover the help text.
            // TODO: Add a check before this to determine if this is within a comment.
            let docHTML = Editor.getDefinitionFromTable(word);

            if (docHTML !== null) {
                docHTML = "<code>" + word + "</code>: " + docHTML;  // Adjusts the formatting of the output
                Editor.showTooltip(docHTML, left, top);
            }
            else {
                Editor.hideTooltip();
            }
        });
    }

    /**
     * Ensures the instructions tab is loaded.
     *
     * This tab contains the documentation for each instruction. This is parsed
     * and used for auto-complete and popover hints on the editor.
     *
     * Acts as a promise that resolves when the tab is loaded.
     */
    static loadInstructionsTab() {
        return new Promise( (resolve, reject) => {
            document.querySelectorAll(".tabs").forEach( (tabStrip) => {
                tabStrip.querySelectorAll(".tab > a, .tab > button").forEach( (tabButton) => {
                    var instructionsTabPanel = document.querySelector(".tab-panel#" + tabButton.getAttribute('aria-controls'));
                    if (instructionsTabPanel != null && instructionsTabPanel.getAttribute("data-pjax") === "guidance/instructions") {
                        if (instructionsTabPanel) {

                            // Check if the instructionsTab is PJAX loaded
                            if (!instructionsTabPanel.classList.contains("pjax-loaded")) {
                                var pjaxURL = instructionsTabPanel.getAttribute('data-pjax');
                                if (pjaxURL) {
                                    // Fetch HTML page and get content at "body.documentation"
                                    instructionsTabPanel.classList.add("pjax-loaded");
                                    fetch(pjaxURL, {
                                        credentials: 'include'
                                    }).then(function(response) {
                                        return response.text();
                                    }).then(function(text) {
                                        // Push text to dummy node
                                        var dummy = document.createElement("div");
                                        dummy.setAttribute('hidden', '');
                                        dummy.innerHTML = text;
                                        document.body.appendChild(dummy);
                                        var innerElement = dummy.querySelector(".content.documentation");
                                        instructionsTabPanel.innerHTML = "";
                                        instructionsTabPanel.appendChild(innerElement);
                                        dummy.remove();

                                        resolve();
                                    });
                                }
                            }
                        }
                    }
                });
            });
        });
    }

    /**
     * Gets the definition of an instruction and instruction name.
     */
    static getDefinitionFromTable(instruction) {
        var myXPath = ".//td[text()='" + instruction + "']";  // Builds the XPath
        var leftCell = document.evaluate(myXPath, Editor._instructionTable, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;  // Gets the cell containing the instruction

        if (leftCell === null) {
            return null;
        }

        return leftCell.nextElementSibling.innerText;  // Returns the string version of the description
    }

    static hideTooltip() {
        let tooltipNode = Editor.tooltipNode;
        Editor.tooltipNode = null;
        if (tooltipNode && tooltipNode.parentNode) {
            tooltipNode.parentNode.removeChild(tooltipNode);
        }
    }

    static showTooltip(html, x, y) {
        if (!Editor.tooltipNode) {
            // Create a tooltip element
            Editor.tooltipNode = document.createElement("div");
            Editor.tooltipNode.classList.add("ace_tooltip");
            Editor.tooltipNode.classList.add("ace_doc-tooltip");
            Editor.tooltipNode.style.margin = 0;
            Editor.tooltipNode.style.pointerEvents = "none";
            Editor.tooltipNode.tabIndex = -1;
        }

        let tooltipNode = Editor.tooltipNode;
        tooltipNode.innerHTML = html;

        if (!tooltipNode.parentNode) {
            document.body.appendChild(tooltipNode);
        }

        // Position the node
        tooltipNode.style.bottom = (window.innerHeight - y) + 'px';
        tooltipNode.style.left = x + 'px';

        // Display the node
        tooltipNode.style.display = "block";
    }
}

export default Editor;
