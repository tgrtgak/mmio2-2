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


        // Loads the Instructions tab
        Editor.loadInstructionsTab();


        // Assign the completer
        var langTools = window.ace.require("ace/ext/language_tools");
        let completer = {
            getCompletions: function(editor, session, pos, prefix, callback) {
                
                let commandsTable = Editor.getCommandsTable();

                let instructionsList = [];

                for (var i = 0, row; i < commandsTable.rows.length; i++) {
                    row = commandsTable.rows[i];
                    let dict = {};
                    dict["name"] = row.cells[0].innerText;
                    dict["value"] = row.cells[0].innerText;
                    dict["score"] = 100;
                    dict["meta"] = 'instruction';
                    instructionsList.push(dict);
                }

                // Return a list of relevant instructions
                callback(null, instructionsList);
            },
            getDocTooltip: function(item) {
                // Gets the table with the list of commands 
                let commandsTable = Editor.getCommandsTable();

                let result = Editor.getDefinitionFromTable(commandsTable, item.name);

                if (result !== null) {
                    item.docHTML = "<code>" + item.name + "</code>: " + result;  // Adjusts the formatting of the output
                }
            }
        };

        // Set the completer to our completer
        editor.completers = [completer];



        // Now, we look at supporting instruction 'popovers'
        // Hook into the mousemove event to track the mouse position:
        editor.on("mousemove", function(event) {
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

            // Gets the table with the list of commands 
            let commandsTable = Editor.getCommandsTable();

            // If the word is an instruction (and not within a comment) then
            // popover the help text.
            // TODO: Add a check before this to determine if this is within a comment.
            let docHTML = Editor.getDefinitionFromTable(commandsTable, word);

            if (docHTML !== null) {
                docHTML = "<code>" + word + "</code>: " + docHTML;  // Adjusts the formatting of the output
                Editor.showTooltip(docHTML, left, top);
            }
            else {
                Editor.hideTooltip();
            }
        });
    }

    static loadInstructionsTab() {
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
                                });
                            }
                        }
                    }
                }
            });
        });
    }

    // Gets the table with commands from the Instructions tab
    static getCommandsTable() {
        return document.getElementById("instruction-table-p").nextElementSibling;
    }

    // Gets the definition of a command given the table and name of the command    
    static getDefinitionFromTable(commandsTable, word) {

        var myXPath = ".//td[text()='" + word + "']";  // Builds the XPath
        var leftCell = document.evaluate(myXPath, commandsTable, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;  // Gets the cell containing the instruction

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
