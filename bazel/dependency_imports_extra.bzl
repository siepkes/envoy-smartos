load("@envoy_rust_crate_index//:defs.bzl", "crate_repositories")
# llvm_register_toolchains is disabled on illumos: the build uses the auto-detected host GCC
# toolchain, and @llvm_toolchain has no illumos clang/llvm to download.
#load("@llvm_toolchain//:toolchains.bzl", "llvm_register_toolchains")

# Dependencies that rely on a first stage of envoy_dependency_imports() in dependency_imports.bzl.
def envoy_dependency_imports_extra():
    crate_repositories()
    #llvm_register_toolchains()
