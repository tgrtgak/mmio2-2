"use strict";

/**
 * This class manages the files stored in local storage.
 */
class LocalStorage {
    /**
     * Saves the given file data to the provided path.
     *
     * @param {string} path The path for the file.
     * @param {string} data The text for the file.
     */
    save(path, data) {
        let tag = "files";
        let directory = JSON.parse(window.localStorage.files || "[]");
        let current = "";

        // Split path
        let parts = path.split('/');
        parts.forEach( (part, i) => {
            current = current + "/" + part;

            if (i == (parts.length - 1)) {
                let directoryTag = 'file-' + part;
                if (!directory.includes(directoryTag)) {
                    // Add file to current directory
                    directory.push(directoryTag);
                    window.localStorage[tag] = JSON.stringify(directory);
                }

                // Store the file
                window.localStorage['file-' + current] = data;
            }
            else {
                let directoryTag = 'directory-' + part;
                if (!directory.includes(directoryTag)) {
                    // Add directory to current directory
                    directory.push(directoryTag);
                    window.localStorage[tag] = JSON.stringify(directory);
                }

                // Get next directory
                tag = 'directory-' + current;
                directory = JSON.parse(window.localStorage[tag] || "[]");
            }
        });
    }

    /**
     * Loads the given path.
     *
     * @returns string The file data.
     */
    load(path) {
        return window.localStorage['file-' + path];
    }

    /**
     * Deletes the file at the given path.
     *
     * Recursively deletes any empty directories.
     *
     * @param {string} path The path of the file to remove.
     * @param {string} type Whether or not this is a file or directory.
     */
    remove(path, type = 'file') {
        window.localStorage.removeItem(type + '-' + path);

        let last = path.lastIndexOf('/');
        if (last > 0) {
            let name = path.substring(last + 1);
            path = path.substring(0, last);

            let listing = this.list(path);
            
            // Remove the file from the listing
            listing.splice(listing.indexOf(type + '-' + name));
            window.localStorage['directory-' + path] = JSON.stringify(listing);

            // If the directory is empty... remove it as well, recursively
            if (listing.length == 0) {
                this.remove(path, 'directory');
            }
        }
    }

    /**
     * Lists the files in the given path.
     *
     * @param {string} path The path to list.
     */
    list(path) {
        let listing = [];
        if (path === undefined || path === "" || path === "/") {
            listing = JSON.parse(window.localStorage.files || "[]");
        }
        else {
            listing = JSON.parse(window.localStorage['directory-' + path]);
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
