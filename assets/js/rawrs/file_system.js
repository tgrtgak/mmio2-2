"use strict";

// Import localForage to unify data backends
import localForage from 'localforage';

/**
 * This class manages the local file system.
 */
class FileSystem {
    /**
     * Creates a new instance representing our local file storage.
     */
    constructor() {
        localForage.config({
            name: 'rawrs',
            version: 1.0,
            storeName: 'rawrs-file-system',
            description: 'The RAWRS local file system.'
        });
    }

    /**
     * Saves the given file data to the provided path.
     *
     * @param {string} path The path for the file.
     * @param {string} data The text for the file.
     */
    async save(path, data) {
        let tag = "files";
        let directory = (await this.retrieve('files')) || [];
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
                    await this.store(tag, directory);
                }

                // Store the file
                await this.store('file-' + current, data);
            }
            else {
                let directoryTag = 'directory-' + part;
                if (!directory.includes(directoryTag)) {
                    // Add directory to current directory
                    directory.push(directoryTag);
                    await this.store(tag, directory);
                }

                // Get next directory
                tag = 'directory-' + current;
                directory = (await this.retrieve(tag)) || [];
            }
        };
    }

    /**
     * Low-level function that clears the entire file system.
     */
    async clear() {
        return localForage.clear();
    }

    /**
     * Low-level function to store data into the provided key.
     */
    async store(key, data) {
        return localForage.setItem(key, data);
    }

    /**
     * Low-level function to retrieve the data from the provided key.
     */
    async retrieve(key) {
        console.log("retrieving", key);
        return localForage.getItem(key);
    }

    /**
     * Low-level function to delete data stored at the provided key.
     */
    async purge(key) {
        return localForage.removeItem(key);
    }

    /**
     * Loads the given path.
     *
     * @returns string The file data.
     */
    async load(path) {
        return this.retrieve('file-' + path);
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
        console.log('wait');
        // If this is a directory, remove each file within
        if (type == 'directory') {
            let listing = await this.list(path);

            console.log('removing files within', path);
            for (const info of listing) {
                await this.remove(path + '/' + info.name, info.type);
            }
            console.log('done removing files within', path);
        }

        // Remove the given path
        console.log("removing", type, path);
        await this.purge(type + '-' + path);

        let last = path.lastIndexOf('/');
        let name = path.substring(last + 1);
        path = path.substring(0, last);

        let token = 'directory-' + path;
        if (path == '') {
            // Remove from root
            token = 'files';
        }
        let listing = await this.retrieve(token);

        // Remove the file from the listing
        listing.splice(listing.indexOf(type + '-' + name), 1);
        await this.store(token, listing);
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
            data = data || [];
            listing = data;
        }
        else {
            listing = await this.retrieve('directory-' + path);
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

export default FileSystem;
