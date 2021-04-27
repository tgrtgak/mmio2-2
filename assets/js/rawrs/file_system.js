"use strict";

// Import localForage to unify data backends
import localForage from 'localforage';

/**
 * This class manages the local file system.
 *
 * Directories are stored as dictionaries where the key is the name of the file
 * or subdirectory. The data at that key is a dictionary with a 'type' field
 * which is 'directory' or 'file' depending on its type, and a 'token' field
 * that indicates where the data is stored. If it is a 'directory', then the
 * data is another dictionary.
 *
 * The roor is stored at the '/' key.
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

        // Install a global to clear the filesystem for dev access
        window.clearRAWRSFS = function() {
            this.clear();
        }.bind(this);
    }

    /**
     * Produces a string-based token that is unique.
     */
    token() {
        return (Date.now() + Math.random()).toString();
    }

    /**
     * Saves the given file data to the provided path.
     *
     * @param {string} path The path for the file.
     * @param {string} data The text for the file.
     */
    async save(path, data) {
        if (path[0] != '/') {
            path = "/" + path;
        }

        // Start at the root and get its listing
        let directoryToken = '/';
        let directory = (await this.retrieve(directoryToken)) || {};

        // Split path into the subdirectories (and eventual file name we want)
        let parts = path.substring(1).split('/');
        for (let i = 0; i < parts.length; i++) {
            let part = parts[i];
            if (i == (parts.length - 1)) {
                // We are storing a file. Does it exist?
                if (!directory[part]) {
                    let token = this.token();

                    // Add file to current directory
                    directory[part] = {
                        type: 'file',
                        token: token
                    };

                    // Update the directory
                    await this.store(directoryToken, directory);
                }

                // Store the file
                await this.store(directory[part].token, data);
                return directory[part].token;
            }
            else {
                // A directory. We need to update our listing to find the
                // next directory.
                if (!directory[part]) {
                    let token = this.token();

                    // Add directory to current directory
                    directory[part] = {
                        type: 'directory',
                        token: token
                    };

                    // Add the empty directory
                    await this.store(token, {});

                    // Update the containing directory
                    await this.store(directoryToken, directory);
                }

                // Get next directory
                if (directory[part].type != 'directory') {
                    // It is not a directory, but it must be. So bail.
                    return null;
                }

                // Retrieve the data/token and keep going
                directoryToken = directory[part].token;
                directory = await this.retrieve(directoryToken);
            }
        }
    }

    /**
     * Moves a file or directory from the given old to new path.
     */
    async move(path, newPath) {
        if (path[0] != '/') {
            path = "/" + path;
        }

        if (newPath[0] != '/') {
            newPath = "/" + newPath;
        }

        // We need to locate the directory containing 'path'
        let parts = path.substring(1).split('/');
        let directoryPath = parts.slice(0, parts.length - 1).join('/') || '/';
        let fileName = parts[parts.length - 1];

        let directoryToken = null;
        if (!directoryToken) {
            directoryToken = await this.locate(directoryPath);
        }

        // Pull up the directory listing for this directory to find the source
        let directory = await this.load(directoryPath, directoryToken);

        // Bail if the source does not exist
        if (!directory[fileName]) {
            return null;
        }

        // Now we look up the destination path
        parts = newPath.substring(1).split('/');
        let destDirectoryPath = parts.slice(0, parts.length - 1).join('/') || '/';
        let destFileName = parts[parts.length - 1];

        let destDirectoryToken = null;
        if (!destDirectoryToken) {
            destDirectoryToken = await this.locate(destDirectoryPath);
        }

        // Bail if the destination path does not exist
        if (!destDirectoryToken) {
            return null;
        }

        // Get the source file metadata
        let metadata = directory[fileName];

        // Delete the source file entry
        delete directory[fileName];

        // Store the source directory again
        await this.store(directoryToken, directory);

        // Pull up the directory listing for this directory to find the source
        let destDirectory = await this.load(destDirectoryPath, destDirectoryToken);

        // Add the file to the destination directory
        destDirectory[destFileName] = metadata;

        // Store the destination directory again
        await this.store(destDirectoryToken, destDirectory);

        // Return the file token
        return metadata.token;
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
        return localForage.getItem(key);
    }

    /**
     * Low-level function to delete data stored at the provided key.
     */
    async purge(key) {
        return localForage.removeItem(key);
    }

    /**
     * Locates the token for the given path.
     */
    async locate(path) {
        if (path[0] != '/') {
            path = "/" + path;
        }

        // Start at the root and get its listing
        let directoryToken = '/';
        let directory = (await this.retrieve(directoryToken)) || {};

        // Just return the root directory data if requested.
        if (path == '/') {
            return directoryToken;
        }

        // Split path into the subdirectories (and eventual file name we want)
        let parts = path.substring(1).split('/');
        for (let i = 0; i < parts.length; i++) {
            let part = parts[i];
            if (i == (parts.length - 1)) {
                // We are reading the file. Does it exist?
                if (!directory[part]) {
                    return null;
                }

                // Return the token
                return directory[part].token;
            }
            else {
                // A directory. Does the subdirectory exist?
                if (!directory[part]) {
                    // Does not exist, therefore the file doesn't either
                    return null;
                }

                // Get next directory
                if (directory[part].type != 'directory') {
                    // It is not a directory, but it must be. So bail.
                    return null;
                }

                directoryToken = directory[part].token;
                directory = await this.retrieve(directoryToken);
            }
        }
    }

    /**
     * Loads the given path.
     *
     * @returns string The file data.
     */
    async load(path, token) {
        if (!token) {
            token = await this.locate(path);
        }

        return await this.retrieve(token);
    }

    /**
     * Deletes the file at the given path.
     *
     * Recursively deletes any empty directories.
     *
     * @param {string} path The path of the file to remove.
     */
    async remove(path, directoryToken) {
        if (path[0] != '/') {
            path = "/" + path;
        }

        let parts = path.substring(1).split('/');
        let directoryPath = parts.slice(0, parts.length - 1).join('/') || '/';
        let fileName = parts[parts.length - 1];

        if (!directoryToken) {
            directoryToken = await this.locate(directoryPath);
        }

        let directory = await this.load(directoryPath, directoryToken);

        // Look for the file in the directory and remove it
        if (directory[fileName]) {
            // Get the file token
            let token = directory[fileName].token;

            // If it is a directory, recursively delete everything in it
            if (directory[fileName].type == 'directory') {
                let subdirectory = await this.load(path, token);
                let names = Object.keys(subdirectory);
                for (let i = 0; i < names.length; i++) {
                    let name = names[i];
                    await this.remove(path + '/' + name, token);
                }
            }

            // Delete the file entry
            delete directory[fileName];

            // Store it again
            await this.store(directoryToken, directory);

            // Delete the file data
            this.purge(token);
        }
    }

    /**
     * Lists the files in the given path.
     *
     * @param {string} path The path to list.
     */
    async list(path, token) {
        let data = await this.load(path, token);

        if (!data) {
            return [];
        }

        // Convert to a list of files
        let ret = [];

        Object.keys(data).forEach( (name) => {
            ret.push({
                name: name,
                type: data[name].type,
                token: data[name].token
            });
        });

        return ret;
    }
}

export default FileSystem;
