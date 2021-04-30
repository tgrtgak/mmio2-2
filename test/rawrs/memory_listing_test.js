"use strict";

import Helper from '../helper.js';

import MemoryListing from '../../assets/js/rawrs/memory_listing';

// Helper functions
// Near copy paste of update() from memory_listing, works at time of test writing
function helperNewRow(address, data) {
    var row = document.createElement("tr");

    function createCell(type, value, address, event) {
        var cell = document.createElement("td");
        cell.classList.add(type);
        cell.textContent = value;

        if (type === "word") {
            cell.setAttribute("current", value);
            cell.setAttribute("address", address);
            cell.setAttribute("contenteditable", "true");
            cell.setAttribute("spellcheck", "false")

            cell.addEventListener("keydown", function(event) {
                if (event.code === 'Enter') {
                    event.preventDefault();
                    cell.blur();
                }
            });

            cell.addEventListener('focusout', () => {
                let submit = "0x";
                let word = cell.textContent.slice(-8).padStart(8, '0');
                submit += word;
                try {
                    BigInt(submit);
                }
                catch (err) {
                    word = cell.getAttribute("current");
                    submit = "0x" + word;
                }
                finally {
                    cell.textContent = word;
                    cell.setAttribute("current", word);
                    window.getSelection().removeAllRanges();

                    let splitWord = word.match(/([\S\s]{1,2})/g).reverse();
                    let array = new Uint8Array(4);
                    for (let i = 0; i < 4; i++) {
                        array[i] = parseInt(splitWord[i], 16);
                    }

                    data = {address: parseInt(cell.getAttribute("address"), 16), data: array};
                    event.trigger("change", data);
                }
            });
        }
        return cell;
    }

    row.appendChild(createCell("address", address));

    // For each word, push a cell
    for (var i = 0; i < 32; i+=4) {
        var word = "";
        for (var byteIndex = 0; byteIndex < 4; byteIndex++) {
            word = (data[i+byteIndex] || 0).toString(16).padStart(2, '0') + word;
        }
        row.appendChild(createCell("word", word, (parseInt(address, 16) + i).toString(16), this));
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

    return row;
}

describe('MemoryListing', () => {

    beforeEach(function() {

        // Make init table
        let tb = document.createElement("table");
        tb.classList.add("memory");
        tb.classList.add("empty");
        let th = document.createElement("thead");
        let tr = document.createElement("tr");

        // Add labels
        let label = document.createElement("th");
        label.innerHTML = "Address";
        tr.appendChild(label);

        for (let i = 0; i <= 28; i += 4) {
            label = document.createElement("th");
            label.innerHTML = "Value (+" + i +")";
            tr.appendChild(label);
        }

        label = document.createElement("th");
        label.innerHTML = "Printed";
        tr.appendChild(label);

        // Put everything together
        th.appendChild(tr);
        tb.appendChild(th);
        tb.appendChild(document.createElement("tbody"));
        document.body.appendChild(tb);
    });

    afterEach(function() {
        document.body.removeChild(document.querySelector("table"));
    });

    describe('get numberOfRows', () => {
        it('should return 0 when empty', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            expect(mem_list.numberOfRows).toEqual(0);
        });

        it('should return the number of rows', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            let num = Helper.randomInteger(100, 2);

            // Remove empty class
            document.querySelector('table').classList.remove("empty");

            // Add random number of rows
            for (let i = 0; i < num; i++){
                // Make address
                let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
                addr = "0000000000000000".slice(addr.length) + addr;

                // Make array of bytes
                let bytes = new Uint8Array(32);

                for (let j = 0; j < bytes.length; j++){
                    bytes[j] = Helper.randomInteger(255, 0);
                }

                let row = helperNewRow(addr, bytes);
                document.querySelector("tbody").appendChild(row);
            }

            expect(mem_list.numberOfRows).toEqual(num);
        });
    });

    describe('get addresses', () => {
        it('should return an array containing all addresses', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            let addresses = new Array();

            // Add random number of rows
            let num = Helper.randomInteger(100, 2);
            for (let i = 0; i < num; i++){
                // Make address
                let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
                addr = "0000000000000000".slice(addr.length) + addr;

                // Store address to check against later
                addresses[i] = addr;

                // Make array of bytes
                let bytes = new Uint8Array(32);

                for (let j = 0; j < bytes.length; j++){
                    bytes[j] = Helper.randomInteger(255, 0);
                }

                let row = helperNewRow(addr, bytes);
                document.querySelector("tbody").appendChild(row);
            }

            expect(mem_list.addresses.length).toEqual(addresses.length);
            addresses.forEach( (address) => {
                expect(mem_list.addresses).toContain(address);
            });
        });

        it('should return an empty array if there are no rows', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            expect(mem_list.addresses.length).toEqual(0);
        });
    });

    describe('address', () => {
        it('should return the address in the index', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            let addresses = new Array();

            // Add random number of rows
            let num = Helper.randomInteger(100, 2);
            for (let i = 0; i < num; i++){
                // Make address
                let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
                addr = "0000000000000000".slice(addr.length) + addr;

                // Store address to check against later
                addresses[i] = addr;

                // Make array of bytes
                let bytes = new Uint8Array(32);

                for (let j = 0; j < bytes.length; j++){
                    bytes[j] = Helper.randomInteger(255, 0);
                }

                let row = helperNewRow(addr, bytes);
                document.querySelector("tbody").appendChild(row);
            }

            addresses.forEach( (address, i) => {
                expect(mem_list.address(i)).toEqual(address);
            });
        });
    });

    describe('clear', () => {
        it('should remove all rows', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            let num = Helper.randomInteger(100, 2);

            // Remove empty class
            document.querySelector('table').classList.remove("empty");

            // Add random number of rows
            for (let i = 0; i < num; i++){
                // Make address
                let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
                addr = "0000000000000000".slice(addr.length) + addr;

                // Make array of bytes
                let bytes = new Uint8Array(32);

                for (let j = 0; j < bytes.length; j++){
                    bytes[j] = Helper.randomInteger(255, 0);
                }

                let row = helperNewRow(addr, bytes);
                document.querySelector("tbody").appendChild(row);
            }

            // Function call
            mem_list.clear();

            expect(document.querySelector("tbody").firstChild).toBeNull();
        });

        it('should mark the listing as empty', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            let num = Helper.randomInteger(100, 2);

            // Remove empty class
            document.querySelector('table').classList.remove("empty");

            // Add random number of rows
            for (let i = 0; i < num; i++){
                // Make address
                let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
                addr = "0000000000000000".slice(addr.length) + addr;

                // Make array of bytes
                let bytes = new Uint8Array(32);

                for (let j = 0; j < bytes.length; j++){
                    bytes[j] = Helper.randomInteger(255, 0);
                }

                let row = helperNewRow(addr, bytes);
                document.querySelector("tbody").appendChild(row);
            }

            // Function call
            mem_list.clear();

            expect(document.querySelector("table.memory").classList).toContain("empty");
        });
    });

    describe('update', () => {
        it('should remove the empty class', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            // Make address
            let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
            addr = "0000000000000000".slice(addr.length) + addr;

            // Make array of bytes
            let bytes = new Uint8Array(32);

            for (let i = 0; i < bytes.length; i++){
                bytes[i] = Helper.randomInteger(255, 0);
            }

            // Call update
            mem_list.update(addr, bytes);

            expect(document.querySelector("table.memory").classList).not.toContain("empty");
        });
        
        it('should add a new row', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            // Make address
            let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
            addr = "0000000000000000".slice(addr.length) + addr;

            // Make array of bytes
            let bytes = new Uint8Array(32);

            for (let i = 0; i < bytes.length; i++){
                bytes[i] = Helper.randomInteger(255, 0);
            }

            // Call update
            mem_list.update(addr, bytes);

            // Get the new row
            let row = document.querySelector("tbody").querySelector("tr");

            expect(row).not.toBeNull();
        });

        it('should list the address in the address column', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            // Make address
            let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
            addr = "0000000000000000".slice(addr.length) + addr;

            // Make array of bytes
            let bytes = new Uint8Array(32);

            for (let i = 0; i < bytes.length; i++){
                bytes[i] = Helper.randomInteger(255, 0);
            }

            // Call update
            mem_list.update(addr, bytes);

            // Get the new row
            let row = document.querySelector("tbody").querySelector("tr");

            expect(row.querySelectorAll("td")[0].textContent).toEqual(addr);
        });

        it('should list the values in the appropriate columns', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            // Make address
            let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
            addr = "0000000000000000".slice(addr.length) + addr;

            // Make array of bytes
            let bytes = new Uint8Array(32);

            for (let i = 0; i < bytes.length; i++) {
                bytes[i] = Helper.randomInteger(255, 0);
            }

            // Call update
            mem_list.update(addr, bytes);

            // Get the new row
            let row = document.querySelector("tbody").querySelector("tr");

            for (let i = 0; i < bytes.length / 4; i++) {
                let str = "";
                for (let j = 0; j < 4; j++) {
                    str = bytes[i*4+j].toString(16).padStart(2, '0') + str;
                }
                expect(row.querySelectorAll("td")[i+1].textContent).toEqual(str);
            }
        });

        // WIP
        xit('should list the interpreted print value in the print column', function() {
            // Make memory listing
            let mem_list = new MemoryListing(document);

            // Make address
            let addr = 144 + (Helper.randomInteger(100, 1)*32).toString(16);
            addr = "0000000000000000".slice(addr.length) + addr;

            // Make string
            let str = Helper.randomString();
            
            // Make textencoder
            let textEncoder = new TextEncoder();

            // Make array of bytes
            let bytes = textEncoder.encode(str);

            // Pad out array
            while (bytes.length < 32) {
                bytes[bytes.length] = 0;
            }

            // Call update
            mem_list.update(addr, bytes);

            // Get the new row
            let row = document.querySelector("tbody tr");

            expect(row.querySelectorAll("td")[10].textContent).toEqual(str);
        });
    });

});
