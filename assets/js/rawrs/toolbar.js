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

    /**
     * Sets the status of the given button.
     *
     * @param {String} button The button identifier.
     */
    setStatus(button, status) {
        let buttonElement = this.element.querySelector("button#" + button);

        if (buttonElement) {
            if (status) {
                buttonElement.setAttribute("data-status", status);

                if (status === "disabled") {
                    buttonElement.setAttribute("disabled", "");
                    if (button === "step") {
                        buttonElement.setAttribute("title", buttonElement.getAttribute("data-i18n-pause"));
                    }
                }
                else {
                    buttonElement.removeAttribute("disabled");
                    if (button === "step") {
                        buttonElement.setAttribute("title", buttonElement.getAttribute("data-i18n-step"));
                    }
                }
            }
            else {
                buttonElement.removeAttribute("data-status");
                buttonElement.removeAttribute("disabled");
            }
        }
    }

    /**
     * Retrieves the status of the specified button or undefined if not set.
     *
     * @param {String} button The button identifier.
     * @returns String The status.
     */
    getStatus(button) {
        let buttonElement = this.element.querySelector("button#" + button);

        if (buttonElement) {
            return buttonElement.getAttribute("data-status");
        }

        return undefined;
    }
}

export default Toolbar;
