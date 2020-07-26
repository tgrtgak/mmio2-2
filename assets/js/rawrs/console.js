"use strict";

import EventComponent from './event_component';

class Console extends EventComponent {
    constructor(rows, cols, fontSize) {
        super();

        this._term = new window.XTerm({
          cols: cols,
          rows: rows,
          cursorBlink:      true,     // Whether or not the cursor caret blinks
          cursorStyle:      "block",  // Cursor style: block, underline, or bar
          screenReaderMode: true,     // Enables screen-reader support
          tabStopWidth:     8,        // Default tab stop width (in spaces)
          convertEol:       true,     // Turn any '\n' into '\r\n'
        });

        this._term.open(document.getElementById("term_container"));
        this._term.resize(cols, rows);

        this._term.onKey( (event) => {
            // TODO: Convert printable key to appropriate scancode
            //       (will better support international keyboards)
            this.trigger('keydown', event.domEvent);
        });

        // TinyEMU looks for this:
        window.term = {
            write: (x) => {
                this._term.write(x);
            },
            getSize: (x) => {
                return [cols, rows];
            }
        };
    }

    clear() {
        this._term.write("\x1b[0;40;37m\x1b[2J\x1b[0;0H");
    }
}

export default Console;
