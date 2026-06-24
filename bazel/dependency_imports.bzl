load("@aspect_bazel_lib//lib:repositories.bzl", "register_jq_toolchains", "register_yq_toolchains")
load("@base_pip3//:requirements.bzl", pip_dependencies = "install_deps")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")
load("@build_bazel_rules_apple//apple:repositories.bzl", "apple_rules_dependencies")
load("@cel-cpp//bazel:deps.bzl", "parser_deps")
load("@com_github_chrusty_protoc_gen_jsonschema//:deps.bzl", protoc_gen_jsonschema_go_dependencies = "go_dependencies")
load("@dev_pip3//:requirements.bzl", pip_dev_dependencies = "install_deps")
load("@emsdk//:emscripten_deps.bzl", "emscripten_deps")
load("@emsdk//:toolchains.bzl", "register_emscripten_toolchains")
load("@envoy_toolshed//compile:sanitizer_libs.bzl", "setup_sanitizer_libs")
load("@envoy_toolshed//coverage/grcov:grcov_repository.bzl", "grcov_repository")
load("@fuzzing_pip3//:requirements.bzl", pip_fuzzing_dependencies = "install_deps")
load("@io_bazel_rules_go//go:deps.bzl", "go_download_sdk", "go_register_toolchains", "go_rules_dependencies")
load("@proxy_wasm_rust_sdk//bazel:dependencies.bzl", "proxy_wasm_rust_sdk_dependencies")
load("@rules_buf//buf:repositories.bzl", "rules_buf_toolchains")
load("@rules_cc//cc:extensions.bzl", "compatibility_proxy_repo")
load("@rules_foreign_cc//foreign_cc:repositories.bzl", "rules_foreign_cc_dependencies")
load("@rules_fuzzing//fuzzing:repositories.bzl", "rules_fuzzing_dependencies")
load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
load("@rules_proto_grpc//:repositories.bzl", "rules_proto_grpc_toolchains")
load("@rules_rust//crate_universe:defs.bzl", "crates_repository")
load("@rules_rust//crate_universe:repositories.bzl", "crate_universe_dependencies")
load("@rules_rust//rust:defs.bzl", "rust_common")
load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains", "rust_repository_set")
load("@rules_rust//crate_universe:deps_bootstrap.bzl", "cargo_bazel_bootstrap")
load("@shellcheck//:deps.bzl", "shellcheck_dependencies")

# go version for rules_go
# Using 'host' makes Bazel use the go installation on our host. This
# is needed because the 'io_bazel_rules_go' tries to download a GO
# installation. However it can't download one for illumos / Solaris.
GO_VERSION = "host"

JQ_VERSION = "1.7"
YQ_VERSION = "4.24.4"

BUF_SHA = "366ed6c11819d56e122042c18cb8dbcf012f773456821f15324c22d192dfc65c"
BUF_VERSION = "v1.61.0"

def envoy_dependency_imports(
        go_version = GO_VERSION,
        jq_version = JQ_VERSION,
        yq_version = YQ_VERSION,
        buf_sha = BUF_SHA,
        buf_version = BUF_VERSION,
        # This allows the downstream repo to point to a different locally re-generated lockfile,
        # which can be used to workaround a rules_rust bug. See:
        # - https://github.com/bazelbuild/rules_rust/issues/3521
        # - https://github.com/envoyproxy/envoy/issues/38951
        cargo_bazel_lockfile = "@envoy//:Cargo.Bazel.lock"):
    compatibility_proxy_repo()
    rules_foreign_cc_dependencies()
    go_rules_dependencies()
    go_register_toolchains(go_version)
    if go_version != "host":
        envoy_download_go_sdks(go_version)
    gazelle_dependencies(go_sdk = "go_sdk")
    apple_rules_dependencies()
    pip_dependencies()
    pip_dev_dependencies()
    pip_fuzzing_dependencies()
    rules_pkg_dependencies()
    emscripten_deps(emscripten_version = "4.0.6")
    # WASM is disabled on illumos (.bazelrc `build:illumos --define wasm=disabled`), so the
    # emscripten/WASM cc toolchain is never used. Registering it forces Bazel to LOAD the
    # @emsdk//emscripten_toolchain package during cc-toolchain resolution, which fails on
    # illumos because that package references @python3_12 (the hermetic Python toolchain we
    # deliberately don't register -- there is no illumos CPython build to download; we use the
    # system Python instead). Skip the registration.
    #register_emscripten_toolchains()

    rust_repository_set(
        name = "rust_linux_s390x",
        exec_triple = "s390x-unknown-linux-gnu",
        extra_target_triples = [
            "wasm32-unknown-unknown",
            "wasm32-wasi",
        ],
        versions = [rust_common.default_version],
    )
    rules_rust_dependencies()

    # illumos: download the pinned Rust 1.88.0 host toolchain from static.rust-lang.org.
    # Rust ships tier-2 host tools (rustc/cargo/std/clippy/rustfmt) for
    # x86_64-unknown-illumos, and rules_rust learns that triple via
    # bazel/illumos-rules_rust.patch. We register an explicit set rather than relying on
    # rust_register_toolchains() (which only iterates DEFAULT_TOOLCHAIN_TRIPLES, no illumos).
    # The repo name MUST be "rust_illumos_x86_64" so crate_universe's default tool templates
    # (@rust_{system}_{arch}__{triple}__{channel}_tools) resolve to the downloaded cargo/rustc.
    # Empty constraints keep the toolchain always-selectable on the single illumos host.
    # The sha256s are the official static.rust-lang.org hashes (pinned for reproducibility);
    # key format is "{tool}-{version}-{triple}.tar.xz".
    rust_repository_set(
        name = "rust_illumos_x86_64",
        exec_triple = "x86_64-unknown-illumos",
        versions = ["1.88.0"],
        exec_compatible_with = [],
        default_target_compatible_with = [],
        sha256s = {
            "rustc-1.88.0-x86_64-unknown-illumos.tar.xz": "f4e53f23b131b0bced09dfaa3aa7c34f62345b30ae5c242846d36407f23a7b62",
            "rust-std-1.88.0-x86_64-unknown-illumos.tar.xz": "13c57363f8549e6156d36bcb46100fec845159aa91f97f674cf783c861050d0b",
            "cargo-1.88.0-x86_64-unknown-illumos.tar.xz": "9eea3a158c2c2174cdee255f171f63df3afe4b83d3836bd6ba06dd87baa8c451",
            "clippy-1.88.0-x86_64-unknown-illumos.tar.xz": "97ac3161d8415417e6ee0e446d102296289146aea714a601f3a8639e0c01b26b",
            "rustfmt-1.88.0-x86_64-unknown-illumos.tar.xz": "6daced23b8fea4333fd5ec3fb59d5cf437ec7c15e07d88f709ccbe6ed8483006",
        },
    )
    crate_universe_dependencies()
    # No prebuilt cargo-bazel exists for illumos (crate_universe/private/urls.bzl), so build
    # it from source with the downloaded host cargo. The default cargo/rustc tool templates
    # resolve to @rust_illumos_x86_64__x86_64-unknown-illumos__stable_tools (no overrides).
    cargo_bazel_bootstrap(
        name = "cargo_bazel_bootstrap",
        rust_version = "1.88.0",
    )
    crates_repositories(cargo_bazel_lockfile = cargo_bazel_lockfile)
    grcov_repository()
    shellcheck_dependencies()
    proxy_wasm_rust_sdk_dependencies()
    rules_fuzzing_dependencies(
        oss_fuzz = True,
        honggfuzz = False,
    )
    register_jq_toolchains(version = jq_version)
    register_yq_toolchains(version = yq_version)
    parser_deps()

    rules_buf_toolchains(
        sha256 = buf_sha,
        version = buf_version,
    )

    setup_sanitizer_libs()

    protoc_gen_jsonschema_go_dependencies()

    # These dependencies, like most of the Go in this repository, exist only for the API.
    # All transitive dependencies are pinned explicitly below to keep builds hermetic.
    go_repository(
        name = "org_golang_google_grpc",
        build_file_proto_mode = "disable",
        importpath = "google.golang.org/grpc",
        sum = "h1:aHQeeJbo8zAkAa3pRzrVjZlbz6uSfeOXlJNQM0RAbz0=",
        version = "v1.68.0",
        build_directives = [
            "gazelle:resolve go google.golang.org/genproto/googleapis/rpc/status @org_golang_google_genproto_googleapis_rpc//status",
            "gazelle:resolve go golang.org/x/net/http2 @org_golang_x_net//http2",
            "gazelle:resolve go golang.org/x/net/http2/hpack @org_golang_x_net//http2/hpack",
            "gazelle:resolve go golang.org/x/net/trace @org_golang_x_net//trace",
            "gazelle:resolve go golang.org/x/sys/unix @org_golang_x_sys//unix",
        ],
    )
    go_repository(
        name = "org_golang_x_net",
        importpath = "golang.org/x/net",
        sum = "h1:Mb7Mrk043xzHgnRM88suvJFwzVrRfHEHJEl5/71CKw0=",
        version = "v0.34.0",
        build_directives = [
            "gazelle:resolve go golang.org/x/sys/unix @org_golang_x_sys//unix",
            "gazelle:resolve go golang.org/x/text/secure/bidirule @org_golang_x_text//secure/bidirule",
            "gazelle:resolve go golang.org/x/text/unicode/bidi @org_golang_x_text//unicode/bidi",
            "gazelle:resolve go golang.org/x/text/unicode/norm @org_golang_x_text//unicode/norm",
        ],
    )
    go_repository(
        name = "org_golang_x_sys",
        importpath = "golang.org/x/sys",
        sum = "h1:3yZWxaJjBmCWXqhN1qh02AkOnCQ1poK6oF+a7xWL6Gc=",
        version = "v0.38.0",
    )
    go_repository(
        name = "org_golang_x_text",
        importpath = "golang.org/x/text",
        sum = "h1:zyQAAkrwaneQ066sspRyJaG9VNi/YJ1NfzcGB3hZ/qo=",
        version = "v0.21.0",
    )
    go_repository(
        name = "org_golang_google_genproto_googleapis_api",
        importpath = "google.golang.org/genproto/googleapis/api",
        sum = "h1:+2XxjfsAu6vqFxwGBRcHiMaDCuZiqXGDUDVWVtrFAnE=",
        version = "v0.0.0-20251029180050-ab9386a59fda",
        build_directives = [
            "gazelle:resolve go google.golang.org/genproto/googleapis/rpc/status @org_golang_google_genproto_googleapis_rpc//status",
        ],
    )
    go_repository(
        name = "org_golang_google_genproto_googleapis_rpc",
        importpath = "google.golang.org/genproto/googleapis/rpc",
        sum = "h1:i/Q+bfisr7gq6feoJnS/DlpdwEL4ihp41fvRiM3Ork0=",
        version = "v0.0.0-20251029180050-ab9386a59fda",
    )
    go_repository(
        name = "org_golang_google_protobuf",
        build_file_proto_mode = "disable",
        importpath = "google.golang.org/protobuf",
        sum = "h1:AYd7cD/uASjIL6Q9LiTjz8JLcrh/88q5UObnmY3aOOE=",
        version = "v1.36.10",
    )
    go_repository(
        name = "xds_go",
        importpath = "github.com/cncf/xds/go",
        sum = "h1:gt7U1Igw0xbJdyaCM5H2CnlAlPSkzrhsebQB6WQWjLA=",
        version = "v0.0.0-20251110193048-8bfbf64dc13e",
        build_directives = [
            "gazelle:resolve go google.golang.org/genproto/googleapis/api/expr/v1alpha1 @org_golang_google_genproto_googleapis_api//expr/v1alpha1",
        ],
    )
    go_repository(
        name = "dev_cel_expr",
        importpath = "cel.dev/expr",
        sum = "h1:1KrZg61W6TWSxuNZ37Xy49ps13NUovb66QLprthtwi4=",
        version = "v0.25.1",
    )
    go_repository(
        name = "com_github_spf13_afero",
        importpath = "github.com/spf13/afero",
        sum = "h1:EaGW2JJh15aKOejeuJ+wpFSHnbd7GE6Wvp3TsNhb6LY=",
        version = "v1.10.0",
        build_directives = [
            "gazelle:resolve go golang.org/x/text/runes @org_golang_x_text//runes",
            "gazelle:resolve go golang.org/x/text/transform @org_golang_x_text//transform",
            "gazelle:resolve go golang.org/x/text/unicode/norm @org_golang_x_text//unicode/norm",
        ],
    )
    go_repository(
        name = "com_github_lyft_protoc_gen_star_v2",
        importpath = "github.com/lyft/protoc-gen-star/v2",
        sum = "h1:sIXJOMrYnQZJu7OB7ANSF4MYri2fTEGIsRLz6LwI4xE=",
        version = "v2.0.4-0.20230330145011-496ad1ac90a4",
        build_directives = [
            "gazelle:resolve go github.com/spf13/afero @com_github_spf13_afero//:afero",
            "gazelle:resolve go golang.org/x/tools/imports @org_golang_x_tools//imports",
        ],
    )
    go_repository(
        name = "com_github_iancoleman_strcase",
        importpath = "github.com/iancoleman/strcase",
        sum = "h1:nTXanmYxhfFAMjZL34Ov6gkzEsSJZ5DbhxWjvSASxEI=",
        version = "v0.3.0",
    )
    go_repository(
        name = "com_github_planetscale_vtprotobuf",
        importpath = "github.com/planetscale/vtprotobuf",
        sum = "h1:ujRGEVWJEoaxQ+8+HMl8YEpGaDAgohgZxJ5S+d2TTFQ=",
        version = "v0.6.1-0.20240409071808-615f978279ca",
    )

    go_repository(
        name = "com_github_envoyproxy_protoc_gen_validate",
        importpath = "github.com/envoyproxy/protoc-gen-validate",
        sum = "h1:TvGH1wof4H33rezVKWSpqKz5NXWg5VPuZ0uONDT6eb4=",
        version = "v1.3.0",
    )

    rules_proto_grpc_toolchains()

def envoy_download_go_sdks(go_version):
    go_download_sdk(
        name = "go_linux_amd64",
        goos = "linux",
        goarch = "amd64",
        version = go_version,
    )
    go_download_sdk(
        name = "go_linux_arm64",
        goos = "linux",
        goarch = "arm64",
        version = go_version,
    )
    go_download_sdk(
        name = "go_darwin_amd64",
        goos = "darwin",
        goarch = "amd64",
        version = go_version,
    )
    go_download_sdk(
        name = "go_darwin_arm64",
        goos = "darwin",
        goarch = "arm64",
        version = go_version,
    )

def crates_repositories(cargo_bazel_lockfile):
    crates_repository(
        name = "envoy_rust_crate_index",
        cargo_lockfile = "@envoy//:Cargo.lock",
        lockfile = Label(cargo_bazel_lockfile),
        manifests = ["@envoy//:Cargo.toml"],
        # illumos: use the source-bootstrapped cargo-bazel (no prebuilt for illumos) and emit
        # crate select() conditions for the illumos triple. The default cargo/rustc tool
        # templates resolve to the downloaded @rust_illumos_x86_64 toolchain, so no overrides.
        # @rules_rust//rust/platform:x86_64-unknown-illumos exists via bazel/illumos-rules_rust.patch.
        generator = "@cargo_bazel_bootstrap//:cargo-bazel",
        supported_platform_triples = [
            "x86_64-unknown-linux-gnu",
            "x86_64-unknown-illumos",
        ],
    )
