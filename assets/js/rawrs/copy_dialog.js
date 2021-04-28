"use strict";

import Dialog from './dialog';
import FileList from './file_list';
import FileSystem from './file_system';

/**
 * Represents the file copy dialog.
 */
class CopyDialog extends Dialog {
    constructor(fileInfo) {
        super('dialog-copy-file');

        this.open();

        this._source = fileInfo;

        this._fileList = new FileList(this.dialog);

        this._fileList.loadRoot().then( () => {
            this._fileList.revealPath("/").then( () => {
            })
        });

        this._cancelButton = this.dialog.querySelector("#button-cancel-copy");
        this._copyButton = this.dialog.querySelector("#button-complete-copy");
        this._copyButton.setAttribute('disabled', '');

        // Bind the specific events for the dialog
        this.bindEvents();
    }

    /**
     * Closes the dialog.
     */
    close() {
        this._fileList.unselect();
        this._fileList.clear();
        super.close();
    }

    /**
     * Performs the copy of the file to the selected directory.
     */
    async copy() {
        this._copyButton.setAttribute('disabled', '');
        await this.trigger('copy', this._selected);
        this.close();
    }

    /**
     * Binds events to the dialog to handle the file copy and close buttons.
     *
     * This is called internally when the dialog is created.
     */
    bindEvents() {
        // Bail if this was called before
        if (this.dialog.classList.contains("bound")) {
            return;
        }

        // Do not allow the events to be bound twice
        this.dialog.classList.add("bound");

        this._cancelButton.addEventListener("click", this.close.bind(this));
        this._copyButton.addEventListener("click", this.copy.bind(this));

        // Bind to the change event of the file list
        // This fires when something new is selected
        this._fileList.on('change', (item) => {
            let info = this._fileList.infoFor(item);
            this._selected = info;
            this._copyButton.removeAttribute('disabled');
        });
    }
}

export default CopyDialog;
