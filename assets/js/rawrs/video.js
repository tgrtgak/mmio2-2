"use strict";

import EventComponent from './event_component';
import Tabs from './tabs';

/**
 * This represents the video device.
 */
export class Video extends EventComponent {
    constructor(width, height, canvas) {
        super();

        this._canvas = canvas;
        this._width = width;
        this._height = height;
        this._active = false;
        this._visible = false;
        this._scale = 1;

        // Get context
        this._context = this._canvas.getContext('2d');

        // Create an image to hold the frame
        this._image = this.context.createImageData(width, height);

        // Get the tabs so we know when it switches to the video screen
        this._tabs = Tabs.load(document.querySelector('.tabs.side'));
        this._tabs.on('change', (button) => {
            if (button.getAttribute('id') === 'video-select') {
                this._visible = true;
                this.animate();
            }
            else {
                this._visible = false;
            }
        });

        // Clear screen
        this.clear();

        // TinyEMU looks for this:
        window.rawrsVideo = this;
    }

    /**
     * Returns whether or not the device has been written to.
     */
    get active() {
        return this._active;
    }

    /**
     * Returns the scale of the video.
     */
    get scale() {
        return this._scale;
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

    blit(imageData, destX, destY, srcX, srcY, width, height, deviceWidth, deviceHeight) {
        // Update the scale
        if (deviceWidth != this.width || deviceHeight != this.height) {
            this._width = deviceWidth;
            this._height = deviceHeight;
            this.canvas.setAttribute('width', this.width);
            this.canvas.setAttribute('height', this.height);
        }

        this._active = true;
        this.context.putImageData(imageData, destX, destY, srcX, srcY, width, height);
    }

    show() {
        // TODO: tell the tabstrip to activate this tab
        this._visible = true;
    }

    reset() {
        this._active = false;
        this.clear();
        this.animate();
    }

    clear() {
        if (this.active) {
            // Clear to black
            this.context.fillStyle = "#000";
            this.context.fillRect(0, 0, this.width, this.height);
        }
        else {
            // Clear to static
            let buffer = new Uint32Array(this._image.data.buffer);
            let step = 4; // The size of the pixel
            let pixels = step * step;

            for (let y = 0; y < this.height; y += step) {
                for (let x = 0; x < this.width; x += step) {
                    let pos = (y * this.width) + x;
                    let value = 0x888888 | ((255 * Math.random()) << 24);

                    for (let j = 0; j < pixels; j++) {
                        buffer[pos + (j % step) + (this.width * Math.floor(j / step))] = value;
                    }
                }
            }

            this.context.putImageData(this._image, 0, 0);
        }
    }

    animate() {
        // If not written to, show the static
        let time = 0;
        let step = (when) => {
            if (!time) {
                time = when;
            }

            let elapsed = when - time;
            if (elapsed > 50) {
                time = when;
                this.clear();
            }

            if (this._visible && !this._active) {
                window.requestAnimationFrame(step);
            }
        };

        window.requestAnimationFrame(step);
    }
}

export default Video;
