"use strict";

/**
 * This class manages the files stored in local storage.
 */
class LocalStorage {
    /**
     * Creates a new instance representing our local storage.
     */
    constructor() {
    }

    /**
     * Saves the given file data to the provided path.
     *
     * @param {string} path The path for the file.
     * @param {string} data The text for the file.
     */
    async save(path, data) {
        let tag = "files";
        let directory = JSON.parse((await this.retrieve('files')) || "[]");
        let current = "";

        // Split path
        let parts = path.split('/');
        for (var i = 0; i < parts.length; i++) {
            let part = parts[i];
            current = current + "/" + part;

            if (i == (parts.length - 1)) {
                let directoryTag = 'file-' + part;
                if (!directory.includes(directoryTag)) {
                    // Add file to current directory
                    directory.push(directoryTag);
                    await this.store(tag, JSON.stringify(directory));
                }

                // Store the file
                await this.store('file-' + current, data);
            }
            else {
                let directoryTag = 'directory-' + part;
                if (!directory.includes(directoryTag)) {
                    // Add directory to current directory
                    directory.push(directoryTag);
                    await this.store(tag, JSON.stringify(directory));
                }

                // Get next directory
                tag = 'directory-' + current;
                directory = JSON.parse((await this.retrieve(tag)) || "[]");
            }
        };
    }

    /**
     * Low-level function to connect to a database.
     */
    async connect() {
        if (!this._connectPromise) {
            this._connectPromise = new Promise( (resolve, reject) => {
                var indexedDB = window.indexedDB || window.webkitIndexedDB ||
                                window.mozIndexedDB || window.OIndexedDB ||
                                window.msIndexedDB;
                var dbVersion = 2;

                if (!indexedDB) {
                    reject();
                    return;
                }

                let request = indexedDB.open("rawrs", dbVersion);

                request.onerror = (event) => {
                    reject();
                };

                request.onsuccess = (event) => {
                    this._connection = request.result;

                    // Sometimes we create the datastore here instead of
                    // on the 'onupgradeneeded' event
                    if (this._connection.setVersion) {
                        if (this._connection.version != dbVersion) {
                            var setVersion = this._connection.setVersion(dbVersion);
                            setVersion.onsuccess = () => {
                                this._connection.createObjectStore("files");
                                resolve(this._connection);
                            };

                            setVersion.onerror = (event) => {
                                reject(event);
                            };
                        }
                    }
                    else {
                        resolve(this._connection);
                    }
                };

                // Create the datastore
                request.onupgradeneeded = (event) => {
                    this._connection = event.target.result;
                    this._connection.createObjectStore("files");
                };
            });
        }

        return this._connectPromise;
    }
    
    /**
     * Low-level function that clears the entire file system.
     */
    async clear() {
        try {
            // IndexedDB
            let db = await this.connect();
            let transaction = db.transaction(["files"], "readwrite");
            return await new Promise( (resolve, reject) => {
                let objects = transaction.objectStore("files");
                let request = objects.clear();
                request.onsuccess = (event) => {
                    resolve();
                };
            });
        }
        catch (error) {
            // Local Storage
            window.localStorage.clear();
        }
    }

    /**
     * Low-level function to store data into the provided key.
     */
    async store(key, data) {
        try {
            // IndexedDB
            let db = await this.connect();
            let transaction = db.transaction(["files"], "readwrite");
            return await new Promise( (resolve, reject) => {
                let objects = transaction.objectStore("files");
                let put = objects.put(data, key);
                put.onsuccess = (event) => {
                    resolve();
                };
            });
        }
        catch (error) {
            // Local Storage
            window.localStorage["rawrs-" + key] = data;
        }
    }

    /**
     * Low-level function to retrieve the data from the provided key.
     */
    async retrieve(key) {
        try {
            // IndexedDB
            let db = await this.connect();
            let transaction = db.transaction(["files"], "readonly");
            return await new Promise( (resolve, reject) => {
                let request = transaction.objectStore("files").get(key);
                request.onsuccess = (event) => {
                    resolve(event.target.result);
                };
                request.onerror = (event) => {
                    reject(event);
                };
            });
        }
        catch (error) {
            // Local Storage
            return window.localStorage["rawrs-" + key];
        }
    }

    /**
     * Low-level function to delete data stored at the provided key.
     */
    async purge(key) {
        try {
            // IndexedDB
            let db = await this.connect();
            let transaction = db.transaction(["files"], "readwrite");
            return await new Promise( (resolve, reject) => {
                let objects = transaction.objectStore("files");
                objects.delete(data, key).onsuccess = (event) => {
                    resolve();
                };
            });
        }
        catch (error) {
            // Local Storage
            window.localStorage.removeItem("rawrs-" + key);
        }
    }

    /**
     * Loads the given path.
     *
     * @returns string The file data.
     */
    async load(path) {
        return await this.retrieve('file-' + path);
    }

    /**
     * Deletes the file at the given path.
     *
     * Recursively deletes any empty directories.
     *
     * @param {string} path The path of the file to remove.
     * @param {string} type Whether or not this is a file or directory.
     */
    async remove(path, type = 'file') {
        this.purge(type + '-' + path);

        let last = path.lastIndexOf('/');
        if (last > 0) {
            let name = path.substring(last + 1);
            path = path.substring(0, last);

            let listing = await this.list(path);

            // Remove the file from the listing
            listing.splice(listing.indexOf(type + '-' + name));
            await this.store('directory-' + path, JSON.stringify(listing));

            // If the directory is empty... remove it as well, recursively
            if (listing.length == 0) {
                await this.remove(path, 'directory');
            }
        }
    }

    /**
     * Lists the files in the given path.
     *
     * @param {string} path The path to list.
     */
    async list(path) {
        let listing = [];
        if (path === undefined || path === "" || path === "/") {
            let data = await this.retrieve('files');
            data = data || "[]";
            listing = JSON.parse(data);
        }
        else {
            listing = JSON.parse(await this.retrieve('directory-' + path));
        }

        listing = listing.map( (tag) => {
            if (tag.startsWith("file-")) {
                return {
                    name: tag.substring(5),
                    type: 'file'
                };
            }
            else {
                return {
                    name: tag.substring(10),
                    type: 'directory'
                };
            }
        });

        return listing;
    }
}

export default LocalStorage;
