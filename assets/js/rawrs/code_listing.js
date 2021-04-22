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
        this.unhighlight();
        this._element.classList.add("empty");
        this._element.querySelectorAll("tbody tr").forEach( (x) => x.remove() );
    }

    /**
     * Unhighlights any highlighted line.
     */
    unhighlight() {
        this._highlighted = null;
        this._element.querySelectorAll(".highlighted").forEach( (element) => {
            element.classList.remove("highlighted");
        });
    }

    /**
     * Highlights the instruction at the given address.
     *
     * Only one line can be highlighted at a time.
     *
     * @param {string} address The address as a hex string, i.e. "400004".
     */
    highlight(address) {
        this._highlighted = address;

        this._element.querySelectorAll(".highlighted").forEach( (element) => {
            element.classList.remove("highlighted");
        });

        var element = this._element.querySelector(".address-" + address);
        if (element) {
            element.parentNode.classList.add("highlighted");
        }
    }

    /**
     * Retrieves the highlighted instruction.
     */
    get highlightedLine() {
        let highlighted = this._element.querySelector(".highlighted");
        if (!highlighted) {
            return null;
        }

        let ret = {};

        ret.machineCode = highlighted.querySelector("td.machine-code").textContent;
        ret.address     = highlighted.querySelector("td.address").textContent;
        // TODO: original,code,row may be on the preceding line
        ret.code        = highlighted.querySelector("td.code").textContent;
        ret.row         = highlighted.querySelector("td.row").textContent;

        return ret;
    }

    /**
     * Marks the given address as having its breakpoint set.
     */
    check(address) {
        var element = this._element.querySelector(".address-" + address);
        if (element) {
            let breakpointCell = element.parentNode.querySelector("td.breakpoint");
            let checkbox = breakpointCell.querySelector("input");
            checkbox.checked = true;
            breakpointCell.classList.add("checked");
        }
    }

    /**
     * Removes the mark for the given address so as to clear its breakpoint.
     */
    uncheck(address) {
        var element = this._element.querySelector(".address-" + address);
        if (element) {
            let breakpointCell = element.parentNode.querySelector("td.breakpoint");
            let checkbox = breakpointCell.querySelector("input");
            checkbox.checked = false;
            breakpointCell.classList.remove("checked");
        }
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
                this.trigger("breakpoint-set", info.address);
            }
            else {
                breakpointCell.classList.remove("checked");
                this.trigger("breakpoint-clear", info.address);
            }
        });
        breakpointCell.appendChild(checkbox);
        row.appendChild(breakpointCell);

        var addressCell = createCell("address", info.address);
        addressCell.classList.add("address-" + info.address);
        row.appendChild(addressCell);
        row.appendChild(createCell("machine-code", info.machineCode));
        row.appendChild(createCell("code", info.code));
        row.appendChild(createCell("row", rowText));
        row.appendChild(createCell("original", (rowText ? this._sourceLines[info.row - 1] : "")));

        if (info.address == this._highlighted) {
            row.classList.add('highlighted');
        }

        this._element.querySelector("tbody").appendChild(row);
        this._last = info;
    }
}

export default CodeListing;
