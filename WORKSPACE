workspace(name = "envoy")

# Even though the Bazel illumos port has illumos defined in the 'platforms' repo as OS the platforms
# gets overridden by some dependency in Envoy (no idea which one). Therefor we need to make sure the
# modified platforms repo stays in Envoy's Bazel build.
#
# We define this here instead of 'repository_locations.bzl' because by defining it here, before
# anything else gets loaded, we ensure no-one overwrites our definition.
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "platforms",
    sha256 = "1cbfc5fce669885d0ea6c5c92858eef7bfcdf8da22fee5dfd9b318f843f89fc6",
    strip_prefix = "platforms-d64c19586387033dd0c2ba3a3f36e47406e8cecc",
    urls = [
        # Commit 'b2adb960759a3dc93505953357109d78503b0bd9' is a fork of 0.0.7 with 'illumos' added as OS.
        # 0.0.7 is the version used in Bazel 6.5.0, the Bazel version used to build Envoy.
        "https://github.com/siepkes/platforms/archive/d64c19586387033dd0c2ba3a3f36e47406e8cecc.zip",
    ],
)

load("//bazel:api_binding.bzl", "envoy_api_binding")

envoy_api_binding()

load("//bazel:api_repositories.bzl", "envoy_api_dependencies")

envoy_api_dependencies()

load("//bazel:repositories.bzl", "envoy_dependencies")

envoy_dependencies()

load("//bazel:repositories_extra.bzl", "envoy_dependencies_extra")

envoy_dependencies_extra()

load("//bazel:python_dependencies.bzl", "envoy_python_dependencies")

envoy_python_dependencies()

load("//bazel:dependency_imports.bzl", "envoy_dependency_imports")

envoy_dependency_imports()
