"use strict";

/**
 * Utility class for the test suite.
 */
class Helper {
    /**
     * Returns a random integer between min (inclusive) and max (exclusive).
     */
    static randomInteger(max, min) {
        max = Math.floor(max);
        min = Math.floor(min || 0);
        return Math.floor(Math.random() * (max - min)) + min;
    }

    /**
     * Returns a random alphanumeric string.
     */
    static randomString() {
        return Math.random().toString(36).substring(2, 15) +
               Math.random().toString(36).substring(2, 15);
    }

    /**
     * Dispatches a keyboard event.
     */
    static dispatchKeyEvent(eventName, to, options = {}) {
        let event = new KeyboardEvent(eventName, Object.assign({
            view: window,
            bubbles: true,
            cancelable: true
        }, options));
        to.dispatchEvent(event);
    }

    /**
     * Dispatches a mouse event.
     */
    static dispatchMouseEvent(eventName, to, options = {}) {
        let event = new MouseEvent(eventName, Object.assign({
            view: window,
            bubbles: true,
            cancelable: true
        }, options));
        to.dispatchEvent(event);
    }

    static getAllFuncs(toCheck) {
        var props = [];
        var obj = toCheck;
        do {
            props = props.concat(Object.getOwnPropertyNames(obj));
        } while (obj = Object.getPrototypeOf(obj));

        return props.sort().filter(function(e, i, arr) { 
            if (e!=arr[i+1] && typeof toCheck.prototype[e] == 'function') return true;
        });
    }
}

Helper.VisibilityMatchers = {
    toBeVisible: (util, customEqualityTesters) => {
        return {
            compare: (element, _) => {
                let result = {};
                result.pass = element.offsetWidth > 0 && element.offsetHeight > 0;

                return result;
            }
        };
    },

    toBeHidden: (util, customEqualityTesters) => {
        return {
            compare: (element, _) => {
                let result = {};
                result.pass = element.offsetWidth <= 0 || element.offsetHeight <= 0 || element.hasAttribute('hidden');

                return result;
            }
        };
    }
};

export default Helper;
