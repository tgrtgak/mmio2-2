"use strict";

import EventComponent from './event_component';

class Console extends EventComponent {
    constructor(selector, rows, cols, fontSize) {
        super();

        this._rows = rows;
        this._columns = cols;

        this._term = new window.XTerm({
          theme: {
            fontFamily: 'inconsolata'
          },
          fontFamily: 'inconsolata',
          cols: cols,
          rows: rows,
          cursorBlink:      true,     // Whether or not the cursor caret blinks
          cursorStyle:      "block",  // Cursor style: block, underline, or bar
          screenReaderMode: true,     // Enables screen-reader support
          tabStopWidth:     8,        // Default tab stop width (in spaces)
          convertEol:       true,     // Turn any '\n' into '\r\n'
        });

        this._term.open(document.querySelector(selector));
        this._term.resize(cols, rows);

        this._term.onKey( (event) => {
            // TODO: Convert printable key to appropriate scancode
            //       (will better support international keyboards)
            this.trigger('keydown', event.domEvent);
        });

        this._term.onData( (bytes) => {
            this.trigger('data', bytes);
        });

        this.clear();
    }

    get rows() {
        return this._rows;
    }

    get columns() {
        return this._columns;
    }

    clear() {
        this._term.write("\x1b[0;40;37m\x1b[2J\x1b[0;0H");
    }

    write(data) {
        this._term.write(data);
    }

    writeln(data) {
        this._term.write(data + "\n");
    }
}

export default Console;
