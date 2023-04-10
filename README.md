# Envoyer app

[![CI](https://github.com/matzipan/envoyer/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/matzipan/envoyer/actions/workflows/ci.yml)

Envoyer intends to be the mail app for the Linux desktop of today. It has been
through many writes and rewrites. It is currently written in Rust on top of GTK
4.0 using the melib library as a mailing backend.

While this application started with the intent of being a serious effort, it
has since become a vehicle for me to learn and experiment. It will likely never
be finished. Anyway, the experience of rewriting this in Rust has been very
nice. Go learn Rust!

## Building

## Requirements

Make sure to initialize the git submodules:

```shell
git submodule init
git submodule update
```

### Installing locally

```
mkdir build
flatpak-builder --user --install build flatpak.yml
```

### Make a development build

In case you don't have GTK 4 on your system, you can use flatpak.
The commands below should give you a shell in a flatpak environment with GTK 4 set up.
  ```shell
  flatpak-builder build flatpak.yml
  flatpak-builder --run build flatpak.yml bash
  ```
To build or run the application, use the usual `cargo` commands: `cargo build` or `cargo run`.

You can find the binaries under `./build/files/bin/envoyer`

### License

Copyright 2016-2021 Andrei-Costin Zisu.

This software is licensed under the GNU General Public License (version 3).
See the LICENSE file in this distribution.
