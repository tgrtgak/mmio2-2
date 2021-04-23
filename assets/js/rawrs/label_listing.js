"use strict";

import EventComponent from './event_component';

/**
 * This widget shows the a partial reflection of the .symtab section, specifically
 * the labels that were defined as well as the addresses of the appropriate data.
 */
class LabelListing extends EventComponent {
    /**
     * Create a new instance of a label listing for the given root element.
     *
     * @param {HTMLElement} root The element to look for the label listing within.
     */
    constructor(root) {
        super();

        let element = root.querySelector("table.labels");
        this._element = element;
    }

    /**
     * Returns the element associated with this label listing.
     *
     * @returns {HTMLElement} The element for this label listing.
     */
    get element() {
        return this._element;
    }

    /**
     * Clears the label listing.
     */
    clear() {
        this._element.classList.add("empty");
        this._element.querySelectorAll("tbody tr").forEach( (x) => x.remove() );
    }

    /**
     * Updates a row within the label listing
     *
     * A row consists of a label and a corresponding address, both of them strings
     *
     * @param {string} label The name of the label
     * @param {string} address The address that the label points at
     */
    update(label, address) {
        this._element.classList.remove("empty");
        var row = document.createElement("tr");

        function createCell(type, value) {
            var cell = document.createElement("td");
            cell.classList.add(type);
            cell.textContent = value;
            return cell;
        }
        
        row.appendChild(createCell("label", label));
        row.appendChild(createCell("address", address));
        this._element.querySelector("tbody").appendChild(row);
    }
}

export default LabelListing;
