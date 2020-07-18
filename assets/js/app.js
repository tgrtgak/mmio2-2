"use strict";

import bigInt from 'big-integer';
import 'element-qsa-scope';

// Use big-integer to polyfill our use of BigInt
if (!window.BigInt) {
    window.BigInt = bigInt;
}

// Polyfill the simple usecase of BigUint64Array
// We really only use it as a container... hmm.
if (!window.BigUint64Array) {
    window.BigUint64Array = function(values) {
        this.values = values;
    };

    window.BigUint64Array.prototype.forEach = function(callback) {
        return this.values.forEach(callback);
    };
}

import RAWRS from './rawrs/rawrs';

let cols = 80;
let rows = 30;
let term_handler = (str) => {
};
let font_size = 15;

window.term = new window.Term(cols, rows, term_handler, 10000);
window.term.open(document.getElementById("term_container"),
          document.getElementById("term_paste"));
window.term.term_el.style.fontSize = font_size + "px";

RAWRS.load();

export default RAWRS;
