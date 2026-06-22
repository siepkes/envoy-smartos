load("//tools/python:namespace.bzl", "envoy_py_namespace")

licenses(["notice"])  # Apache 2

envoy_py_namespace()

exports_files([
    "VERSION.txt",
    "API_VERSION.txt",
    ".clang-format",
    "pytest.ini",
    ".coveragerc",
    "CODEOWNERS",
    "OWNERS.md",
    ".github/config.yml",
    "reviewers.yaml",
])

alias(
    name = "envoy",
    actual = "//source/exe:envoy",
    visibility = ["//visibility:public"],
)

alias(
    name = "envoy.stripped",
    actual = "//source/exe:envoy-static.stripped",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "clang_tidy_config",
    srcs = [".clang-tidy"],
    visibility = ["//visibility:public"],
)

# These two definitions exist to help reduce Envoy upstream core code depending on extensions.
# To avoid visibility problems, see notes in source/extensions/extensions_build_config.bzl
#
# TODO(#9953) //test/config_test:__pkg__ should probably be split up and removed.
# TODO(#9953) the config fuzz tests should be moved somewhere local and //test/config_test and //test/server removed.
package_group(
    name = "extension_config",
    packages = [
        "//source/exe",
        "//source/extensions/...",
        "//test/config_test",
        "//test/extensions/...",
        "//test/server",
        "//test/server/config_validation",
        "//test/tools/...",
        "//tools/extensions/...",
    ],
)

package_group(
    name = "extension_library",
    packages = [
        "//source/extensions/...",
        "//test/extensions/...",
    ],
)

package_group(
    name = "contrib_library",
    packages = [
        "//contrib/...",
    ],
)

package_group(
    name = "mobile_library",
    packages = [
        "//mobile/...",
    ],
)

exports_files([
    "rustfmt.toml",
])

load(
    "@bazel_tools//tools/jdk:default_java_toolchain.bzl",
    "BASE_JDK9_JVM_OPTS",
    "DEFAULT_JAVACOPTS",
    "DEFAULT_TOOLCHAIN_CONFIGURATION",
    "default_java_toolchain",
)

# On illumos this config gets activated. We use it to force Bazel to use the local (pkgsrc) JDK. If we
# don't it will try to use '@bazel_tools//tools/jdk:remote_jdk11'. Which won't work because there is no
# remote illumos JDK which can be downloaded configured in the 'rules_java' project.
default_java_toolchain(
    name = "repository_default_toolchain",
    configuration = DEFAULT_TOOLCHAIN_CONFIGURATION,
    java_runtime = "@local_jdk//:jdk",
    javacopts = DEFAULT_JAVACOPTS,
    jvm_opts = BASE_JDK9_JVM_OPTS,
    source_version = "11",
    target_version = "11",
)
