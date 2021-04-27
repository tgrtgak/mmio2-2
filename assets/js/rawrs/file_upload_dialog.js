"use strict";

import Dialog from './dialog';

/**
 * Represents the file upload dialog.
 */
class FileUploadDialog extends Dialog {
    /**
     * Opens a file upload dialog to select files to upload.
     */
    constructor() {
        super('dialog-upload-files');

        // Show the dialog
        this.open();

        // Stores each preview file queued during file uploading
        this._previewFiles = [];

        // Get the table body to add the file rows to
        this._dropPreviews = this.dialog.querySelector(".drop-previews");

        // Bind the specific events for the dialog
        this.bindEvents();
    }

    /**
     * Fires the upload event to upload the current list of files.
     *
     * It will close the dialog after the files are uploaded.
     */
    async upload() {
        // Trigger the upload event.
        await this.trigger('upload', this._previewFiles);

        // Removes all of the file preview rows.
        let previewRows = this._dropPreviews.querySelectorAll(".drop-preview");
        previewRows.forEach( (preview) => preview.click());

        // Closes modal upon successful completion.
        this.close();
    }

    /**
     * Creates a preview file and adds it to the modal.
     * 
     * @param {File} file The file from the user.
     */
    addFile(file) {
        // Creates the file preview as it is stored on host computer.
        let filePreview = document.createElement("tr");
        filePreview.classList.add('drop-preview');

        let fileNameCell = document.createElement("td");
        fileNameCell.textContent = file.name;
        fileNameCell.classList.add('file-name');
        filePreview.appendChild(fileNameCell);

        let fileSizeCell = document.createElement("td");
        fileSizeCell.textContent = this.displayBytes(file.size);
        fileSizeCell.classList.add('file-size');
        filePreview.appendChild(fileSizeCell);

        this._dropPreviews.appendChild(filePreview);

        // Removes the file preview if it is clicked.
        filePreview.addEventListener("click", () => {
            this._dropPreviews.removeChild(filePreview);
            let index = this._previewFiles.indexOf(file);

            if (index != -1) {
                this._previewFiles.splice(index, 1);
            }

            // Display the drag & drop box if this is the last file being removed.
            if (!this._previewFiles.length) {
                this.dialog.querySelector(".upload-zone .drop-area-header").removeAttribute('hidden');
                this.dialog.querySelector(".upload-zone .drop-area-caption").removeAttribute('hidden');
                this.dialog.querySelector(".upload-zone span.preview-message").setAttribute('hidden', '');

                // Disable the upload button with an empty list
                this.dialog.querySelector("#button-complete-upload").setAttribute('disabled', '');
            }
        });

        this._dropPreviews.appendChild(filePreview);
        this._previewFiles.push(file);
    }

    /**
     * Adds preview files that are drag-and-dropped.
     * 
     * @param {Event} event The drop event to be handled.
     */
    handleDrop(event) {
        //Prevents the file from opening in another tab.
        event.preventDefault();
        
        //Access the file(s) using DataTransferItemList interface.
        if (event.dataTransfer.items) {
            for (var i = 0; i < event.dataTransfer.items.length; i++) {
                if (event.dataTransfer.items[i].kind === 'file') {
                    let file = event.dataTransfer.items[i].getAsFile();
                    this.addFile(file);
                }
            }
        } 
        
        // Otherwise, access the file(s) using DataTransfer interface.
        else {
            for (var i = 0; i < event.dataTransfer.files.length; i++) {
                this.addFile(event.dataTransfer.files[i]);
            }
        }

        // Removes the file dropdown box, if still there, after file(s) added.
        this.dialog.querySelector(".upload-zone .drop-area-header").setAttribute('hidden', '');
        this.dialog.querySelector(".upload-zone .drop-area-caption").setAttribute('hidden', '');
        this.dialog.querySelector(".upload-zone span.preview-message").removeAttribute('hidden');

        // Enable the upload button
        this.dialog.querySelector("#button-complete-upload").removeAttribute('disabled');
    }

    /**
     * Enables custom behavior when files are dragged over the modal.
     * 
     * @param {Event} event The dragover event to be handled.
     */
    handleDragover(event) {
        event.preventDefault();
    }

    /**
     * Adds preview files when the file input field changes.
     */
    handleChange() {
        // Adds each file collected from the files object from input.
        let input = this._dialog.querySelector("input#input-choose-files");
        let files = input.files;
        for (let i = 0; i < files.length; ++i) {
            this.addFile(files[i]);
        }

        input.value = null;

        // Removes the file dropdown box, if still there, after file(s) added.
        let dropArea = this._dialog.querySelector(".upload-zone > label.drop-area");
        if (dropArea.style.display !== 'none') {
            dropArea.style.display = "none";
            this._dropPreviews.style.display = "block";
            this._dialog.querySelector(".upload-zone > label.drop-preview-message").style.display = "block";
        }
    }

    /**
     * Binds events to the dialog to handle the file upload listing and buttons.
     *
     * This is called internally when the dialog is created.
     */
    bindEvents() {
        // Bind events to the file upload modal.
        this.dialog.addEventListener("drop", this.handleDrop.bind(this));
        this.dialog.addEventListener("dragover", this.handleDragover.bind(this));

        let dropArea = this.dialog.querySelector("#input-choose-files");
        dropArea.addEventListener("change", this.handleChange.bind(this));

        let cancelButton = this.dialog.querySelector("#button-cancel-upload");
        cancelButton.addEventListener("click", this.close.bind(this));

        let uploadButton = this.dialog.querySelector("#button-complete-upload");
        uploadButton.addEventListener("click", this.upload.bind(this));
    }

    /**
     * Displays bytes in terms of larger units if possible up to 2 decimal places.
     * 
     * @param {Number} bytes The number of bytes.
     * @returns {string} The display of the number of bytes.
     */
    displayBytes(bytes) {
        const power = Math.floor(Math.log(Math.max(bytes, 1)) / Math.log(1024));

        // Realistically will not encounter terabytes or more being uploaded.
        return (bytes / Math.pow(1024, power)).toFixed(2) + ' ' + ['B', 'KB', 'MB', 'GB'][power];
    }
}

export default FileUploadDialog;
