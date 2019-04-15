workspace(name = "envoy")

load("//bazel:api_repositories.bzl", "envoy_api_dependencies")

envoy_api_dependencies()

load("//bazel:repositories.bzl", "GO_VERSION", "envoy_dependencies")
load("//bazel:cc_configure.bzl", "cc_configure")

envoy_dependencies()

load("@rules_foreign_cc//:workspace_definitions.bzl", "rules_foreign_cc_dependencies")

rules_foreign_cc_dependencies()

cc_configure()

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")

go_rules_dependencies()

# Using 'host' makes Bazel use the go installation on our host. This
# is needed because the 'io_bazel_rules_go' tries to download a GO 
# installation. However it can't download one for Illumos / Solaris.
go_register_toolchains(go_version = "host")
