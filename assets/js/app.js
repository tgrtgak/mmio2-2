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

RAWRS.load();

export default RAWRS;
