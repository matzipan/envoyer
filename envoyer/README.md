# Installing locally

```
mkdir build
flatpak-builder --user --install build flatpak.yaml
```

# Developing

```
mkdir build
flatpak-builder --run build flatpak.yml bash
cargo build
```