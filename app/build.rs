use std::env;
use std::path::PathBuf;

fn main() {
    let clang_lib_path = env::var("CLANG_LIB_PATH").expect(
        "CLANG_LIB_PATH is not set. \
         Make sure you are building from the flatpak environment",
    );
    let out_path = env::var("OUT_DIR").unwrap();
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();

    let litehtml_callbacks_header_file = PathBuf::from(&out_path)
        .join("include")
        .join("litehtml_rust.hpp")
        .display()
        .to_string();

    let mut config: cbindgen::Config = Default::default();
    config.macro_expansion.bitflags = true;

    cbindgen::Builder::new()
        .with_config(config)
        .with_src(format!("{}/src/litehtml_callbacks.rs", crate_dir))
        .with_namespace("litehtml_rust")
        // We exclude the Callbacks item and just provide a placeholder
        // definition. The methods only use pointers to Callbacks anyway.
        .exclude_item("Callbacks")
        .with_header("namespace litehtml_rust {struct Callbacks;}")
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file(litehtml_callbacks_header_file);

    let clang_include_path = format!("{}/include", clang_lib_path);
    let include_path = format!("{}/include", out_path);

    // Build litehtml as a CMake library
    let litehtml_build = cmake::Config::new("vendor/litehtml").define("BUILD_TESTING", "Off").build();

    // Build the litehtml container as a C++ library
    cc::Build::new()
        .file("lib/litehtml_container/container.cpp")
        .file("lib/litehtml_container/setup.cpp")
        .include(&include_path)
        .flag("-Wno-unused-parameter")
        .flag("-Wno-reorder")
        .flag("-Wno-switch")
        .compile("litehtml_container");

    // Create the Rust bindings for the C++ code
    let bindings = bindgen::Builder::default()
        // The input header we would like to generate
        // bindings for.
        .header("lib/bindgen_wrapper.hpp")
        .allowlist_function("setup::.*")
        .opaque_type("std::.*")
        .enable_cxx_namespaces()
        .clang_args(&[
            &format!("-I{}", &clang_include_path),
            &format!("-I{}", &include_path),
            "--std=c++14",
        ])
        // Tell cargo to invalidate the built crate whenever any of the
        // included header files changed.
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .generate()
        .expect("Unable to generate bindings");

    bindings
        .write_to_file(format!("{}/bindings.rs", out_path))
        .expect("Couldn't write bindings!");

    println!("cargo:rustc-link-search=native={}/lib", litehtml_build.display());
    println!("cargo:rustc-link-lib=static=litehtml_container");
    println!("cargo:rustc-link-lib=static=litehtml");
    println!("cargo:rustc-link-lib=static=gumbo");
    println!("cargo:rustc-link-lib=dylib=stdc++");

    // Tell cargo to invalidate the built crate whenever the wrapper changes
    println!("cargo:rerun-if-changed=lib/setup.hpp");
    println!("cargo:rerun-if-changed=lib/setup.cpp");
    println!("cargo:rerun-if-changed=lib/bindgen_wrapper.hpp");
    println!("cargo:rerun-if-changed=lib/litehtml_container/setup.h");
    println!("cargo:rerun-if-changed=lib/litehtml_container/setup.cpp");
    println!("cargo:rerun-if-changed=lib/litehtml_container/container.cpp");
    println!("cargo:rerun-if-changed=lib/litehtml_container/container.h");
    println!("cargo:rerun-if-changed=src/litehtml_callbacks.rs");

    println!("cargo:rerun-if-changed=migrations");
}
