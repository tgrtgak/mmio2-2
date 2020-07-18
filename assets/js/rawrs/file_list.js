"use strict";

import EventComponent from './event_component.js';
import LocalStorage from './local_storage.js';

class FileList extends EventComponent {
    /**
     * Create a new instance of a file list for the given root element.
     *
     * @param {HTMLElement} root The element to look for the file list within.
     */
    constructor(root) {
        super();

        this._element = root.querySelector(".project-pane");
        this._storage = new LocalStorage();

        // Bind events to built-in files
        var files = this._element.querySelectorAll("li.file");
        this._activeItem = null;
        files.forEach( (item) => {
            this.bind(item);
        });

        // Bind events to built-in directories
        var directories = this._element.querySelectorAll("li.directory");
        directories.forEach( (item) => {
            this.bind(item);
        });

        // Read the root directory of our storage and add the files
        let localRoot = this._element.querySelector("li.directory.root > ol");
        this.readDirectory(this._storage.list(""), localRoot);
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
        if (window.localStorage.startupFile) {
            return window.localStorage.startupFile;
        }

        return "files/examples/hello/hello.s";
    }

    /**
     * Sets the file that should be loaded at startup.
     *
     * @param {string} path The filename to open.
     */
    set startupFile(path) {
        window.localStorage.startupFile = path;
    }

    /**
     * Gets the element of the item used for the initial file.
     *
     * @returns {HTMLElement} The startup item, if found.
     */
    get startupItem() {
        let path = this.startupFile;
        if (path[0] == '/') {
            // Ensure the file exists in the listing
            let parts = path.substring(1).split('/');
            let subpath = "";

            parts.slice(0, parts.length - 1).forEach( (directory) => {
                subpath = subpath + "/" + directory;
                let item = this._element.querySelector("li[data-path=\"" + subpath + "\"]");
                this.open(item);
            });

            // Open the file entry
            return this._element.querySelector("li[data-path=\"" + this.startupFile + "\"]");
        }
        else {
            return this._element.querySelector("li[data-url=\"" + this.startupFile + "\"]");
        }
    }

    /**
     * Binds events on the given list item.
     */
    bind(item) {
        if (item.classList.contains("file")) {
            item.addEventListener('click', (event) => {
                this.loadItem(item);

                event.stopPropagation();
                event.preventDefault();
            });
        }
        else if (item.classList.contains("directory")) {
            item.addEventListener('click', (event) => {
                if (this.isOpen(item)) {
                    this.close(item);
                }
                else {
                    this.open(item);
                }

                event.stopPropagation();
                event.preventDefault();
            });
        }
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
            // -1 moves the cursor to the start (without this,
            // it will select the entire text... I dunno)
            window.editor.setValue(text, -1);
            window.editor.getSession().setUndoManager(new window.ace.UndoManager());
        });
    }

    /**
     * Opens the directory provided by the given element.
     *
     * @param {HTMLElement} item The list item to treat as a directory.
     */
    open(item) {
        item.classList.add('open');

        // Is this a local directory?
        if (item.hasAttribute('data-path')) {
            // Read the contents, if we need to do so.
            let itemRoot = item.querySelector('ol');
            let path = item.getAttribute('data-path');
            if (itemRoot.children.length == 0) {
                let listing = this._storage.list(path);
                this.readDirectory(listing, itemRoot, path);
            }
        }
    }

    /**
     * Closes the directory provided by the given element.
     *
     * @param {HTMLElement} item The list item to treat as a directory.
     */
    close(item) {
        item.classList.remove('open');
    }

    /**
     * Returns whether or not the provided directory is open.
     *
     * @param {HTMLElement} item The list item to treat as a directory.
     */
    isOpen(item) {
        return item.classList.contains("open");
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

        // Ensure all directories to this file are open
        let current = item.parentNode;
        while (current && current.classList) {
            if (current.classList.contains("directory")) {
                this.open(current);
            }
            current = current.parentNode;
        }

        this._activeItem = item;
        item.classList.add('active');

        // Load the file
        if (item.hasAttribute('data-path')) {
            let path = item.getAttribute('data-path');
            let text = this._storage.load(path);

            // -1 moves the cursor to the start (without this,
            // it will select the entire text... I dunno)
            window.editor.setValue(text, -1);
            window.editor.getSession().setUndoManager(new window.ace.UndoManager());

            this.startupFile = path;
        }
        else {
            var url = item.getAttribute('data-url');
            this.load(url);

            this.startupFile = url;
        }
    }

    /**
     * Generates a directory or file element for the given item.
     *
     * @param {Object} item The item information.
     */
    newItem(item) {
        let template = document.querySelector("template." + item.type);
        let element = template;
        if ('content' in template) {
            element = document.importNode(template.content, true);
            element = element.querySelector("li");
        }
        else {
            element = template.querySelector("li").cloneNode(true);
        }

        // Set name
        element.querySelector("span.name").textContent = item.name;

        // Bind events
        this.bind(element);

        // Return new item
        return element;
    }

    /**
     * Reads the given directory listing and generates the listing within the app.
     *
     * @param {Array} listing The list of items in the directory.
     * @param {HTMLElement} rootElement The directory element to which to add
     *                                  the items.
     */
    readDirectory(listing, rootElement, path) {
        path = path || "";

        listing.forEach( (item) => {
            let itemElement = this.newItem(item);
            itemElement.setAttribute('data-path', path + '/' + item.name);
            rootElement.appendChild(itemElement);
        });
    }
}

export default FileList;
