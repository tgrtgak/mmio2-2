"use strict";

import EventComponent from './event_component';

/**
 * This represents the video device.
 */
export class Video extends EventComponent {
    constructor(width, height, canvas) {
        super();

        this._canvas = canvas;
        this._width = width;
        this._height = height;

        // Get context
        this._context = this._canvas.getContext('2d');

        // Clear screen
        this.clear();

        let image = this.context.createImageData(width, height);

        // TinyEMU looks for this:
        window.graphic_display = {
            image: image,
            width: width,
            height: height,
            ctx: this.context
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

    /**
     * Returns the drawing context for the display.
     */
    get context() {
        return this._context;
    }

    clear() {
        this.context.fillStyle = "#000";
        this.context.fillRect(0, 0, this.width, this.height);
    }
}

export default Video;
