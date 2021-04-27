"use strict";

import Tabs from './tabs';
import Dialog from './dialog';

class FloatExplorerDialog extends Dialog {
    constructor() {
        // Wrap the dialog
        super('dialog-float-explorer');

        // Show the dialog
        this.open();

        // Find the float explorer dialog tabs
        this._tabs = Tabs.load(this.dialog.querySelector("ol.tabs"));

        // Bind the events for the float explorer
        this.bindEvents();

        // Ensure the calculated and error fields never grow out of their boxes
        let width = this.dialog.querySelector("li.active p.calculated-value").offsetWidth;
        this.dialog.querySelectorAll("p.calculated-value, p.error-value").forEach( (p) => {
            p.style.width = width + "px";
        });
    }

    /**
     * Updates the floating point explorer with the given 64-bit BigInt value.
     *
     * The 32-bit floating point value is constructed using the lower 32 bits.
     *
     * @param {BigInt} value - The 64-bit value to use.
     * @param {number} bits - The table to update (32, 64, default: all)
     */
    update(value, bits) {
        let binary = BigInt.asUintN(64, value).toString(2).padStart(64, '0');
        let table = this.dialog;

        // Filter to just the given table
        if (bits) {
            table = table.querySelector("table.float-" + bits);
        }

        // Update the 64-bit and 32-bit table cells.
        for (let i = 0; i < 64; i++) {
            let b = binary[63 - i];

            let inputs = table.querySelectorAll("td[data-bit-index=\"" + i + "\"] input");
            inputs.forEach( (input) => {
                input.checked = b == '1';
            });
        }

        this.calculate(bits);
    }

    /**
     * Switches to the 32-bit representation tab.
     */
    view32() {
        this._tabs.select("float-explorer-32-panel");
    }

    /**
     * Switches to the 32-bit representation tab.
     */
    view64() {
        this._tabs.select("float-explorer-64-panel");
    }

    fixedToString(value) {
        let negative = false;
        value = value.toString();
        if (value[0] == '-') {
            value = value.slice(1);
            negative = true;
        }

        // Pad to at least our precision requirement
        // This will ensure that we have an integer part and a full fractional
        value = value.padStart(FloatExplorerDialog.FIXED_PRECISION, '0');

        // Get the integer portion of the string
        let intDigits = value.length - FloatExplorerDialog.FIXED_PRECISION + 1;
        let intPart = value.substring(0, intDigits) || '0';

        // Get the fractional remaining part of the string
        let fracPart = value.substring(intDigits).replace(/0+$/, '') || '0';

        // Construct the string with the appropriate joiner
        // TODO: handle locale
        value = intPart + '.' + fracPart;

        // Return the value prepended with a '-' if negative
        return (negative ? '-' : '') + value;
    }

    /**
     * Updates the sections according to the value encoded in the bits.
     *
     * @param {number} bits - The section to calculate. (32, 64, default: all)
     */
    calculate(bits) {
        let selector = "table";

        if (bits) {
            selector += ".float-" + bits;
        }

        this.dialog.querySelectorAll(selector).forEach( (table) => {
            // Which are we on?
            let is32 = table.classList.contains("float-32");

            let value = BigInt(0);

            // Get the sign bit
            let sign = table.querySelector("td.sign input").checked;
            let signField = table.parentNode.querySelector(".calculation span.sign");

            if (sign) {
                signField.textContent = "-1";
                value = BigInt(1);
            }
            else {
                signField.textContent = "1";
            }

            // Get exponent
            let exponent = 0;
            table.querySelectorAll("td.exponent input").forEach( (input) => {
                value = value << BigInt(1);
                exponent = exponent << 1;
                value = value | BigInt(input.checked ? 1 : 0);
                exponent |= (input.checked ? 1 : 0);
            });

            let exponentField = table.parentNode.querySelector(".calculation span.exponent");
            exponentField.textContent = exponent.toString();

            // Determine if it is normalized/denormalized
            if (exponent == 0) {
                // Show the calculation as de-normalized
                table.parentNode.querySelectorAll(".normalized").forEach( (el) => {
                    el.setAttribute('hidden', '');
                    el.setAttribute('aria-hidden', 'true');
                });
                table.parentNode.querySelectorAll(".denormalized").forEach( (el) => {
                    el.removeAttribute('hidden');
                    el.setAttribute('aria-hidden', 'false');
                });
                table.parentNode.querySelector(".calculation span.leading").textContent = "0."
            }
            else {
                // Show the calculation as normalized
                table.parentNode.querySelectorAll(".normalized").forEach( (el) => {
                    el.removeAttribute('hidden');
                    el.setAttribute('aria-hidden', 'false');
                });
                table.parentNode.querySelectorAll(".denormalized").forEach( (el) => {
                    el.setAttribute('hidden', '');
                    el.setAttribute('aria-hidden', 'true');
                });
                table.parentNode.querySelector(".calculation span.leading").textContent = "1."
            }

            // Get the calculated exponent
            let bias = parseInt(table.parentNode.querySelector(".calculation span.bias").textContent);
            let actualExponent = exponent - bias;
            let scalar = BigInt("1".padEnd(FloatExplorerDialog.FIXED_PRECISION, '0'));

            if (actualExponent <= 0) {
                for (let i = actualExponent; i < 0; i++) {
                    scalar /= BigInt(2);
                }
            }
            else {
                for (let i = actualExponent; i > 0; i--) {
                    scalar *= BigInt(2);
                }
            }

            // Get mantissa
            let mantissa = BigInt("1".padEnd(FloatExplorerDialog.FIXED_PRECISION, '0'));
            let considering = BigInt("1".padEnd(FloatExplorerDialog.FIXED_PRECISION, '0'));
            table.querySelectorAll("td.mantissa input").forEach( (input) => {
                value = value << BigInt(1);
                considering /= BigInt(2);
                if (input.checked) {
                    mantissa += considering;
                    value = value | BigInt(1);
                }
            });

            // Set the mantissa to this calculated value
            let mantissaField = table.parentNode.querySelector(".calculation span.mantissa");
            mantissaField.textContent = mantissa.toString().replace(/0+$/, '').slice(1) || "0";

            // Now, alter the mantissa for the final calculation
            if (exponent == 0) {
                // If denormalized, we remove the implicit 1
                mantissa -= BigInt("1".padEnd(FloatExplorerDialog.FIXED_PRECISION, '0'));

                // And we also multiply by 2
                mantissa *= BigInt(2);
            }

            // Calculate the actual value (as a big integer fixed value)
            let calculated = mantissa * scalar / BigInt("1".padEnd(FloatExplorerDialog.FIXED_PRECISION, '0'));
            if (sign) {
                calculated *= BigInt(-1);
            }

            // Update hex value
            let hexValue = table.parentNode.querySelector("input.hex-value");
            hexValue.setAttribute('value', "0x" + value.toString(16).padStart(is32 ? 8 : 16, '0'));

            // Update actual value
            let actualValue = table.parentNode.querySelector("p.calculated-value");
            let decimalValue = table.parentNode.querySelector("input.entered-value");
            let buffer = new Uint8Array(16);
            let view = new DataView(buffer.buffer);
            view.setBigUint64(0, value);
            let floatValue = (is32 ? view.getFloat32(4) : view.getFloat64(0));

            actualValue.textContent = this.fixedToString(calculated);

            if (isNaN(floatValue)) {
                actualValue.textContent = "NaN";
            }

            if (floatValue == Infinity) {
                actualValue.textContent = "Infinity";
            }

            if (floatValue == -Infinity) {
                actualValue.textContent = "-Infinity";
            }

            if (!decimalValue.hasAttribute('data-entered')) {
                decimalValue.setAttribute('value', floatValue.toString());
                decimalValue.value = floatValue.toString();
            }

            let errorValue = table.parentNode.querySelector("p.error-value");
            errorValue.textContent = "0";

            if (decimalValue.hasAttribute('data-entered')) {
                // Calculate actual error value by reinterpreting the entered
                // value as a BigInt multiplied by 10^(precision - 1).
                let parts = decimalValue.getAttribute('data-entered').split('.');
                let intPart = parts[0]
                let fracPart = parts[1].padEnd(FloatExplorerDialog.FIXED_PRECISION - 1, '0');
                let entered = BigInt(intPart + fracPart);

                // We can calculate the error by subtracting it from the
                // calculated value.
                let error = entered - calculated;
                if (error < 0) {
                    error = error * BigInt(-1);
                }
                errorValue.textContent = this.fixedToString(error);
            }
        });
    }

    /**
     * Interprets the given input field's string.
     *
     * @param {HTMLInputElement} input - <input> element within the dialog to parse.
     */
    interpretEnteredValue(input) {
        input.setAttribute('data-entered', input.value);
        let floatValue = parseFloat(input.value)
        let buffer = new Uint8Array(16);
        let view = new DataView(buffer.buffer);
        let table = input.parentNode.querySelector("table");
        let is32 = table.classList.contains("float-32");
        if (is32) {
            view.setFloat32(4, floatValue);
        }
        else {
            view.setFloat64(0, floatValue);
        }
        let value = view.getBigUint64(0);
        this.update(value, is32 ? 32 : 64);
        input.removeAttribute('data-entered');
    }

    bindEvents() {
        // Bail if this was called before
        if (this.dialog.classList.contains("bound")) {
            return;
        }

        // Do not allow the events to be bound twice
        this.dialog.classList.add("bound");

        // Bind to the bit checkboxes
        this.dialog.querySelectorAll("table td label input").forEach( (cell) => {
            cell.addEventListener('change', (event) => {
                this.calculate();
            });
        });

        this.dialog.querySelectorAll("input.entered-value").forEach( (input) => {
            input.addEventListener('change', (event) => {
                this.interpretEnteredValue(input);
            });

            input.addEventListener('input', (event) => {
                this.interpretEnteredValue(input);
            });
        });
    }
}

FloatExplorerDialog.FIXED_PRECISION = 320;

export default FloatExplorerDialog;
