"use strict";

import EventComponent from './event_component';
import Simulator      from './simulator';

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
            this._element.querySelector("tr." + regName + " td.value button").textContent = "0x" + str;
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
            let str = reg.toString(16);
            str = "0000000000000000".slice(str.length) + str;

            // Get the register name and the element that represents it.
            let regName = Simulator.ALL_REGISTER_NAMES[i];
            let element = this._element.querySelector("tr." + regName + " td.value");
            if (element) {
                let oldContent = element.firstElementChild.textContent;
                let newContent = "0x" + str;
                if (oldContent != newContent) {
                    element.firstElementChild.textContent = newContent;
                    element.parentNode.classList.add("updated");
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
            ret[realIndex] = BigInt(td.firstElementChild.textContent);
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
                td.previousElementSibling.firstElementChild.textContent = input.value;
            }
            this.trigger('change');
        }
    }

    bindEvents() {
        let tableCells = this._element.querySelectorAll("td.value");
        tableCells.forEach( (td) => {
            td.firstElementChild.addEventListener("click", this.selectInput.bind(this, td));
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
