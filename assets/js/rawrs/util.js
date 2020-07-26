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
}

export default Util;
