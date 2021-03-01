# Electron Builds

The electron builds provide a "native" application environment.

## Motivation

This could potentially allow native files instead of IndexedDB/LocalStorage
drivers.

## Builds

One can build the given platform via the appropriate build script. All scripts
assume a Linux or similar environment with `wget`, `zip`, `unzip`, and `tar`
installed.

```shell
cd electron
/bin/bash build-win.sh
```
