"use strict";

import Helper from '../helper.js';

import Terminal from '../../assets/js/rawrs/terminal.js';
import Tabs from '../../assets/js/rawrs/tabs.js';

describe('Terminal', () => {

    beforeEach(function() {
        // Make the body element that will be passed to the constructor
        this.pre = document.createElement("pre");
        this.pre.setAttribute("id", "output");
        
        document.body.appendChild(this.pre);

        // We need a stub for the main tabs
        let element = document.createElement('ol');
        element.classList.add('tabs');
        element.setAttribute('id', 'main-tabs');

        document.body.appendChild(element);

        this.tabs = jasmine.createSpyObj('tabs', ['on'], {'element': element});
        spyOn(Tabs, 'load').and.returnValue(this.tabs);
    });

    afterEach(function() {
        document.body.innerHTML = "";
    });

    describe('#updateActivePanel', () => {
        beforeEach(function() {
            // Get the tab strip
            let element = this.tabs.element;

            // We need the assemble and run panels
            ['assemble-console-panel', 'run-console-panel'].forEach( (id) => {
                // Create the tab
                let tab = document.createElement('li');
                tab.classList.add('tab');
                element.appendChild(tab);
                let button = document.createElement('button');
                tab.appendChild(button);
                button.setAttribute('aria-controls', id.replace('-console', ''));

                // Create the tab panel
                let panel = document.createElement('div');
                panel.setAttribute('id', id);
                document.body.appendChild(panel);
            });
        });

        it("should duplicate to the run tab when switched to", function() {
            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#assemble-console-panel');
            panel.appendChild(this.pre);

            // Switch to the run tab
            let button = document.querySelector('button[aria-controls="run-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to be within the run panel
            let destinationPanel = document.querySelector('#run-console-panel');
            expect(this.pre.parentNode).toEqual(destinationPanel);
        });

        it("should duplicate to the assemble tab when switched to", function() {
            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#run-console-panel');
            panel.appendChild(this.pre);

            // Switch to the assemble tab
            let button = document.querySelector('button[aria-controls="assemble-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to be within the assemble panel
            let destinationPanel = document.querySelector('#assemble-console-panel');
            expect(this.pre.parentNode).toEqual(destinationPanel);
        });

        it("should stay at the run tab when already there", function() {
            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#run-console-panel');
            panel.appendChild(this.pre);

            // Switch to the run tab
            let button = document.querySelector('button[aria-controls="run-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to be within the run panel
            let destinationPanel = document.querySelector('#run-console-panel');
            expect(this.pre.parentNode).toEqual(destinationPanel);
        });

        it("should stay at the assemble tab when already there", function() {
            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#assemble-console-panel');
            panel.appendChild(this.pre);

            // Switch to the assemble tab
            let button = document.querySelector('button[aria-controls="assemble-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to be within the assemble panel
            let destinationPanel = document.querySelector('#assemble-console-panel');
            expect(this.pre.parentNode).toEqual(destinationPanel);
        });

        it("should maintain the scroll top when switching to the run panel", function() {
            // Set fixed height and overflow
            this.pre.style.height = "150px";
            this.pre.style.overflowY = "scroll";
            this.pre.style.overflowX = "hidden";

            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#assemble-console-panel');
            panel.appendChild(this.pre);

            // Switch to the run tab
            let button = document.querySelector('button[aria-controls="run-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Add some text that will hopefully autoscroll
            for (let i = 0; i < 50; i++) {
                terminal.writeln(Helper.randomString());
            }

            // Read the current scroll value
            let scrollTop = this.pre.scrollTop;

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to still have the same scrollTop
            expect(this.pre.scrollTop).toEqual(scrollTop);
        });

        it("should maintain the scroll top when switching to the assemble panel", function() {
            // Set fixed height and overflow
            this.pre.style.height = "150px";
            this.pre.style.overflowY = "scroll";
            this.pre.style.overflowX = "hidden";

            // Move the pre to the appropriate starting panel
            let panel = document.querySelector('#run-console-panel');
            panel.appendChild(this.pre);

            // Switch to the assemble tab
            let button = document.querySelector('button[aria-controls="assemble-panel"]');
            button.parentNode.classList.add('active');

            // Make terminal
            let terminal = new Terminal(document);

            // Add some text that will hopefully autoscroll
            for (let i = 0; i < 50; i++) {
                terminal.writeln(Helper.randomString());
            }

            // Read the current scroll value
            let scrollTop = this.pre.scrollTop;

            // Call routine
            terminal.updateActivePanel();

            // Expect the <pre> to still have the same scrollTop
            expect(this.pre.scrollTop).toEqual(scrollTop);
        });
    });

    describe('#write', () => {
        it("should set the inner html of its element", function() {
            // Make terminal
            let terminal = new Terminal(document);
            
            // Make string
            let s1 = Helper.randomString();

            // Call
            terminal.write(s1);
            expect(this.pre.innerHTML).toEqual(s1);
        });

        
        it("should append new data", function() {
            // Make terminal
            let terminal = new Terminal(document);
            
            // Make strings
            let s1 = Helper.randomString();
            let s2 = Helper.randomString();

            // Call
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
                terminal.writeln(Helper.randomString());
                expect(this.pre.scrollHeight - this.pre.clientHeight <= this.pre.scrollTop).toBeTruthy
            }
        });
    });

    describe("#writeHeader", () => {
        it("should create a header within the element that contains the string entered", function() {
            // Make terminal
            let terminal = new Terminal(document);

            // Make a string
            let s = Helper.randomString();

            // Add the header
            terminal.writeHeader(s);

            // Find the header
            let h = this.pre.querySelector("h1");

            expect(h.innerHTML).toEqual(s);
        });

        it("should create a new header each time it is called", function() {
            // How many headers to create
            let numHeaders = 10;
            
            // Make terminal
            let terminal = new Terminal(document);

            // Make headers
            let i;
            for (i = 0; i < numHeaders; i++) {
                terminal.writeHeader(i.toString());
            }

            // Retrieve headers
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
            // Make terminal
            let terminal = new Terminal(document);
            
            // Add text directly to inner html
            this.pre.innerHTML = Helper.randomString();

            // Clear
            terminal.clear();

            expect(this.pre.innerHTML).toEqual("");
        });
    });

    describe('#writeln', () => {
        it("should set the inner html of its element and go to next line", function() {
            // Make terminal
            let terminal = new Terminal(document);
            
            // Make string
            let s1 = Helper.randomString();

            // Call
            terminal.writeln(s1);
            expect(this.pre.innerHTML).toEqual(s1 + "\n");
        });

        
        it("should append new data on new lines", function() {
            // Make terminal
            let terminal = new Terminal(document);
            
            // Make strings
            let s1 = Helper.randomString();
            let s2 = Helper.randomString();

            // Call
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
