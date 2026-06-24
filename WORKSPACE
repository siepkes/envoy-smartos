workspace(name = "envoy")

# Even though the Bazel illumos port has illumos defined in the 'platforms' repo as OS the platforms
# gets overridden by some dependency in Envoy (no idea which one). Therefor we need to make sure the
# modified platforms repo stays in Envoy's Bazel build.
#
# We define this here instead of 'repository_locations.bzl' because by defining it here, before
# anything else gets loaded, we ensure no-one overwrites our definition. Instead of forking the
# 'platforms' repo we use the upstream release and apply a patch that adds 'illumos' as an OS.
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "platforms",
    patch_args = ["-p1"],
    patches = ["@envoy//bazel:illumos-platforms.patch"],
    sha256 = "852b71bfa15712cec124e4a57179b6bc95d59fdf5052945f5d550e072501a769",
    strip_prefix = "platforms-1.0.0",
    urls = [
        # Must match the version Envoy 1.38.3 uses (see bazel/repository_locations.bzl).
        # The patch adds 'illumos' as an OS.
        "https://github.com/bazelbuild/platforms/archive/1.0.0.tar.gz",
    ],
)

# illumos: expose a host objcopy (binutils/llvm) for the dynamic_modules symbol-prefixing
# step, since the upstream LLVM toolchain (@toolchains_llvm) has no illumos support.
load("//bazel:illumos_objcopy.bzl", "register_illumos_objcopy")

register_illumos_objcopy()

load("//bazel:api_binding.bzl", "envoy_api_binding")

envoy_api_binding()

load("//bazel:api_repositories.bzl", "envoy_api_dependencies")

envoy_api_dependencies()

load("//bazel:repositories.bzl", "envoy_dependencies")

envoy_dependencies()

load("//bazel:bazel_deps.bzl", "envoy_bazel_dependencies")

envoy_bazel_dependencies()

load("//bazel:repositories_extra.bzl", "envoy_dependencies_extra")

envoy_dependencies_extra()

load("//bazel:python_dependencies.bzl", "envoy_python_dependencies")

envoy_python_dependencies()

load("//bazel:dependency_imports.bzl", "envoy_dependency_imports")

envoy_dependency_imports()

load("//bazel:repo.bzl", "envoy_repo")

envoy_repo()

load("//bazel:toolchains.bzl", "envoy_toolchains")

envoy_toolchains()

load("//bazel:dependency_imports_extra.bzl", "envoy_dependency_imports_extra")

envoy_dependency_imports_extra()
