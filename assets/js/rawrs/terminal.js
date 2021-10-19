"use strict";

import Tabs           from './tabs';
import EventComponent from './event_component';

/**
 * This widget represents a classical terminal.
 */
class Terminal extends EventComponent {
    /**
     * Create a new instance of a terminal for the given root element.
     *
     * @param {HTMLElement} root The element to look for the terminal within.
     */
    constructor(root) {
        super();

        let element = root.querySelector("pre#output");
        this._element = element;
        this._element.classList.remove("initial");

        this._tabs = Tabs.load(document.querySelector('#main-tabs'));
        this._tabs.on('change', (button) => {
            let panelId = button.getAttribute('aria-controls');
            let assembleContainer = document.querySelector('#assemble-console-panel');
            let runContainer = document.querySelector('#run-console-panel');
            if (panelId === 'assemble-panel') {
                if (runContainer.children[0]) {
                    assembleContainer.appendChild(runContainer.children[0]);
                }
            }
            else if (panelId === 'run-panel') {
                if (assembleContainer.children[0]) {
                    runContainer.appendChild(assembleContainer.children[0]);
                }
            }
        });
    }

    /**
     * Returns the element associated with this terminal.
     *
     * @returns {HTMLElement} The element for this terminal.
     */
    get element() {
        return this._element;
    }

    /**
     * Clears the terminal.
     */
    clear() {
        this._element.innerHTML = "";
    }

    /**
     * Creates a new header.
     */
    writeHeader(string) {
        var header = document.createElement("h1");
        header.innerHTML = string;
        var maxScroll = this._element.scrollHeight - this._element.clientHeight;
        var autoScroll = (this._element.scrollTop >= maxScroll - 0.5);
        this._element.appendChild(header);
        if (autoScroll) {
            this._element.scrollTop = this._element.scrollHeight - this._element.clientHeight;
        }
    }

    /**
     * Writes the given string to the terminal.
     *
     * @param {string} data The string to write.
     */
    write(data) {
        var maxScroll = this._element.scrollHeight - this._element.clientHeight;
        var autoScroll = (this._element.scrollTop >= maxScroll - 0.5);
        this._element.innerHTML += data;
        if (autoScroll) {
            this._element.scrollTop = this._element.scrollHeight - this._element.clientHeight;
        }
    }

    /**
     * Writes the given string and go to the next line.
     *
     * @param {string} data The string to write.
     */
    writeln(data) {
        this.write(data + "\n");
    }
}

export default Terminal;
