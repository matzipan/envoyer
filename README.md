# Envoyer app

[![CI](https://github.com/matzipan/envoyer/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/matzipan/envoyer/actions/workflows/ci.yml)

Envoyer intends to be the mail app for the Linux desktop of today. It has been
through many writes and rewrites. It is currently written in Rust on top of GTK
4.0 using the melib library as a mailing backend.

While this application started with the intent of being a serious effort, it
has since become a vehicle for me to learn and experiment. It will likely never
be finished. Anyway, the experience of rewriting this in Rust has been very
nice. Go learn Rust!

## Developing

### Requirements

Install flatpak runtimes:

```shall
flatpak install org.gnome.Platform/x86_64/45
flatpak install org.freedesktop.Sdk.Extension.rust-stable/x86_64/23.08
flatpak install org.freedesktop.Sdk.Extension.llvm16/x86_64/23.08
```

Make sure to initialize the git submodules:

```shell
git submodule init
git submodule update
```

### Installing locally

```
mkdir build
flatpak-builder --user --install build build-aux/flatpak.yml
```

### Make a development build

The commands below should give you a shell in a flatpak environment with GTK 4 set up. This also works on systems with
no GTK 4. Building without flatpak is possible, although a bit more difficult.

```shell
flatpak-builder --user workdir build-aux/flatpak.yml
flatpak-builder --run workdir build-aux/flatpak.yml bash
```

To build the application then:

```shell
mkdir build && cd build
meson setup --prefix=/app -D profile=devel ..
ninja
```

In order to get the application set up correctly, you will need to run:

```
ninja install
```

Then you will simply be able to run the application from the `PATH` by simply running:

```
envoyer
```

### Testing

A test server is available to test the application against. To start the server, run the command below. `docker` needs to be available.

```
cargo run --bin test_server
```

Then running `envoyer` like so should get it to connect to the test server:

```
envoyer --with-test-server
```

## License

Copyright 2016-2021 Andrei-Costin Zisu.

This software is licensed under the GNU General Public License (version 3).
See the LICENSE file in this distribution.
