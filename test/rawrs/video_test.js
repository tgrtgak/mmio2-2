"use strict";

import Helper from '../helper.js';

import { Video } from '../../assets/js/rawrs/video.js';

describe('Video', () => {
    beforeEach(function() {
        this.canvas = document.createElement("canvas");

        // Mock out the canvas draw context
        this.context = jasmine.createSpyObj('context', [
            'fillRect', 'createImageData'
        ], {
            'fillStyle': '#fff'
        });

        // Return the draw context from the canvas
        spyOn(this.canvas, 'getContext').and.returnValue(this.context);
    });

    describe('.constructor', () => {
        it('should set the graphic_display global width property', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(window.graphic_display.width).toEqual(width);
        });

        it('should set the graphic_display global height property', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(window.graphic_display.height).toEqual(height);
        });

        it('should set the graphic_display global ctx property', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);
            expect(window.graphic_display.ctx).toEqual(this.context);
        });

        it('should set the graphic_display global image property', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let imageData = {};
            this.context.createImageData.and.returnValue(imageData);
            let video = new Video(width, height, this.canvas);
            expect(window.graphic_display.image).toEqual(imageData);
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
            let video = new Video(width, height, this.canvas);
            expect(video.context).toEqual(this.context);
        });
    });

    describe('#clear', () => {
        it('should paint the canvas black', function() {
            let width = Helper.randomInteger(1, 1000);
            let height = Helper.randomInteger(1, 1000);
            let video = new Video(width, height, this.canvas);

            video.clear();
            expect(this.context.fillRect)
                .toHaveBeenCalledWith(0, 0, width, height);
            expect(
                Object.getOwnPropertyDescriptor(this.context, "fillStyle").set)
                .toHaveBeenCalledWith('#000');
        });
    });
});
