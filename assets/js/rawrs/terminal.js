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
        if (this._tabs) {
            this._tabs.on('change', (button) => {
                this.updateActivePanel();
            });
        }
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
     * Ensures the console appears on the active panel.
     */
    updateActivePanel() {
        // Terminal the new tab
        let button = this._tabs.element.querySelector(".active button");
        let panelId = button.getAttribute('aria-controls');
        let assembleContainer = document.querySelector('#assemble-console-panel');
        let runContainer = document.querySelector('#run-console-panel');

        // Copy the console to the appropriate tab and maintain the scroll.
        if (panelId === 'assemble-panel') {
            if (runContainer.children[0]) {
                let pre = runContainer.children[0];
                let scroll = pre.scrollTop;
                assembleContainer.appendChild(pre);
                pre.scrollTop = scroll;
            }
        }
        else if (panelId === 'run-panel') {
            if (assembleContainer.children[0]) {
                let pre = assembleContainer.children[0];
                let scroll = pre.scrollTop;
                runContainer.appendChild(pre);
                pre.scrollTop = scroll;
            }
        }
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
