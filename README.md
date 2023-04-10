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

* Initialize git submodules:

  ```shell
  git submodule init
  git submodule update
  ```

* If you are building with flatpak, install `flatpak` runtime:

  ```shell
  flatpak install flathub "org.gnome.Sdk/x86_64/43"
  flatpak install flathub "org.freedesktop.Sdk.Extension.rust-nightly"
  flatpak install flathub "org.freedesktop.Sdk.Extension.llvm14"
  ```

### Installing locally

```
mkdir build
flatpak-builder --user --install build flatpak.yml
```

### Make a development build

* If you have `libgtk4` and Rust installed locally, run `cargo build`

* To build with flatpak, run the following commands:
  
  ```shell
  flatpak-builder build flatpak.yml
  flatpak-builder --run build flatpak.yml bash
  ```
  
  This will open a shell inside the flatpak environment.
  You can then execute the binary:
  
  ```shell
  ./build/files/bin/envoyer
  ```
  

### License

Copyright 2016-2021 Andrei-Costin Zisu.

This software is licensed under the GNU General Public License (version 3).
See the LICENSE file in this distribution.
