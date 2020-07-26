"use strict";

import EventComponent from './event_component';

/**
 * This represents the video device.
 */
class Video extends EventComponent {
    constructor(width, height, canvas) {
        super();

        this._canvas = canvas;
        this._width = width;
        this._height = height;

        // Get context
        let ctx = this._canvas.getContext('2d');

        // Clear screen
        ctx.fillStyle = "#000";
        ctx.fillRect(0, 0, width, height);

        let image = ctx.createImageData(width, height);

        // TinyEMU looks for this:
        window.graphic_display = {
            image: image,
            width: width,
            height: height,
            ctx: ctx
        };
    }

    /**
     * Returns the current width of the display.
     */
    get width() {
        return this._width;
    }

    /**
     * Returns the current height of the display.
     */
    get height() {
        return this._height;
    }

    /**
     * Returns the canvas element representing the display.
     */
    get canvas() {
        return this._canvas;
    }
}

export default Video;
