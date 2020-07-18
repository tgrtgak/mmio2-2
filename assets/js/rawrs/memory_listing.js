"use strict";

import EventComponent from './event_component';

/**
 * This widget shows the disassembled code and allows the setting of breakpoints
 * and shows the mapping between the machine code and the original source.
 */
class MemoryListing extends EventComponent {
    /**
     * Create a new instance of a memory listing for the given root element.
     *
     * @param {HTMLElement} root The element to look for the memory listing within.
     */
    constructor(root) {
        super();

        let element = root.querySelector("table.memory");
        this._element = element;
    }

    /**
     * Returns the element associated with this memory listing.
     *
     * @returns {HTMLElement} The element for this memory listing.
     */
    get element() {
        return this._element;
    }

    /**
     * Clears the memory listing.
     */
    clear() {
        this._element.classList.add("empty");
        this._element.querySelectorAll("tbody tr").forEach( (x) => x.remove() );
    }

    /**
     * Updates a row within the memory listing.
     *
     * A row is a sequence of 8 32-bit words. The 'data' argument can contain up
     * to 32 elements, each representing a byte. The data will be considered in
     * byte order and then printed in little-endian form.
     *
     * @param {string} address The address of the updated row as a hex string.
     * @param {Uint8Array} data The data as an array of bytes.
     */
    update(address, data) {
        this._element.classList.remove("empty");
        var row = document.createElement("tr");

        function createCell(type, value) {
            var cell = document.createElement("td");
            cell.classList.add(type);
            cell.textContent = value;
            return cell;
        }

        row.appendChild(createCell("address", address));

        // For each word, push a cell
        for (var i = 0; i < 32; i+=4) {
            var wordString = "";
            for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
                wordString = (data[i+byteIndex] || 0).toString(16).padStart(2, '0') + wordString;
            }
            row.appendChild(createCell("word", wordString));
        }

        var ascii = Array.from(data).map( (byte) => {
            var chr = String.fromCharCode(byte);
            // A tricky way to decide if a character is "printable"
            // Probably gonna have some edge cases that are missed
            var uri = encodeURI(chr);
            if (uri.length == 1 || uri === "%25" ||
                                   uri === "%3C" ||
                                   uri === "%3E" ||
                                   uri === "%22" ||
                                   uri === "%20" ||
                                   uri === "%5E" ||
                                   uri === "%60" ||
                                   uri === "%5B" ||
                                   uri === "%5D") {
                // It is a proper character within a URI
                // ... or it is a % or " " or ^ or ` or [ or ] (yikes)
                return chr;
            }
            else {
                return ".";
            }
        }).join('').padEnd(32, '.');

        row.appendChild(createCell("ascii", ascii));

        this._element.querySelector("tbody").appendChild(row);
    }
}

export default MemoryListing;
