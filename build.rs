use cc;
use cmake;

use std::env;

fn main() {
    let out_path = env::var("OUT_DIR").unwrap();
    let include_path = format!("{}/include", out_path);

    // Build litehtml as a CMake library
    let litehtml_build = cmake::build("litehtml");

    // Build the litehtml container as a C++ library
    cc::Build::new()
        .file("lib/litehtml_container/container.cpp")
        .include(&include_path)
        .compile("litehtml_container");

    // Create the Rust bindings for the C++ code
    let bindings = bindgen::Builder::default()
        // The input header we would like to generate
        // bindings for.
        .header("lib/bindgen_wrapper.hpp")
        .allowlist_type("litehtml::.*")
        .allowlist_function("litehtml::.*")
        .allowlist_type("litehtml_container.*")
        .allowlist_function("litehtml_container.*")
        .opaque_type("std::.*")
        .enable_cxx_namespaces()
        .clang_args(&[
            // I'm not sure how to avoid hardcoding this flatpak path
            "-I/usr/lib/sdk/llvm12/lib/clang/12.0.1/include",
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
    println!("cargo:rustc-link-lib=static=litehtml");
    println!("cargo:rustc-link-lib=static=litehtml_container");
    println!("cargo:rustc-link-lib=dylib=stdc++");

    // Tell cargo to invalidate the built crate whenever the wrapper changes
    println!("cargo:rerun-if-changed=lib/bindgen_wrapper.hpp");
}
