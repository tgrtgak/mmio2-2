"use strict";

import EventComponent from './event_component';

class Console extends EventComponent {
    constructor(rows, cols, fontSize) {
        super();

        let term_handler = (str) => {
        };

        this._term = new window.Term(cols, rows, term_handler, 10000);
        this._term.open(document.getElementById("term_container"),
                        document.getElementById("term_paste"));
        this._term.term_el.style.fontSize = fontSize + "px";

        this._term.content_el.addEventListener('keydown', (event) => {
            this.trigger('keydown', event);
        });

        this._term.content_el.addEventListener('keyup', (event) => {
            this.trigger('keyup', event);
        });

        window.term = this._term;
    }

    clear() {
        this._term.write("\x1b[0;40;37m\x1b[2J\x1b[0;0H");
    }
}

export default Console;
