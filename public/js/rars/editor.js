"use strict";

class Editor {
    static load() {
        var editor = window.ace.edit("editor");
        window.editor = editor;
        editor.setTheme("ace/theme/monokai");
        editor.setShowPrintMargin(false);
        editor.session.setMode("ace/mode/assembly_riscv");
    }
}

export default Editor;
