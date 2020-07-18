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
            this._element.querySelector("tr." + regName + " td.value").textContent = "0x" + str;
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
        regs.forEach( (reg, i) => {
            var str = reg.toString(16);
            str = "0000000000000000".slice(str.length) + str;
            var regName = Simulator.REGISTER_NAMES[i];
            var element = this._element.querySelector("tr." + regName + " td.value");
            if (element) {
                var oldContent = element.textContent;
                var newContent = "0x" + str;
                if (oldContent != newContent) {
                    element.textContent = newContent;
                    element.parentNode.classList.add("updated");
                }
            }
        });
    }
}

export default RegisterListing;
