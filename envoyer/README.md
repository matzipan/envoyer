# Building

```
mkdir build
flatpak-builder --user build flatpak.yaml
```

# Developing

```
flatpak build-init sdk com.github.matzipan.envoyer org.gnome.Sdk org.gnome.Platform 40 --sdk-extension=org.freedesktop.Sdk.Extension.rust-stable
flatpak build --share=network --share=ipc --socket=fallback-x11 --socket=wayland --device=dri --talk-name=org.freedesktop.portal.OpenURI sdk bash
cargo build
```