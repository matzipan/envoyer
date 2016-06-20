# Envoyer app

Envoyer intends to be the nail app for the Linux desktop of 2016. It is written
in Vala using the Evolution Data Server/Camel library as a backend and GTK+3 as 
a toolkit. It is designed to be used with elementary OS.

The application is currently in full development.

### Review of other mail clients

* Geary (or its brother, Pantheon Mail): while the UI was great, the performance
and usability of the application as a daily driver is upsetting. I originally
intended to work on Pantheon Mail and improve on these points but was turned 
away by the poor quality of the code. For example, the most important class of 
the application, GearyController, has over 2800 lines. There is severe overlap
of concerns and plenty of undocumented assumptions, which make further
development cumbersome. Envoyer intends to adhere to principled development.

* Evolution: Envoyer builds on Evolution's backend (Evolution Data 
Server/Camel), but the aim is to have a much lighter and friendlier UI. GObject 
in C (Evolution) demands a lot of boilerplate code and it makes the overall 
development experience really difficult. Envoyer uses Vala, which makes it
much more easy to write GObject code.

* Thunderbird: just as Evolution, I think many use cases for which this 
application was built are no longer as important today. 

* Nylas N1: very good UI and UX, but it uses a third-party HTTPS API for mail
communication. Built on the Electron framework, it cannot make use of native 
toolkit goodies like theming, icons or better performance.

### How to setup.

You will first need to install Evolution, because Envoyer is not able to manage
accounts just yet.

You will then need to cone [this](https://github.com/matzipan/evolution-data-server) branch of Evolution Data Server. To build it you will first need to generate the make files
using `./autogen.sh` then `make & sudo make install`.

To build Envoyer, run the following commands:
```
mkdir build
cd build
cmake ..
make 
```

You can then run: `./src/envoyer`.

The current vapi bindings are a bit different than what EDS' build will generate,
as there were some missing GIR annotations which were quickfixed in the vapi files 
directly.

### License

Copyright 2011-2016 Andrei-Costin Zisu. 

This software is licensed under the GNU Lesser General Public License (version 2.1 or later).  See the COPYING file in this distribution.

