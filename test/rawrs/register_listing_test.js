"use strict";

import Helper from '../helper.js';

import RegisterListing from '../../assets/js/rawrs/register_listing.js';
import Simulator from '../../assets/js/rawrs/simulator.js';

describe('Register Listing', () => {

    beforeEach(function() {
        // Make register listing html in way constructor expects
        
        // Div containing all
        let register_file_div = document.createElement("div");
        register_file_div.classList.add("register-file");

        // The table
        let register_table = document.createElement("table");
        register_table.classList.add("registers");
        
        // The table body
        let tbody = document.createElement("tbody");

        // Make all rows
        Simulator.REGISTER_NAMES.forEach( (regName) => {
            // Make each tr
            let curr_row = document.createElement("tr");
            curr_row.classList.add("register");
            curr_row.classList.add(regName);

            // Create name td
            let name_td = document.createElement("td");
            name_td.classList.add("name");
            name_td.textContent = regName;

            // Create value td
            let value_td = document.createElement("td");
            value_td.classList.add("value");
            let value_td_button = document.createElement("button");
            value_td_button.textContent = "0x0000000000000000" // Default value
            value_td.appendChild(value_td_button);

            // Create edit td
            let edit_td = document.createElement("td");
            edit_td.classList.add("edit");
            edit_td.setAttribute('hidden', '');
            let edit_td_input = document.createElement("input");
            edit_td_input.classList.add("input");
            edit_td_input.id = "register-" + regName;
            edit_td_input.type = "text";
            edit_td.appendChild(edit_td_input);

            // Attach td's as children
            curr_row.appendChild(name_td);
            curr_row.appendChild(value_td);
            curr_row.appendChild(edit_td);

            // Attach row to table body
            tbody.appendChild(curr_row);
        });

        // Attach all parts together
        register_table.appendChild(tbody);
        register_file_div.appendChild(register_table);

        // Attach whole thing to document
        document.body.appendChild(register_file_div);
    });

    afterEach(function() {
        // Get rid of table to remake
        document.body.removeChild(document.body.querySelector(".register-file"));
    });

    describe('#clear', () => {
        it("should set all values in value listings to 0x0000000000000000", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);
            
            // Set the values in table to hex value of index + 1
            Simulator.REGISTER_NAMES.forEach( (regName, i) => {
                let str = (i + 1).toString(16); // Convert to a string represented as a hex value
                str = "0000000000000000".slice(str.length) + str;
                document.querySelector("tr." + regName + " td.value button").textContent = "0x" + str;
            });

            // Run function
            reg_list.clear();

            // Test to see if all is 0 hex values
            Simulator.REGISTER_NAMES.forEach( (regName) => {
                let val = document.querySelector("tr." + regName + " td.value button").textContent
                expect(val).toEqual("0x0000000000000000");
            });
        });
    });

    describe('#unhighlight', () => {
        it("should unhighlight all entries i.e. remove the updated class", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Set all values i.e. rows to be highlighted/updated
            document.querySelectorAll("tr").forEach( (row) => {
                row.classList.add("updated");
            });

            // Run function
            reg_list.unhighlight();

            // Check that everything has been unhighlighted
            document.querySelectorAll("tr").forEach( (row) => {
                expect(row.classList.contains("updated")).toBeFalsy();
            });
        });
    });

    describe('#update', () => {
        it("should update the listed numbers", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Make array of 32 random BigUint64
            let nums = new BigUint64Array(32);
            for (let i = 0; i < 32; i++) {
                let num = BigInt(Helper.randomInteger(1000000, 1));
                nums[i] = num;
            }

            // Run function
            reg_list.update(nums);
        
            // Check listed numbers against nums
            Simulator.REGISTER_NAMES.forEach( (regName, i) => {
                let val = document.querySelector("tr." + regName + " td.value button").textContent
                expect(BigInt(val)).toEqual(nums[i]);
            });
        });

        it("should highlight (i.e. mark as updated) all values that changed", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Make array of what will be updated from 0
            let isUpdated = new Array(32);

            // First two indexes set manually
            isUpdated[0] = true;
            isUpdated[1] = false;

            // Rest are random
            for (let i = 2; i < 32; i++) {
                isUpdated[i] = Math.random() < 0.5;
            }

            // Make array of 32 BigUint64, random for those being changed, 0 (default value) for those not
            let nums = new BigUint64Array(32);
            for (let i = 0; i < 32; i++) {
                if (isUpdated[i]) {
                let num = BigInt(Helper.randomInteger(1000000, 1));
                nums[i] = num;
                }
                else {
                    nums[i] = BigInt(0);
                }
            }

            // Run function
            reg_list.update(nums);

            // That registers updated have been marked as such
            document.querySelectorAll("tr").forEach( (row, i) => {
                expect(row.classList.contains("updated")).toEqual(isUpdated[i]);
            });
        });
    });

    describe('#get registers', () => {
        it("should return the values of the registers", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Make array of 32 random BigUint64
            let nums = new BigUint64Array(32);
            for (let i = 0; i < 32; i++) {
                let num = BigInt(Helper.randomInteger(1000000, 1));
                nums[i] = num;
            }

            // Manually set values in table
            Simulator.REGISTER_NAMES.forEach( (regName, i) => {
                let str = nums[i].toString(16); // Convert to a string represented as a hex value
                str = "0000000000000000".slice(str.length) + str; // Pad the string with zeroes
                document.querySelector("tr." + regName + " td.value button").textContent = "0x" + str;
            });

            // Check if arrays are the same
            expect(nums.length).toEqual(reg_list.registers.length);
            for (let i = 0; i < 32; i++) {
                expect(nums[i]).toEqual(reg_list.registers[i]);
            }

        });
    });

    describe('#selectInput', () => {
        it("should focus on the input", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

             // Setup spy
             let focusSpy = spyOn(input, 'focus');

             // Call function
             reg_list.selectInput(val_td);

             // Check if input has been focused
             expect(focusSpy).toHaveBeenCalled();
        });

        it("should select on the input", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

             // Setup spy
             let selectSpy = spyOn(input, 'select');

             // Call function
             reg_list.selectInput(val_td);

             // Check if input has been focused
             expect(selectSpy).toHaveBeenCalled();
        });

        it("should put the register value in the input", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Make test string
            let str = Helper.randomInteger(1000000, 1).toString(16); // Convert to a string represented as a hex value
            str = "0000000000000000".slice(str.length) + str;
            str = "0x" + str;

            // Put str in button
            button.textContent = str;

            // Call function
            reg_list.selectInput(val_td);

            // Check that str is in input
            expect(input.value).toEqual(str);
        });

        it("should hide the value td", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Call function
            reg_list.selectInput(val_td);

            // Check if hidden
            expect(val_td.hasAttribute("hidden")).toBeTruthy();
        });

        it("should show the edit td", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Call function
            reg_list.selectInput(val_td);

            // Check if shown
            expect(edit_td.hasAttribute("hidden")).toBeFalsy();
        });
    });

    describe('#submitInput', () => {
        it("should hide the edit td", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Set attributes to what they would be while editing register
            val_td.setAttribute('hidden', '');
            edit_td.removeAttribute('hidden');

            // Call function
            reg_list.submitInput(input);

            // Check if hidden
            expect(edit_td.hasAttribute("hidden")).toBeTruthy();
        });

        it("should show the value td", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Set attributes to what they would be while editing register
            val_td.setAttribute('hidden', '');
            edit_td.removeAttribute('hidden');

            // Call function
            reg_list.submitInput(input);

            // Check if shown
            expect(val_td.hasAttribute("hidden")).toBeFalsy();
        });

        it("should put the value in the input in the value listing (if valid)", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Set attributes to what they would be while editing register
            val_td.setAttribute('hidden', '');
            edit_td.removeAttribute('hidden');

            // Make test string
            let str = Helper.randomInteger(1000000, 1).toString(16); // Convert to a string represented as a hex value
            str = "0000000000000000".slice(str.length) + str;
            str = "0x" + str;

            // Put str in input
            input.value = str;

            // Call function
            reg_list.submitInput(input);

            // Check if value listing is str
            expect(button.textContent).toEqual(str);
        });

        it("should reject invalid value in input, maintain previous value", function() {
            // Make register_listing
            let reg_list = new RegisterListing(document);

            // Find components for test
            let test_tr = document.querySelector("tr");
            let val_td = test_tr.querySelector("td.value");
            let edit_td = test_tr.querySelector("td.edit");
            let button = val_td.querySelector("button");
            let input = edit_td.querySelector("input");

            // Make valid test string
            let v_str = Helper.randomInteger(1000000, 1).toString(16); // Convert to a string represented as a hex value
            v_str = "0000000000000000".slice(v_str.length) + v_str;
            v_str = "0x" + v_str;

            // Put valid str in listing
            button.textContent = v_str;

            // Make invalid test string
            let iv_str = "0xLMNOP";

            // Set attributes to what they would be while editing register
            val_td.setAttribute('hidden', '');
            edit_td.removeAttribute('hidden');

            // Put invalid value in input
            input.value = iv_str;

            // Call function
            reg_list.submitInput(input);

            // Check if value listing is v_str
            expect(button.textContent).toEqual(v_str);
        });
    });

    xdescribe('#bindEvents', () => {
        it("should bind all buttons on click to selectInput()", function() {
            // WIP
            expect().nothing();
        });

        it("should bind all inputs on blur to submitInput()", function() {
            // WIP
            expect().nothing();
        });

        it("should bind all inputs on pressing enter to submitInput()", function() {
            // WIP
            expect().nothing();
        });
    });

    describe(".constructor", () => {
        it("should bindEvents when constructed", function() {
            let spy = spyOn(RegisterListing.prototype, 'bindEvents');

            // Make register_listing
            let reg_list = new RegisterListing(document);

            expect(spy).toHaveBeenCalled();
        });
    });
});