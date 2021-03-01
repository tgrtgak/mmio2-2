"use strict";

import Helper from '../helper.js';

import { Video } from '../../assets/js/rawrs/video.js';

describe('Video', () => {
    beforeEach(function() {
        // We need there to be some tabs on the page
        this.tabsElement = document.createElement("ol");
        this.tabsElement.classList.add('tabs');
        this.tabsElement.classList.add('side');
        document.body.appendChild(this.tabsElement);

        // Create a canvas for the framebuffer
        this.canvas = document.createElement("canvas");
    });

    describe('.constructor', () => {
        it('should set the rawrsVideo global', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(window.rawrsVideo).toEqual(video);
        });

        it('should clear the canvas', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            spyOn(Video.prototype, 'clear').and.returnValue();
            let video = new Video(width, height, this.canvas);
            expect(video.clear).toHaveBeenCalled();
        });
    });

    describe('#width', () => {
        it('should return the width provided by the constructor', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(video.width).toEqual(width);
        });
    });

    describe('#height', () => {
        it('should return the height provided by the constructor', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(video.height).toEqual(height);
        });
    });

    describe('#canvas', () => {
        it('should return the canvas provided by the constructor', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(video.canvas).toEqual(this.canvas);
        });
    });

    describe('#context', () => {
        it('should return the appropriate canvas context', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);

            // Mock out the canvas draw context
            this.context = jasmine.createSpyObj('context', ['fillRect', 'createImageData']);

            // Return the draw context from the canvas
            spyOn(this.canvas, 'getContext').and.returnValue(this.context);
            spyOn(Video.prototype, 'clear').and.returnValue();

            let video = new Video(width, height, this.canvas);

            expect(video.context).toEqual(this.context);
        });
    });

    describe('#clear', () => {
        it('should paint the canvas black when active', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);

            spyOn(video.context, 'fillRect').and.returnValue();
            spyOnProperty(video.context, 'fillStyle', 'set').and.callThrough();
            video._active = true;
            video.clear();

            expect(video.context.fillRect)
                .toHaveBeenCalledWith(0, 0, width, height);
            expect(
                Object.getOwnPropertyDescriptor(video.context, "fillStyle").set)
                .toHaveBeenCalledWith('#000');
        });
    });
});
