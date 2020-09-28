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

        // Assign the completer
        var langTools = window.ace.require("ace/ext/language_tools");
        let completer = {
            getCompletions: function(editor, session, pos, prefix, callback) {
                // Return a list of relevant instructions
                callback(null, [
                    {name: 'ecall', value: 'ecall', score: 100, meta: 'instruction'},
                    {name: 'li', value: 'li', score: 100, meta: 'instruction'},
                    {name: 'la', value: 'la', score: 100, meta: 'instruction'},
                ])
            },
            getDocTooltip: function(item) {
                if (item.name === "li") {
                    item.docHTML = "<code>li</code>: Load Immediate"
                }
                else if (item.name === "la") {
                    item.docHTML = "<code>la</code>: Load Address"
                }
                else if (item.name === "ecall") {
                    item.docHTML = "<code>ecall</code>: Environment Call"
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

            // If the word is an instruction (and not within a comment) then
            // popover the help text.
            let docHTML = null;
            if (word === "li") {
                docHTML = "<code>li</code>: Load Immediate"
            }
            else if (word === "la") {
                docHTML = "<code>la</code>: Load Address"
            }
            else if (word === "ecall") {
                docHTML = "<code>ecall</code>: Environment Call"
            }

            if (docHTML) {
                Editor.showTooltip(docHTML, left, top);
            }
            else {
                Editor.hideTooltip();
            }
        });
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
