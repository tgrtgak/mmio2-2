"use strict";

import EventComponent from './event_component.js';

import dialogPolyfill from 'dialog-polyfill';

class Dialog extends EventComponent {
    /**
     * Create a new dialog instance for the dialog at the given id.
     *
     * @param {string} id The identifier for the `<dialog>` element.
     */
    constructor(id) {
        super();

        // Ensure the id is in the form of a css selector
        if (id[0] != "#") {
            id = "#" + id;
        }

        // Find the dialog element
        this._id = id;
        this._dialog = document.querySelector(this._id);

        // Ensure that the polyfill happens, if it is necessary
        dialogPolyfill.registerDialog(this._dialog);

        // Bind events for the common dialog elements
        this.bindDialogEvents();
    }

    /**
     * The identifier of the dialog that this class represents.
     *
     * @returns {string} The identifier.
     */
    get id() {
        return this._id;
    }

    /**
     * Returns the `<dialog>` element this class represents.
     *
     * @returns {HTMLElement} The wrapped element.
     */
    get dialog() {
        return this._dialog;
    }

    /**
     * Displays the dialog.
     */
    open() {
        this._dialog.showModal();
        this.trigger('open');
    }

    /**
     * Closes the dialog.
     */
    close() {
        this._dialog.close();
        this.trigger('close');
    }

    /**
     * Binds events, which is done internally when the dialog is initialized.
     */
    bindDialogEvents() {
        // Close button
        let closeButton = this.dialog.querySelector('button.close');
        closeButton.addEventListener('click', (event) => {
            this.close();
        });
    }
}

export default Dialog;
