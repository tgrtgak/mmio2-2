class Util {
    /**
     * This function retrieves the query value from the given url.
     *
     * @param {string} name The query key to look for.
     * @param {string} [url] The URL to parse. If not given, then it will use
     *                       the current location.
     * @returns {string} If found, the value for the given key is given.
     */
    static getParameterByName(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, "\\$&");
        var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }

    /*
     * Internal function to convert various JS arrays into a Uint8Array.
     */
    static toU8(data) {
        if (typeof data === 'string' || data instanceof String) {
            data = data.split("").map( (c) => c.charCodeAt(0) );
        }

        if (Array.isArray(data) || data instanceof ArrayBuffer) {
            data = new Uint8Array(data);
        }
        else if (!data) {
            // `null` for empty files.
            data = new Uint8Array(0);
        }
        else if (!(data instanceof Uint8Array)) {
            // Avoid unnecessary copying.
            data = new Uint8Array(data.buffer);
        }
        return data;
    }
}

export default Util;
