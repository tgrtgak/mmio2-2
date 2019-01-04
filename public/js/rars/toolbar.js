"use strict";

import EventComponent from './event_component';

class Toolbar extends EventComponent {
    /**
     * Create a new instance of a toolbar for the given root element.
     *
     * @param {HTMLElement} root The element to look for the toolbar within.
     */
    constructor(root) {
        super();

        let element = root.querySelector(".toolbar");
        this._element = element;

        element.querySelectorAll(":scope button").forEach( (button) => {
            button.addEventListener("click", (event) => {
                this.trigger('click', button);
            });
        });
    }

    /**
     * Returns the element associated with this toolbar.
     *
     * @returns {HTMLElement} The element for this toolbar.
     */
    get element() {
        return this._element;
    }
}

export default Toolbar;
