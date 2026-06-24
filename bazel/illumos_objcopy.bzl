"""Expose a host objcopy as a Bazel tool for illumos / SmartOS.

Envoy's dynamic_modules symbol-prefixing step (envoy_dynamic_module_prefix_symbols in
source/extensions/dynamic_modules/dynamic_modules.bzl) renames symbols in a static archive
with `objcopy --redefine-syms`. Upstream Envoy uses llvm-objcopy from the downloaded LLVM
toolchain (@toolchains_llvm), which has no illumos support ("Unsupported OS: sunos"). On
illumos we use a host objcopy instead: GNU binutils `objcopy`/`gobjcopy` (pkgsrc `binutils`)
or `llvm-objcopy` (pkgsrc `clang`/`llvm`). All of these support `--redefine-syms`.
"""

def _illumos_objcopy_impl(repository_ctx):
    objcopy = None
    for name in ["objcopy", "gobjcopy", "llvm-objcopy"]:
        found = repository_ctx.which(name)
        if found:
            objcopy = found
            break
    if objcopy == None:
        fail(
            "illumos_objcopy: no 'objcopy', 'gobjcopy' or 'llvm-objcopy' found on PATH. " +
            "Install GNU binutils or LLVM on the build host (pkgsrc `binutils`, or " +
            "`clang`/`llvm`) -- it is needed by the dynamic_modules symbol-renaming step.",
        )
    repository_ctx.symlink(objcopy, "objcopy")
    repository_ctx.file("BUILD.bazel", "exports_files([\"objcopy\"])\n")

illumos_objcopy_repository = repository_rule(
    implementation = _illumos_objcopy_impl,
    doc = "Discovers a host objcopy and exposes it as @illumos_objcopy//:objcopy.",
    environ = ["PATH"],
    local = True,
)

def register_illumos_objcopy(name = "illumos_objcopy"):
    illumos_objcopy_repository(name = name)
