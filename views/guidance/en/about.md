# RISC-V Assembler and Workable, Rewritable System (RAWRS)

![Logo](../images/dynamic/hex/ae8bab/dinosaurs/stegosaurus.svg)

**RAWRS** is a learning tool designed to help teach architecture concepts through the writing of assembly language.
The language used is RISC-V, an up-and-coming open RISC architecture based on MIPS. RAWRS itself is loosely
modeled after its own namesake, MARS, which is an equivalent learning solution for MIPS assembly.

RAWRS is built off of entirely free and open software and is designed to be easy to deploy to any modern
environment as a static website. It uses *emscripten* to compile the free and open toolchain that RAWRS uses
to assemble and inspect application binaries all within the web browser's native JavaScript engine.

The simulator (or emulator if you must) that runs the RISC-V application and kernel is TinyEmu by Fabrice
Bellard, and is itself permissively licensed and open. Without this, the modifications required to make it
work in an educational environment would not have been possible. And in the same spirit, RAWRS is offered,
along with the educational RISC-V kernel written alongside it, completely openly and free.

## Source Code

You can find the source code for RAWRS on [GitLab](https://gitlab.com/wilkie/rawrs).

## License

The main web application and program content is licensed under the terms of the [GNU AGPLv3.0 license](https://www.gnu.org/licenses/agpl-3.0.en.html).

## Development

* **RAWRS Programming and Design**: [wilkie](https://wilkie.how)
* **TinyEmu RISC-V System Emulator**: Fabrice Bellard, modifications by wilkie
* **GNU Binutils**: {% binutils_authors %}

## Localization

* **English**: wilkie

## Artwork

* **Dinosaurs**: [Maxicons](https://thenounproject.com/maxicons/), [CCBY](https://creativecommons.org/licenses/by/3.0/us/legalcode), licensed
* **Icon**: wilkie

## Documentation

* **General**: wilkie
* **Tutorials**: wilkie

## Open Source Software

This program would not be possible if not for the existing and ongoing effort provided by the community at large within these independently developed and maintained projects.

* [GNU Binutils](https://www.gnu.org/software/binutils/)
* [RISC-V GNU Binutils port](https://github.com/riscv/riscv-gnu-toolchain)
* [emscripten](http://kripken.github.io/emscripten-site/)
* [TinyEmu](https://bellard.org/tinyemu/) (with modifications)
* [Sinatra](http://sinatrarb.com/)
* [slim](http://slim-lang.com/)
* [Sass](https://sass-lang.com/)
* [tilt](https://github.com/rtomayko/tilt)
* [git](https://git-scm.com/)
* [GitLab](https://about.gitlab.com/)
* [i18n and rails-i18n](http://rails-i18n.org/)
* [Redcarpet](https://github.com/vmg/redcarpet)
* [rackula](https://github.com/socketry/rackula)
* [node](https://nodejs.org/en/)
* [npm](https://www.npmjs.com/)
* [webpack](https://webpack.js.org/)
* [babel](https://babeljs.io/)
