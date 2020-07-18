# RAWRS: RISC-V Assembler and Workable, Rewritable System

RAWRS is based on the ideas presented by MARS, its MIPS equivalent. RAWRS is
meant to be a teaching application for introductory to advanced architecture
and computer science students.

It is, all-in-all, a self-contained web application that can assemble simple to
complex RISC-V applications and execute them on a bare-metal simulation. It uses
the TinyEmu RISC-V simulator that has been modified to provide capabilities for
breakpointing and machine inspection.

For the basic application writing akin to MARS' operation, a kernel has been
written to supervise these applications and provide similar system calls. To be
a suitable guide for students, the kernel is written in RISC-V assembly which
can be inspected by such students as proof the system is not magic. Future
systems and architecture students may modify this kernel to learn more advanced
techniques, and perhaps modify the TinyEmu simulator to change its behavior as
well.

The web application can be hosted in a "serverless" environment by statically
packaging it with the 'rackula' command. See the details in the "Static Site
Generation" subsection in the "Development" section below.

## Development

**This is a work in progress... and the build scripts and modifications to the simulator are not yet included.**

This section contains information about how to create your own development
environment for adding features or fixing bugs in RAWRS. There are quite a few
moving pieces, so each subsection breaks down each one independently. However,
it is assumed that each is installed in the written order as some depend on
others.

### Gather All of the Things

Provided is an install script that will gather the various things we need from
their respective homes. Let us know if anything disappears. I'm an archivist,
so I have many many solutions. (But it is never fun to see this happen in
practice)

Use the script to gather, well, all the things:

```
sh install.sh
```

You can build everything with one command, if you want. However, you may want
to at least skim the next sections to make sure you can build things.

Generally, you will need a C compiler (gcc), relatively new version of Python,
and a Linux environment. We handle most of everything else to lock down the
versions of things we've modified.

```
sh build.sh
```

### Toolchain

In order to do the fun things we do with RISC-V, we need a toolchain. That is,
we need the ability to build and analyze RISC-V binaries. For that, we will
download and build a RISC-V targetted assembler and linker. We will build a
native copy and a JavaScript version.

For this, we need a Linux environment with the basic `gcc` build tools
available. Then, you can install everything we need with the `install.sh`
script.

This will unpack everything from other repositories. It also unpacks some stuff
from 

### Simulator

We use the TinyEmu simulator. This has already been installed and built if
you used the general scripts above.

### JavaScript

We need a JavaScript environment for compiling the application's JavaScript to a
backwards compatible format.

First, install node.js through your system package manager.
Using npm (node's package manager), install the JavaScript dependencies.

```
npm install
```

Now, we can compile the JavaScript using [webpack](https://webpack.js.org/) and [babel](https://babeljs.io/), which
lets us use future JavaScript features and cross-compile them for older browsers.
This produces the file "./public/js/rars.js":

```
npx webpack
```

We can run a local server using `rackup`:

```
rackup
```

Which spawns a server on localhost running on port 9292. If you want to use
a different host or port, use `-o` and `-p` respectively.

For instance, to launch it world-facing:

```
rackup -o 0.0.0.0 -p 8080
```

### Static Site Generation

To create a static site, simply run `rackula` like the following:

```
rackula generate
```

As long as each other step was taken, the site will be complete and working.
The output will be in the `static` subdirectory.

Some caveats: many static website serving solutions, including out-of-the-box
directory listings, will not serve `.wasm` files with the `application/wasm`
MIME type. On modern browsers, this will cause the WebAssembly to not be used,
which will degrade performance. Try to add rules to your webserver of choice
to ensure it serves these MIME types correctly.

For testing, you can use the `server.rb` file in the `/scripts` directory. This
is a modified Webrick instance that serves `.wasm` correctly. While in the new
`static` directory, invoke it like this:

```
ruby ../scripts/server.rb
```

This will spawn the static version of the site on localhost and port 8081.

## Testing

## Installing

## Contributing

The following are accepted and cherished forms of contribution:

* Filing a bug issue. (We like to see feature requests and just normal bugs)
* Fixing a bug. (It's obviously helpful!)
* Adding documentation. (Help us with our docs or send us a link to your blog post!)
* Adding features.
* Adding artwork. (Art is the true visual form of professionalism)

The following are a bit harder to really accept, in spite of the obvious effort that may go into them, so please avoid this:

* Changing all of the JavaScript to coffeescript because it is "better"
* Rewriting all of the sass to whatever is newer. (It's happened to me before)
* Porting everything to rails.
* Creating a pull request with a "better" software license.

In general, contributions are easily provided by doing one of the following:

* Fork and clone the project.
* Update the code/art/documentation on your end however you see fit.
* Push that code/art/documentation to a public server.
* Create a pull request from your copy to ours.

The above is the most convenient process. You may create an issue with a link to a repository or tar/zip containing your code or patches as well, if git is not your thing.

### Localization

If you would like to localize this application and its documentation into
another language, please feel free to do so!

There are two places localization happens. The first is the interface
aspects of the program. These happen in files off of the `locales` directory
in the root of the project. You will see a set of `.yml` files. If you
copy the English (`en.yml`) file and translate the strings, you should see
the effect when you restart a server or rebuild the static site and go to
the "/en" route (replace 'en' with your language code).

The next aspect are the documentation files. These are within `views/guidance`
and are then in the subdirectory consisting of that same language code. When
a document is not found for a particular language, it will default to the
English one, so you do not need to translate every page... any will help.

When you localize the app, send a Pull Request here and somebody will merge it
in.

## Acknowledgements

All attribution and crediting for contributors is located within [this file](views/guidance/en/about.md), which is rendered in the program on the About page of the Guidance tab.

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## License

RAWRS is licensed under the AGPL 3.0, with select code under other licenses as noted. Refer to the [LICENSE.txt](LICENSE.txt) file in the root of the repository for specific details.
