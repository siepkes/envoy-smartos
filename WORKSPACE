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
    sha256 = "218efe8ee736d26a3572663b374a253c012b716d8af0c07e842e82f238a0a7ee",
    urls = [
        # 0.0.10 is required by rules_go. The patch adds 'illumos' as an OS.
        "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.10/platforms-0.0.10.tar.gz",
        "https://github.com/bazelbuild/platforms/releases/download/0.0.10/platforms-0.0.10.tar.gz",
    ],
)

load("//bazel:api_binding.bzl", "envoy_api_binding")

envoy_api_binding()

load("//bazel:api_repositories.bzl", "envoy_api_dependencies")

envoy_api_dependencies()

load("//bazel:repo.bzl", "envoy_repo")

envoy_repo()

load("//bazel:repositories.bzl", "envoy_dependencies")

envoy_dependencies()

load("//bazel:repositories_extra.bzl", "envoy_dependencies_extra")

envoy_dependencies_extra()

load("//bazel:python_dependencies.bzl", "envoy_python_dependencies")

envoy_python_dependencies()

load("//bazel:dependency_imports.bzl", "envoy_dependency_imports")

envoy_dependency_imports()

# Disabled because this requires rules_rust, which does not have illumos support.
# Adding illumos support will require work because we will have to bootstrap Bazel's
# crate_universe for illumos.
#load("//bazel:dependency_imports_extra.bzl", "envoy_dependency_imports_extra")

#envoy_dependency_imports_extra()
