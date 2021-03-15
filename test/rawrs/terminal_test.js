"use strict";

import Helper from '../helper.js';

import Terminal from '../../assets/js/rawrs/terminal.js';

describe('Terminal', () => {

    beforeEach(function() {
        // make the body element that will be passed to the constructor
        this.pre = document.createElement("pre");
        this.pre.setAttribute("id", "output");
        
        document.body.appendChild(this.pre);
    });

    afterEach(function() {
        document.body.removeChild(this.pre)
    });

    describe('#write', () => {
        it("should set the inner html of its element", function() {
            // make terminal
            let terminal = new Terminal(document);
            
            // make string
            let s1 = Helper.randomString();

            // call
            terminal.write(s1);
            expect(this.pre.innerHTML).toEqual(s1);
        });

        
        it("should append new data", function() {
            // make terminal
            let terminal = new Terminal(document);
            
            // make strings
            let s1 = Helper.randomString();
            let s2 = Helper.randomString();

            // call
            terminal.write(s1);
            terminal.write(s2);

            expect(this.pre.innerHTML).toEqual(s1 + s2);
        });

        
        it("should autoscroll", function() {
            // Set fixed height and overflow
            this.pre.style.height = "150px";
            this.pre.style.overflowY = "scroll";
            this.pre.style.overflowX = "hidden";

            // Make terminal
            let terminal = new Terminal(document);

            // Add a bunch of text to cause autoscrolling
            for (let i = 0; i < 100; i++) {
                terminal.write(Helper.randomString() + "\n");
                expect(this.pre.scrollHeight - this.pre.clientHeight <= this.pre.scrollTop).toBeTruthy
            }
        });
    });

    describe("#writeHeader", () => {
        it("should create a header within the element that contains the string entered", function() {
            // make terminal
            let terminal = new Terminal(document);

            // Make a string
            let s = Helper.randomString();

            // Add the header
            terminal.writeHeader(s);

            // find the header
            let h = this.pre.querySelector("h1");

            expect(h.innerHTML).toEqual(s);
        });

        it("should create a new header each time it is called", function() {
            // How many headers to create
            let numHeaders = 10;
            
            // make terminal
            let terminal = new Terminal(document);

            // Make headers
            let i;
            for (i = 0; i < numHeaders; i++) {
                terminal.writeHeader(i.toString());
            }

            // retrive headers
            let headers = this.pre.querySelectorAll("h1");

            // Make sure all were retrieved
            expect(headers.length).toEqual(numHeaders);
        });


        it("should autoscroll", function() {
            // Set fixed height and overflow
            this.pre.style.height = "150px";
            this.pre.style.overflowY = "scroll";
            this.pre.style.overflowX = "hidden";

            // Make terminal
            let terminal = new Terminal(document);

            // Add a bunch of text to cause autoscrolling
            for (let i = 0; i < 100; i++) {
                terminal.writeHeader(Helper.randomString());
                expect(this.pre.scrollHeight - this.pre.clientHeight <= this.pre.scrollTop).toBeTruthy
            }
        });
    });
    
    describe('#clear', () => {
        it("should clear all text from the terminal leaving an empty string", function() {
            // make terminal
            let terminal = new Terminal(document);
            
            // add text directly to inner html
            this.pre.innerHTML = Helper.randomString();

            // clear
            terminal.clear();

            expect(this.pre.innerHTML).toEqual("");
        });
    });

    describe('#writeln', () => {
        it("should set the inner html of its element and go to next line", function() {
            // make terminal
            let terminal = new Terminal(document);
            
            // make string
            let s1 = Helper.randomString();

            // call
            terminal.writeln(s1);
            expect(this.pre.innerHTML).toEqual(s1 + "\n");
        });

        
        it("should append new data on new lines", function() {
            // make terminal
            let terminal = new Terminal(document);
            
            // make strings
            let s1 = Helper.randomString();
            let s2 = Helper.randomString();

            // call
            terminal.writeln(s1);
            terminal.writeln(s2);

            expect(this.pre.innerHTML).toEqual(s1 + "\n" + s2 + "\n");
        });

        it("should autoscroll", function() {
            // Set fixed height and overflow
            this.pre.style.height = "150px";
            this.pre.style.overflowY = "scroll";
            this.pre.style.overflowX = "hidden";

            // Make terminal
            let terminal = new Terminal(document);

            // Add a bunch of text to cause autoscrolling
            for (let i = 0; i < 100; i++) {
                terminal.writeln(Helper.randomString());
                expect(this.pre.scrollHeight - this.pre.clientHeight <= this.pre.scrollTop).toBeTruthy;
            }
        });
        
    });
    
});
