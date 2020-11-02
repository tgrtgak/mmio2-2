"use strict";

import EventComponent from './event_component.js';

/**
 * This class represents a dropdown menu.
 */
class Dropdown extends EventComponent {
    /**
     * Wraps the given button as a dropdown menu.
     *
     * It assumes the next element is the dropdown menu itself.
     *
     * @param {HTMLElement} element The button element.
     */
    constructor(element) {
        super();

        this._element = element;

        this._dropdown = element.nextElementSibling;

        this._dropdown.addEventListener("blur", this.blurEvent.bind(this));

        this._dropdown.querySelectorAll("button").forEach( (button) => {
            button.addEventListener("click", (event) => {
                this.trigger("click", button.getAttribute("data-action"));

                this.blurEvent(null, true);

                event.preventDefault();
                event.stopPropagation();
            });

            button.addEventListener("keydown", (event) => {
                if (event.key === "ArrowUp") {
                    // Focus on previous item, if any.
                    let prevItem = button.parentNode.previousElementSibling;
                    let prevButton = null;
                    if (prevItem) {
                        prevButton = prevItem.querySelector("button");
                    }
                    if (prevButton) {
                        prevButton.setAttribute("tabindex", "0");
                        prevButton.focus();
                        prevButton.setAttribute("tabindex", "-1");
                    }
                    event.preventDefault();
                    event.stopPropagation();
                }
                else if (event.key === "ArrowDown") {
                    // Focus on next item, if any.
                    let nextItem = button.parentNode.nextElementSibling;
                    let nextButton = null;
                    if (nextItem) {
                        nextButton = nextItem.querySelector("button");
                    }
                    if (nextButton) {
                        nextButton.setAttribute("tabindex", "0");
                        nextButton.focus();
                        nextButton.setAttribute("tabindex", "-1");
                    }
                    event.preventDefault();
                    event.stopPropagation();
                }
            });
        });

        this._dropdown.addEventListener("keydown", (event) => {
            if (event.key === "Escape") {
                // Close dropdown
                this.blurEvent(null, true);
            }
            else if (event.key === "ArrowUp") {
                // Focus on last item
                let button = this._dropdown.querySelector("li:last-child > button");
                if (button) {
                    button.setAttribute("tabindex", "0");
                    button.focus();
                    button.setAttribute("tabindex", "-1");
                }
            }
            else if (event.key === "ArrowDown") {
                // Focus on first item
                let button = this._dropdown.querySelector("button");
                if (button) {
                    button.setAttribute("tabindex", "0");
                    button.focus();
                    button.setAttribute("tabindex", "-1");
                }
            }
        });

        element.addEventListener("click", (event) => {
            this.dropdown.removeAttribute("hidden");
            this.dropdown.setAttribute("tabindex", "0");
            this.dropdown.focus();
            this.dropdown.setAttribute("tabindex", "-1");
            event.stopPropagation();
        });
    }

    /**
     * Retrieves the dropdown menu element.
     *
     * @returns HTMLElement The dropdown menu element.
     */
    get dropdown() {
        return this._dropdown;
    }

    /**
     * Retrieves the associated dropdown button.
     *
     * @returns HTMLElement The dropdown button element.
     */
    get element() {
        return this._element;
    }

    /**
     * Low-level event handler for when the menu loses focus.
     */
    blurEvent(event, forceClose) {
        // Ignore blur event if the target is a button within the dropdown
        if (forceClose || (!event.relatedTarget ||
                              (event.relatedTarget.parentNode != event.target &&
                                  (event.relatedTarget.parentNode &&
                                   event.relatedTarget.parentNode.parentNode != event.target) &&
                                   !event.relatedTarget.isSameNode(this.dropdown)
                              )
                          )
           ) {
            this.dropdown.setAttribute("hidden", "");
            this.element.setAttribute("aria-expanded", "false");
            this.element.focus();
        }
    }
}

export default Dropdown;
