"use strict";

import EventComponent from './event_component.js';
import FileSystem from './file_system.js';
import Dropdown from './dropdown.js';
import Util from './util.js';
import JSZip from 'jszip';
import FileSaver from 'file-saver';
import Editor from './editor';
import FileUploadDialog from './file_upload_dialog';

/**
 * This represents the file listing.
 */
class FileList extends EventComponent {
    /**
     * Create a new instance of a file list for the given root element.
     *
     * @param {HTMLElement} root The element to look for the file list within.
     */
    constructor(root, editor) {
        super();

        this._element = root.querySelector(".project-pane");
        this._storage = new FileSystem();

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

        // Bind event to the new project button
        this._newProjectItem = this._element.querySelector("li.action[data-action=\"new-project\"]");
        if (this._newProjectItem) {
            let newProjectButton = this._newProjectItem.querySelector("button");
            newProjectButton.addEventListener("click", (event) => {
                this._newProjectItem.setAttribute("hidden", "");

                let newProjectInputItem = this._newProjectItem.parentNode.querySelector("li.directory.new");
                if (newProjectInputItem) {
                    newProjectInputItem.removeAttribute("hidden");
                    let newProjectInput = newProjectInputItem.querySelector("input");
                    newProjectInput.focus();
                    newProjectInput.select();
                }

                event.stopPropagation();
                event.preventDefault();
            });
        }
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
        if (Util.getParameterByName("open")) {
            return Util.getParameterByName("open");
        }

        if (window.localStorage.rawrsStartupFile) {
            return window.localStorage.rawrsStartupFile;
        }

        return "files/examples/hello/hello.s";
    }

    /**
     * Sets the file that should be loaded at startup.
     *
     * @param {string} path The filename to open.
     */
    set startupFile(path) {
        window.localStorage.rawrsStartupFile = path;
    }

    /**
     * Gets the element of the item used for the initial file.
     *
     * @returns {HTMLElement} The startup item, if found.
     */
    get startupItem() {
        let path = this.startupFile;
        return this.itemFor(path);
    }

    /**
     * Initializes the root directory from local storage.
     */
    async loadRoot() {
        let listing = await this._storage.list("");

        // Read the root directory of our storage and add the files
        let localRoot = this._element.querySelector("li.directory.root > ol");

        // Read and initialize the root directory
        this.readDirectory(listing, localRoot);
    }

    /**
     * Loads the file or directory given in path and all subdirectories.
     */
    async revealPath(path, root = "/") {
        let base = path;

        // A built in path instead.
        let builtIn = false;
        if (path && path[0] != "/") {
            base = "/" + path;
            builtIn = true;
        }
        else {
            // Ensure root directory is open
            await this.open(this._element.querySelector("li.directory.root"));
        }

        // Ensure the file exists in the listing
        let index = base.indexOf('/', root.length + 1);
        if (index == -1) {
            return;
        }

        let directory = base.substring(0, index);

        // Open that item
        let item = this._element.querySelector("li.directory[data-path=\"" + btoa(directory) + "\"]");
        if (item) {
            await this.open(item);

            // Open the subitem (recursively)
            await this.revealPath(base, directory);
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

            let fileNamePlace = item.querySelector("span.name");
            let oldFileName = fileNamePlace.textContent;
            let renameFileInput = item.querySelector(".info > input");
            let dataPath = atob(item.getAttribute('data-path'));

            if (renameFileInput) {
                renameFileInput.addEventListener("blur", (event) => {
                    renameFileInput.style.display = "none";
                    fileNamePlace.style.display = "inline";
                });

                renameFileInput.addEventListener("keydown", async (event) => {
                    if (event.key === "Escape") {
                        renameFileInput.style.display = "none";
                        fileNamePlace.style.display = "inline";
                    }

                    // Rename the file.
                    else if (event.key === "Enter") {
                        await this.revealPath(dataPath);
                        const data = await this._storage.load(dataPath);

                        // Removes file with old name.
                        await this._storage.remove(dataPath);
                        item.parentNode.removeChild(item);

                        let newName = renameFileInput.value;

                        if (!newName.includes(".")) {
                            newName += ".s";
                        }

                        // Saves the renamed file.
                        let directoryPath = dataPath.substring(0, dataPath.length - oldFileName.length - 1);
                        let newPath = directoryPath.substring(1) + "/" + newName;

                        await this._storage.save(newPath, data);

                        // Creates the renamed file item.
                        const newItem = {name: newName, type: "file"};
                        const itemElement = this.newItem(newItem, directoryPath);

                        // Adds the renamed file element to the DOM.
                        const parentDirectory = this.itemFor(directoryPath);
                        const parentListing = parentDirectory.querySelector(":scope > ol");
                        parentListing.appendChild(itemElement);
                    }
                });
            }
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

        // Bind inputs for creating directories/files
        if (item.classList.contains("new")) {
            let newDirectoryInput = item.querySelector(".info > input");
            if (newDirectoryInput) {
                newDirectoryInput.addEventListener("blur", (event) => {
                    item.setAttribute("hidden", "");
                    if (this._newProjectItem) {
                        this._newProjectItem.removeAttribute("hidden");
                    }
                });
                newDirectoryInput.addEventListener("keydown", (event) => {
                    if (event.key === "Escape") {
                        item.setAttribute("hidden", "");
                        if (this._newProjectItem) {
                            this._newProjectItem.removeAttribute("hidden");
                        }
                    }
                    else if (event.key === "Enter") {
                        item.setAttribute("hidden", "");
                        if (this._newProjectItem) {
                            this._newProjectItem.removeAttribute("hidden");
                        }

                        let name = newDirectoryInput.value;
                        let path = name + "/main.s";
                        this._storage.save(path, "").then( () => {
                            this.loadRoot().then( () => {
                                this.revealPath(path).then( () => {
                                    let item = this.itemFor("/" + path);
                                    if (item) {
                                        this.loadItem(item);
                                    }
                                });
                            });
                        });
                    }
                });
            }
        }

        // Bind dropdown events
        let actionButton = item.querySelector("button.actions");
        if (actionButton) {
            item.dropdown = new Dropdown(actionButton);
        }
    }

    /**
     * Saves the current file, if possible, with the provided data.
     */
    async save(data) {
        if (!this._activeItem) {
            return;
        }

        let item = this._activeItem;
        let path = item.getAttribute("data-path");

        if (!path) {
            // Cannot save
            return;
        }

        // Decode
        path = atob(path);

        if (path[0] !== "/") {
            // Cannot save
            return;
        }

        path = path.substring(1);

        this._storage.save(path, data);
    }

    /**
     * Loads the given file.
     *
     * @param {string} url The URL of the file to load.
     */
    async load(url) {
        let basepath = document.body.getAttribute('data-basepath');
        fetch(basepath + url, {
            credentials: 'include'
        }).then(function(response) {
            return response.text();
        }).then(function(text) {
            Editor.load(text);
        });
    }

    /**
     * Opens the directory provided by the given element.
     *
     * @param {HTMLElement} item The list item to treat as a directory.
     */
    async open(item) {
        if (item.classList.contains("new")) {
            return;
        }

        item.classList.add('open');

        // Is this a local directory?
        if (item.hasAttribute('data-path')) {
            // Read the contents, if we need to do so.
            let itemRoot = item.querySelector('ol');
            let path = atob(item.getAttribute('data-path'));

            if (itemRoot.children.length == 0) {
                let listing = await this._storage.list(path);

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
    async loadItem(item) {
        if (this._activeItem) {
            this._activeItem.classList.remove('active');
        }

        // Ensure all directories to this file are open
        let current = item.parentNode;
        while (current && current.classList) {
            if (current.classList.contains("directory")) {
                await this.open(current);
            }
            current = current.parentNode;
        }

        this._activeItem = item;
        item.classList.add('active');

        // Load the file
        if (item.hasAttribute('data-path')) {
            let path = atob(item.getAttribute('data-path'));
            let text = await this._storage.load(path);

            Editor.load(text);
            Editor.focus();

            this.startupFile = path;
        }
        else {
            var url = atob(item.getAttribute('data-url'));
            this.load(url);

            this.startupFile = url;
        }
    }

    /**
     * Generates a directory or file element for the given item.
     *
     * @param {Object} item The item information.
     */
    newItem(item, path) {
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

        // Update dropdown id
        let actionButton = element.querySelector("button.actions");
        let actionDropdown = element.querySelector("ul.dropdown-menu");

        let dropdownID = "dropdown-" + path.replace("/", "-");

        actionButton.setAttribute("aria-controls", dropdownID);
        actionDropdown.setAttribute("id", dropdownID);

        // Updates path itself.
        element.setAttribute('data-path', btoa(path + '/' + item.name));

        // Bind events
        this.bind(element);

        let dataPath = atob(element.getAttribute('data-path'));

        // Attaches event handlers to each dropdown button
        if (element.dropdown) {
            element.dropdown.on("click", async (action) => {
                switch(action) {
                    // "Copy to My Files" functionality
                    // Clones a preset directory or file element to user directory.
                    case "clone":
                        break;

                    // "Delete" functionality
                    // Deletes a directory or file element, and all of its contents.
                    case "delete":
                        // TODO: Disable the file listing during a delete action

                        // Deleting an individual file
                        await this.revealPath(path);

                        // Deletes the individual file.
                        await this._storage.remove(dataPath, item.type);

                        // Removes itself.
                        if (element.parentNode) {
                            element.parentNode.removeChild(element);
                        }

                        // TODO: Enable the file listing afterward
                        break;

                    // "Download" functionality
                    // Downloads a file element to the client.
                    case "download":
                        await this.revealPath(path);

                        // Loads the text of the file.
                        const data = await this._storage.load(dataPath);

                        // Creates and downloads the text blob to the client.
                        const dataBlob = new Blob([data], {type: "text/plain;charset=utf-8"});
                        await FileSaver.saveAs(dataBlob, item.name);

                        break;

                    // "Download ZIP" functionality
                    // Downloads a directory as a ZIP file, and all of its contents, to the client.
                    case "downloadzip":
                        let zip = new JSZip();

                        await this.revealPath(path);

                        // Collects every directory and file element.
                        const listing = await this._storage.list(dataPath);

                        for (const entry of listing) {
                            if (entry.type === 'file') {
                                // Loads the text of the file.
                                const data = await this._storage.load(dataPath + '/' + entry.name);

                                // Stores the file,
                                // Creates any subdirectories implicitly.
                                await zip.file(entry.name, data, {
                                    createFolders: true
                                });
                            }
                        }

                        // Compresses every file in the directory.
                        const content = await zip.generateAsync({
                            type: "blob",
                            compression: "DEFLATE"
                        });

                        // Downloads the directory to the client.
                        await FileSaver.saveAs(content, dataPath.substring(1) + ".zip");
                        break;

                    // "Rename" functionality
                    // Renames the path of the file element.
                    case "rename":
                        element.dropdown.fileRename = element.querySelector("span.info > input");
                        element.dropdown.fileNamePlace = element.querySelector("span.name");
                        element.dropdown.fileRename.value = item.name;
                        break;

                    // "Upload Files" functionality
                    // Shows the modal wherein the user may upload file(s) to the given directory.
                    case "upload":
                        let fileUploadDialog = new FileUploadDialog(dataPath);
                        fileUploadDialog.on('upload', async (files) => {
                            for (const file of files) {
                                const fileData = await file.text();
                                const filePath = dataPath + "/" + file.name;

                                // Places the item only if it does not already exist in the given directory.
                                const existingItem = this.itemFor(filePath);
                                if (!existingItem) {
                                    // Saves the file and its contents.
                                    await this._storage.save(filePath.substring(1), fileData);

                                    // Creates the file item.
                                    const newItem = {name: file.name, type: "file"};
                                    const itemElement = this.newItem(newItem, dataPath);

                                    // Adds file element to the DOM.
                                    const parentDirectory = this.itemFor(dataPath);
                                    const parentListing = parentDirectory.querySelector(":scope > ol");
                                    parentListing.appendChild(itemElement);
                                }
                            }
                        });
                        break;

                    default:
                        // Unknown action
                        throw "Unknown dropdown file action";
                        break;
                }
            })
        }

        // Return new item
        return element;
    }

    /**
     * Retrieves the item element for the given path.
     */
    itemFor(path) {
        if (path[0] == '/') {
            return this._element.querySelector("li[data-path=\"" + btoa(path) + "\"]");
        }
        return this._element.querySelector("li[data-url=\"" + btoa(path) + "\"]");
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
            let existingItem = this.itemFor(path + "/" + item.name);
            if (!existingItem) {
                let itemElement = this.newItem(item, path);
                rootElement.appendChild(itemElement);
            }
        });
    }
}

export default FileList;
