"use strict";

import EventComponent      from './event_component';
import Simulator           from './simulator';
import Dropdown            from './dropdown';
import FloatExplorerDialog from './float_explorer_dialog';

class RegisterListing extends EventComponent {
    /**
     * Create a new instance of a register listing for the given root element.
     *
     * @param {HTMLElement} root The element to look for the register listing within.
     */
    constructor(root) {
        super();

        let element = root.querySelector(".register-file");
        this._element = element;

        this.bindEvents();

        this.clear();
    }

    /**
     * Returns the element associated with this register listing.
     *
     * @returns {HTMLElement} The element for this register listing.
     */
    get element() {
        return this._element;
    }

    /**
     * Resets the register listing to all zeros.
     */
    clear() {
        Simulator.ALL_REGISTER_NAMES.forEach( (regName) => {
            let str = "0000000000000000";
            let row = this._element.querySelector("tr." + regName);
            row.setAttribute("data-hex-value", "0x" + str);
            row.querySelector("td.value button").textContent = "0x" + str;
            this.switchToHex(row);
        });
    }

    /**
     * Removes highlights on updated entries.
     */
    unhighlight() {
        Simulator.ALL_REGISTER_NAMES.forEach( (regName) => {
            this._element.querySelector("tr." + regName + " td.value").parentNode.classList.remove("updated");
        });
    }

    /**
     * Updates the register listing for the provided register values.
     *
     * @param {BigUint64Array} regs The register values.
     */
    update(regs) {
        regs.forEach( (reg, i) => {
            // Get the hex value of the register value padded to 16 digits
            let str = reg.toString(16).padStart(16, '0');

            // Get the register name and the element that represents it.
            let regName = Simulator.ALL_REGISTER_NAMES[i];
            let row = this._element.querySelector("tr." + regName);
            let element = row.querySelector("td.value");
            if (element) {
                // Determine what the value should be encoded as
                let typeCell = row.querySelector("td.type");
                let type = (typeCell ? typeCell.textContent : "x");

                // Determine the new value and if the value has changed
                let oldContent = row.getAttribute("data-hex-value");
                let newContent = "0x" + str;
                row.setAttribute("data-hex-value", newContent);

                // Conform to hex to start
                this.switchToHex(row);

                if (oldContent != newContent) {
                    row.classList.add("updated");
                }

                // Re-encode to the requested type
                if (type == "f") {
                    this.switchToFloat(row);
                }
                else if (type == "d") {
                    this.switchToDouble(row);
                }
            }
        });
    }

    /**
     * Retrieves all registers as 64-bit unsigned integers.
     */
    get registers() {
        let ret = new BigUint64Array(68);
        let tableCells = this._element.querySelectorAll("td.value");
        tableCells.forEach( (td, i) => {
            let registerName = td.previousElementSibling.textContent;
            let realIndex = Simulator.ALL_REGISTER_NAMES.indexOf(registerName);
            ret[realIndex] = BigInt(td.parentNode.getAttribute("data-hex-value"));
        });
        return ret;
    }

    selectInput(val_td) {
        val_td.setAttribute('hidden', '');
        val_td.nextElementSibling.removeAttribute('hidden');
        let input = val_td.nextElementSibling.querySelector('input');
        input.focus();
        input.value = val_td.firstElementChild.textContent;
        input.select();
    }

    submitInput(input) {
        let valid = true; 
        try {
            // TODO: interpret float/double when in that mode
            // Make sure that input.value can be interpreted as a BigInt
            BigInt(input.value);
        }
        catch(err) {
            valid = false;
        }
        finally {
            let td = input.parentNode;
            td.setAttribute('hidden', '');
            td.previousElementSibling.removeAttribute('hidden');
            if (valid) {
                let hexValue = "0x" + BigInt.asUintN(64, BigInt(input.value)).toString(16).padStart(16, '0');
                td.parentNode.setAttribute("data-hex-value", hexValue);
                td.previousElementSibling.firstElementChild.textContent = hexValue;
            }
            this.trigger('change');
        }
    }

    switchToHex(row) {
        let typeCell = row.querySelector("td.type");
        if (typeCell) {
            typeCell.textContent = "x";
        }

        let dataButton = row.querySelector("td.value button");

        if (!row.hasAttribute("data-hex-value")) {
            row.setAttribute("data-hex-value", dataButton.textContent);
        }

        dataButton.textContent = row.getAttribute("data-hex-value");

        // Enable all dropdown entries
        row.querySelectorAll("button[data-action^=\"as-\"]").forEach( (item) => {
            item.removeAttribute("disabled");
        });

        // Disable as-hex
        let asHexItem = row.querySelector("button[data-action=\"as-hex\"]");
        if (asHexItem) {
            asHexItem.setAttribute("disabled", "");
        }
    }

    switchToFloat(row) {
        // Switch to Hex first
        this.switchToHex(row);

        // Now switch to float
        let typeCell = row.querySelector("td.type");
        typeCell.textContent = "f";

        let value = BigInt(row.getAttribute("data-hex-value"));
        let buffer = new Uint8Array(8);
        let view = new DataView(buffer.buffer);
        view.setBigUint64(0, value);
        value = view.getFloat32(4).toString();
        if (value.indexOf(".") == -1 && value != "NaN") {
            value = value + ".0";
        }

        let dataButton = row.querySelector("td.value button");
        dataButton.textContent = value;

        // Enable all dropdown entries
        row.querySelectorAll("button[data-action^=\"as-\"]").forEach( (item) => {
            item.removeAttribute("disabled");
        });

        // Disable as-float
        row.querySelector("button[data-action=\"as-float\"]").setAttribute("disabled", "");
    }

    switchToDouble(row) {
        // Switch to Hex first
        this.switchToHex(row);

        // Now switch to double
        let typeCell = row.querySelector("td.type");
        typeCell.textContent = "d";

        let value = BigInt(row.getAttribute("data-hex-value"));
        let buffer = new Uint8Array(8);
        let view = new DataView(buffer.buffer);
        view.setBigUint64(0, value);
        value = view.getFloat64(0).toString();
        if (value.indexOf(".") == -1 && value != "NaN") {
            value = value + ".0";
        }

        let dataButton = row.querySelector("td.value button");
        dataButton.textContent = value;

        // Enable all dropdown entries
        row.querySelectorAll("button[data-action^=\"as-\"]").forEach( (item) => {
            item.removeAttribute("disabled");
        });

        // Disable as-double
        row.querySelector("button[data-action=\"as-double\"]").setAttribute("disabled", "");
    }

    bindEvents() {
        let tableCells = this._element.querySelectorAll("td.value");
        tableCells.forEach( (td) => {
            td.firstElementChild.addEventListener("click", this.selectInput.bind(this, td));

            // Bind dropdown events
            let actionButton = td.parentNode.querySelector("button.actions");
            if (actionButton) {
                // Create the dropdown menu
                let dropdown = new Dropdown(actionButton);

                dropdown.on('click', (event) => {
                    if (event == "as-hex") {
                        this.switchToHex(td.parentNode);
                    }
                    else if (event == "as-float") {
                        this.switchToFloat(td.parentNode);
                    }
                    else if (event == "as-double") {
                        this.switchToDouble(td.parentNode);
                    }
                    else if (event == "explore") {
                        let floatExplorer = new FloatExplorerDialog();
                        floatExplorer.update(BigInt(td.parentNode.getAttribute('data-hex-value')));

                        let typeCell = td.parentNode.querySelector("td.type");
                        if (typeCell && typeCell.textContent == "f") {
                            floatExplorer.view32();
                        }
                        else if (typeCell && typeCell.textContent == "d") {
                            floatExplorer.view64();
                        }
                    }
                });
            }
        });

        let inputCells = this._element.querySelectorAll("td.edit input");
        inputCells.forEach( (input) => {
            input.addEventListener("blur", this.submitInput.bind(this, input));
            input.addEventListener("keydown", (keyEvent) => {
                if(keyEvent.key === "Enter") {
                    this.submitInput(input);
                }
            });
        });
    }
}

export default RegisterListing;
