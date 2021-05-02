"use strict";

import EventComponent from './event_component';

class Separator extends EventComponent {
    constructor(element) {
        super();

        // Create the 'draggable' surface to catch where the mouse releases
        this._draggable = document.querySelector(".draggable-plane");
        if (!this._draggable) {
            this._draggable = document.createElement("div");
            this._draggable.classList.add("draggable-plane");
            this._draggable.setAttribute('role', 'presentation');
            this._draggable.setAttribute('aria-hidden', 'true');
            this._draggable.setAttribute('hidden', '');
            document.body.appendChild(this._draggable);
        }

        // Retain the element.
        this._element = element;

        // And the identifier, if any
        this._id = element.getAttribute('id');

        // And then find the elements this resizes
        let selector = "[data-separator*=\"" + this._id + "\"]";
        this._components = Array.from(
            document.querySelectorAll(selector)
        );

        // Bind the events.
        this.bindEvents();
    }

    /**
     * Handles the '`mousedown`' event.
     *
     * @param {Event} event The '`mousedown`' event structure.
     */
    handleMouseDown(event) {
        this.start(event.pageX, event.pageY);
    }

    /**
     * Handles the '`mouseup`' event for the draggable plane.
     *
     * @param {Event} event The '`mousedown`' event structure.
     */
    handleMouseUp(event) {
        this.end();
    }

    /**
     * Handles the '`mousemove`' event during the drag.
     *
     * @param {Event} event The '`mousedown`' event structure.
     */
    handleMouseDrag(event) {
        let deltaX = event.pageX - this._mouseX;
        let deltaY = event.pageY - this._mouseY;

        let compareLeft = this._element.offsetLeft;
        let compareTop = this._element.offsetTop;

        this._mouseStarts.forEach( (initial, i) => {
            // Get the components we are updating
            let el = this._components[i];

            // Alter width/height depending on the type of separator
            // A separator can either be 'vertical' or 'horizontal'
            if (this._element.classList.contains("vertical")) {
                // If the item is to the right of the separator, subtract width
                if (el.offsetLeft + 10 > compareLeft) {
                    el.style.width = (initial - deltaX) + "px";
                }
                else {
                    // Otherwise, add to the width
                    el.style.width = (initial + deltaX) + "px";
                }

                // Also set flex-basis
                el.style.flexBasis = el.style.width;
            }
            else {
                // If the item is to the right of the separator, subtract height
                if (el.offsetTop + 10 > compareTop) {
                    el.style.height = (initial - deltaY) + "px";
                }
                else {
                    // Otherwise, add to the height
                    el.style.height = (initial + deltaY) + "px";
                }

                // Also set flex-basis
                el.style.flexBasis = el.style.height;
            }
        });
    }

    start(x, y) {
        // Reset the known location
        this._mouseX = x;
        this._mouseY = y;

        // And the current width/height
        this._mouseStarts = this._components.map( (el) => {
            if (this._element.classList.contains("vertical")) {
                return el.offsetWidth;
            }
            else {
                return el.offsetHeight;
            }
        });

        this._boundUp = this.handleMouseUp.bind(this);
        this._draggable.addEventListener("mouseup", this._boundUp);
        this._boundDrag = this.handleMouseDrag.bind(this);
        this._draggable.addEventListener("mousemove", this._boundDrag);

        // Ensure that the draggable also displays the correct cursor
        let cursor = window.getComputedStyle(this._element).cursor;
        this._draggable.style.cursor = cursor;

        // Show the draggable plane
        this._draggable.removeAttribute('hidden');
    }

    end() {
        this._draggable.removeEventListener("mouseup", this._boundUp);
        this._draggable.removeEventListener("mousemove", this._boundDrag);

        // Hide the draggable plane
        this._draggable.setAttribute('hidden', '');
    }

    bindEvents() {
        this._element.addEventListener("mousedown", this.handleMouseDown.bind(this));
    }
}

export default Separator;
