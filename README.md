# Envoyer app

Envoyer intends to be the mail app for the Linux desktop of 2016. It is written
in Vala using the MailCore 2 library as a backend and GTK+3 as a toolkit. It is 
designed to be used with elementary OS.

The application is currently in full development.

### Review of other mail clients

* Geary (or its brother, Pantheon Mail): while the UI was great, the performance
and usability of the application as a daily driver is upsetting. I originally
intended to work on Pantheon Mail and improve on these points but was turned
away by the poor quality of the code. For example, the most important class of
the application, GearyController, has over 2800 lines. There is severe overlap
of concerns and plenty of undocumented assumptions, which make further
development cumbersome. Envoyer intends to adhere to principled development.

* Evolution: Envoyer was initially built to use Evolution's backend (Evolution Data
Server/Camel), but it was quickly found to be clunky and limiting. GObject
in C (Evolution) demands a lot of boilerplate code and it makes the overall
development experience really difficult. Envoyer uses Vala, which makes it
much more easy to write GObject code.  Furthermore, Envoyer aims to have a 
much lighter and friendlier UI.

* Thunderbird: just as Evolution, I think many use cases for which this
application was built are no longer as important today.

* Nylas N1: very good UI and UX, but it uses a third-party HTTPS API for mail
communication. Built on the Electron framework, it cannot make use of native
toolkit goodies like theming, icons or better performance.

### How to setup.

You will first need to clone the MailCore 2 library in the same directory you 
cloned the Envoyer repository.

To build Envoyer, run the following commands:
```
mkdir build
cd build
cmake ..
make
```

You will have to first run `cd src` and then `./envoyer`, otherwise the 
WebKitGTK+ Web Extension will not get loaded (there is no dynamic mechanism yet).

### Folder structure

* `src/FutureGranite` - modules that are intended to be merged into `libgranite` when finished
* `src/WebExtensions` - implementation of `webkit2gtk-web-extension-4.0` as exemplified [here](https://github.com/rschroll/webkitdom/tree/extension)
* `src/Widgets` - view folder, almost always backed by some models. Never accesses backend libraries, such as `libcamel`, directly.

### License

Copyright 2011-2016 Andrei-Costin Zisu.

This software is licensed under the GNU Lesser General Public License (version 
    2.1 or later).  See the COPYING file in this distribution.
