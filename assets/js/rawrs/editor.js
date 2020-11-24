"use strict";

class Editor {
    static initialize() {
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
        Editor._labelList = Editor.getAllLabels(editor);

        // Keeps track of the initial cursor position
        Editor._lastCursorPosition = window.editor.getCursorPosition();

        // Loads the Instructions tab
        Editor.loadInstructionsTab().then( () => {
            // Get the instruction listing
            Editor._instructionTable = document.getElementById("instruction-table");

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

                let commaCount = linePrefix.split(",").length - 1;

                // Get the last character on the line before the current word
                let lastCharacter = linePrefix[linePrefix.length - 1];

                // These hold the specific instructions that use labels
                // Each are defined by where in the argument listing the label appears
                let instructionsFirstArgument = ["j", "jal"];
                let instructionsSecondArgument = ["la", "bgez", "beqz", "bltz", "blez", "bgtz", "bnez", "jal"];
                let instructionsThirdArgument = ["beq", "bge", "bgeu", "bgt", "bgtu", "ble", "bleu", "blt", "bltu", "bne"];

                // isLabel will be true when the cursor is typing at a place
                // where a label would be expected
                let isLabel = instructionsFirstArgument.indexOf(instruction) >= 0;
                isLabel = isLabel || (instructionsSecondArgument.indexOf(instruction) >= 0 && lastCharacter == ",");
                isLabel = isLabel || (instructionsThirdArgument.indexOf(instruction) >= 0 && commaCount > 1 && lastCharacter == ",");

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

        // Inserts any new labels the user added when the cursor changes lines
        editor.session.selection.on('changeCursor', function(e) {
            // Checks if the cursor has changed lines
            if (Editor._lastCursorPosition.row !== editor.getCursorPosition().row) {
                // Gets the text from the last line the user was on
                let previousLineText = editor.session.getLine(Editor._lastCursorPosition.row);

                // Remove the existing label from this line (if any)
                if (Editor._currentLineText) {
                    Editor.removeLabelsFromString(Editor._currentLineText);
                }

                // Insert the label found on this line (if any)
                Editor.insertLabelsFromString(previousLineText);

                // Keep track of the current line
                Editor._currentLineText = editor.session.getLine(editor.getCursorPosition().row);
            }

            Editor._lastCursorPosition = editor.getCursorPosition();
        });
    }

    static load(text) {
        // -1 moves the cursor to the start (without this,
        // it will select the entire text... I dunno)
        window.editor.setValue(text, -1);
        window.editor.getSession().setUndoManager(new window.ace.UndoManager());

        // We want to re-populate with the known labels/globals in the given text
        Editor._labelList = Editor.getAllLabels(editor);

        // Keeps track of the initial cursor position
        Editor._lastCursorPosition = window.editor.getCursorPosition();
    }

    static focus() {
        window.editor.focus();
    }

    // Checks the entire document for labels and updates the global variable with this new list
    static updateAllLabels(editor) {
        let labelList = Editor.getAllLabels(editor);

        Editor._labelList = labelList;
    }

    // Takes a string, parses it to create a list of labels, then inserts them
    static insertLabelsFromString(textInput) {
        let newLabels = Editor.getLabelsFromText(textInput);

        for (let i = 0; i < newLabels.length; i++) {
            // Checks for duplicates, and if it is new, adds it to the global list
            if (!Editor._labelList.includes(newLabels[i])) {
                Editor._labelList.push(newLabels[i]);
            }
        }
    }

    static removeLabelsFromString(textInput) {
        let labels = Editor.getLabelsFromText(textInput);

        for (let i = 0; i < labels.length; i++) {
            if (Editor._labelList.includes(labels[i])) {
                // Removes the label from the global list
                Editor._labelList.splice(Editor._labelList.indexOf(labels[i]), 1);
            }
        }
    }

    // Returns an array of all labels
    static getAllLabels(editor) {
        let labelList = Editor.getLabelsFromText(editor.getValue());

        return labelList;
    }

    // Returns a list of all labels found in textInput
    static getLabelsFromText(textInput) {
        // Gets an array of all labels in the text 
        // TODO: Check to see whether or not something is in the data section
        // (maybe split the string that getValue() returns by ".data")
        let labelNames = textInput.match(/^\s*([a-zA-Z\d_]+):/gm);

        if (labelNames == null) {  // Prevents an error when labelNames is null
            labelNames = [];
        }

        let labelList = [];  // Contains the list of all labels with the ':' removed

        for (var i = 0; i < labelNames.length; i++) {
            let currentName = labelNames[i].replace(":", "").trim();  // Removes the colon in the string

            labelList.push(currentName);
        }

        return labelList;
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
                    if (instructionsTabPanel !== null && ((instructionsTabPanel.getAttribute("data-pjax") || "").indexOf("instructions") > 0)) {
                        // Check if the instructionsTab is PJAX loaded
                        if (!instructionsTabPanel.classList.contains("pjax-loaded")) {
                            var pjaxURL = instructionsTabPanel.getAttribute('data-pjax');
                            if (tabButton.parentNode.querySelector("a.ajax")) {
                                pjaxURL = tabButton.parentNode.querySelector("a.ajax").getAttribute('href');
                            }
                            if (pjaxURL) {
                                // Fetch HTML page and get content at "body.documentation"
                                instructionsTabPanel.classList.add("pjax-loaded");
                                fetch(pjaxURL, {
                                    credentials: 'include'
                                }).then(function(response) {
                                    return response.text();
                                }).then(function(text) {
                                    // Push text to dummy node
                                    let rootpath = document.body.getAttribute('data-rootpath');
                                    let basepath = document.body.getAttribute('data-basepath');
                                    text = text.replaceAll("\"../", "\"" + rootpath + basepath);

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
                });
            });
        });
    }

    /**
     * Gets the definition of an instruction and instruction name.
     */
    static getDefinitionFromTable(instruction) {
        if (!Editor._instructionTable) {
            return null;
        }

        let summary = Editor._instructionTable.querySelector('td.summary[data-instruction="' + instruction + '"]');

        if (!summary) {
            return null;
        }

        let name = Editor._instructionTable.querySelector('td.name[data-instruction="' + instruction + '"]');

        if (!name) {
            return null;
        }

        // Returns the string version of the description
        return name.innerText + "<br>" + summary.innerText;
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
