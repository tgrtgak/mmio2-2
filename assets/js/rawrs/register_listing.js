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
        Simulator.REGISTER_NAMES.forEach( (regName) => {
            var str = "0000000000000000";
            this._element.querySelector("tr." + regName + " td.value button").textContent = "0x" + str;
        });
    }

    /**
     * Removes highlights on updated entries.
     */
    unhighlight() {
        Simulator.REGISTER_NAMES.forEach( (regName) => {
            var str = "0000000000000000";
            this._element.querySelector("tr." + regName + " td.value").parentNode.classList.remove("updated");
        });
    }

    /**
     * Updates the register listing for the provided register values.
     *
     * @param {BigUint64Array} regs The register values.
     */
    update(regs) {
        regs.forEach( (reg, i) => { // for each register in the array
            var str = reg.toString(16); // convert to a string represented as a hex value
            str = "0000000000000000".slice(str.length) + str; // pad the string with zeroes
            var regName = Simulator.REGISTER_NAMES[i]; // put the current register's name into regName
            var element = this._element.querySelector("tr." + regName + " td.value");
            if (element) {
                var oldContent = element.firstElementChild.textContent;
                var newContent = "0x" + str;
                if (oldContent != newContent) {
                    element.firstElementChild.textContent = newContent;
                    element.parentNode.classList.add("updated");
                }
            }
        });
    }

    get registers() {
        let ret = new BigUint64Array(32);
        var tableCells = this._element.querySelectorAll("td.value");
        tableCells.forEach( (td, i) => {
            let registerName = td.previousElementSibling.textContent;
            let realIndex = Simulator.REGISTER_NAMES.indexOf(registerName);
            ret[realIndex] = BigInt(td.firstElementChild.textContent);
        });
        return ret;
    }

    bindEvents() {
        var tableCells = this._element.querySelectorAll("td.value");
        tableCells.forEach( (td) => {
            td.firstElementChild.addEventListener("click", (event) => {
                td.setAttribute('hidden', '');
                td.nextElementSibling.removeAttribute('hidden');
                let input = td.nextElementSibling.querySelector('input');
                input.focus();
                input.value = td.firstElementChild.textContent;
                input.select();
            });
        });

        var inputCells = this._element.querySelectorAll("td.edit input");
        inputCells.forEach( (input) => {
            let doneEvent = (event) => {
                let td = input.parentNode;
                td.setAttribute('hidden', '');
                td.previousElementSibling.removeAttribute('hidden');
                td.previousElementSibling.firstElementChild.textContent = input.value;
                this.trigger('change');
            }
            input.addEventListener("blur", doneEvent);
            input.addEventListener("keydown", (keyEvent) => {
                if(keyEvent.key === "Enter") {
                    doneEvent(keyEvent);
                }
            });
        });
    }
}

export default RegisterListing;
