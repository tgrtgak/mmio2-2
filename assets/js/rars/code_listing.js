"use strict";

import EventComponent from './event_component';

/**
 * This widget shows the disassembled code and allows the setting of breakpoints
 * and shows the mapping between the machine code and the original source.
 */
class CodeListing extends EventComponent {
    /**
     * Create a new instance of a code listing for the given root element.
     *
     * @param {HTMLElement} root The element to look for the code listing within.
     */
    constructor(root) {
        super();

        let element = root.querySelector("table.instructions");
        this._element = element;
    }

    /**
     * Gets the source code that has been set to this disassembler.
     */
    get source() {
        return this._source;
    }

    /**
     * Sets the source code that this is meant to be a disassembly for.
     *
     * @param {string} value The source text.
     */
    set source(value) {
        this._source = value;
        this._sourceLines = this._source.split("\n");
    }

    /**
     * Returns the element associated with this code listing.
     *
     * @returns {HTMLElement} The element for this code listing.
     */
    get element() {
        return this._element;
    }

    /**
     * Clears the code listing.
     */
    clear() {
        this._element.classList.add("empty");
        this._element.querySelectorAll("tbody tr").forEach( (x) => x.remove() );
    }

    /**
     * Adds an instruction.
     */
    add(info) {
        this._element.classList.remove("empty");
        var row = document.createElement("tr");

        function createCell(type, value) {
            var cell = document.createElement("td");
            cell.classList.add(type);
            cell.textContent = value;
            return cell;
        }

        var rowText = info.row;
        if (this._last && this._last.row == info.row) {
            rowText = "";
        }

        var breakpointCell = document.createElement("td");
        breakpointCell.classList.add("breakpoint");
        var checkbox = document.createElement("input");
        checkbox.setAttribute("type", "checkbox");
        checkbox.addEventListener("change", (event) => {
            if (checkbox.checked) {
                breakpointCell.classList.add("checked");
                this.trigger("breakpoint-set", info);
            }
            else {
                breakpointCell.classList.remove("checked");
                this.trigger("breakpoint-clear", info);
            }
        });
        breakpointCell.appendChild(checkbox);
        row.appendChild(breakpointCell);

        row.appendChild(createCell("address", info.address));
        row.appendChild(createCell("machine-code", info.machineCode));
        row.appendChild(createCell("code", info.code));
        row.appendChild(createCell("row", rowText));
        row.appendChild(createCell("original", (rowText ? this._sourceLines[info.row - 1] : "")));

        this._element.querySelector("tbody").appendChild(row);
        this._last = info;
    }
}

export default CodeListing;
