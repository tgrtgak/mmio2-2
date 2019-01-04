"use strict";

import EventComponent from './event_component';

class FileList extends EventComponent {
    /**
     * Create a new instance of a file list for the given root element.
     *
     * @param {HTMLElement} root The element to look for the file list within.
     */
    constructor(root) {
        super();

        this._element = root.querySelector(".project-pane");

        var files = this._element.querySelectorAll("li.file");
        this._activeItem = null;
        files.forEach( (item) => {
            item.addEventListener('click', (event) => {
                this.loadItem(item);

                event.stopPropagation();
                event.preventDefault();
            });
        });
    }

    /**
     * Returns the element associated with this file list.
     *
     * @returns {HTMLElement} The element for this file list.
     */
    get element() {
        return this._element;
    }

    /**
     * Gets the URL of the startup file.
     *
     * @returns {string} The URL of the file to load on startup.
     */
    get startupFile() {
        return "files/hello.s";
    }

    /**
     * Gets the element of the item used for the initial file.
     *
     * @returns {HTMLElement} The startup item, if found.
     */
    get startupItem() {
        return this._element.querySelector("li[data-url=\"" + this.startupFile + "\"");
    }

    /**
     * Loads the given file.
     *
     * @param {string} url The URL of the file to load.
     */
    load(url) {
        fetch(url, {
            credentials: 'include'
        }).then(function(response) {
            return response.text();
        }).then(function(text) {
            window.editor.setValue(text, -1); // -1 moves the cursor to the start (without this,
            // it will select the entire text)
            window.editor.getSession().setUndoManager(new window.ace.UndoManager());
        });
    }
    
    /**
     * Loads the item provided by the given element.
     *
     * @param {HTMLElement} item The list item to use.
     */
    loadItem(item) {
        if (this._activeItem) {
            this._activeItem.classList.remove('active');
        }

        this._activeItem = item;
        item.classList.add('active');

        // Load the file
        var url = item.getAttribute('data-url');

        this.load(url);
    }
}

export default FileList;
