# Envoy SmartOS / Illumos / Solaris port

**(Scroll down for original Envoy readme.md)**

This repo contains a SmartOS port for Envoy. It will probably also work on Solaris though it will probably require modifications since we assume the use of pkgsrc.

To build this Envoy port you need Bazel. This requires a SmartOS / Illumos / Solaris port of Bazel since Bazel does not natively support these platforms. See the [bazel-smartos](https://github.com/siepkes/bazel-smartos) repo for a SmartOS port. My intention being to properly upstream the thing but that takes some work... Feel free to reach out to me if you encounter any issues.

## Building Envoy on SmartOS

Create a SmartOS container (`joyent` brand if your on Joyent's public cloud / Triton). Steps below are performed on a container running the `pkgbuild` image version `17.4.0`.

Install required build packages. Envoy makes use of modern C++ so will only work with a modern C++ compiler.

```
$ pkgin install ninja-build gcc7 git-base zip unzip openjdk8 libtool cmake automake ninja-build autoconf gmake
```

Configure the build environment:
```
# Needed to prevent a CPU detection algorithm from going awry.
$ export NUM_CPUS=2

# Needed otherwise the io_opentrace build fails complaining it can't find the compiler.
$ export PATH=$PATH:/opt/local/gcc7/bin

# Needed to make CMake / Ninja use the correct compiler (ie. the build scripts under 'ci/build_container/build_recipes').
$ export CC=/opt/local/gcc7/bin/gcc
$ export CXX=/opt/local/gcc7/bin/g++
```

Build Envoy:
```
$ cd /root/envoy/
$ bazel build -c opt --jobs=4 --define hot_restart=disabled --define signal_trace=disabled --package_path %workspace%:/root/envoy/ //source/exe:envoy-static
```

This will result in a statically linked binary of Envoy. The binary will include debug symbols which you can strip to bring down the size of the binary substantially:

```
$ strip bazel-bin/source/exe/envoy-static
```

## Known issues

Below is a list of known issues of this port. These are mostly open issues because they represent functionality I didn't need right away and stood in the way of doing a sucessful build. I'm obviously open to any PR / help anyone can offer though!

### Final binary requires GCC7 package

Due to the way the linking is currently configured the final Envoy binary requires the `gcc7` package to be installed in the container:

```
$ ldd bazel-bin/source/exe/envoy-static
        librt.so.1 =>    /lib/64/librt.so.1
        libdl.so.1 =>    /lib/64/libdl.so.1
        libpthread.so.1 =>       /lib/64/libpthread.so.1
        libm.so.2 =>     /lib/64/libm.so.2
        libstdc++.so.6 =>        /opt/local/gcc7//lib/amd64/libstdc++.so.6
        libxnet.so.1 =>  /lib/64/libxnet.so.1
        libsocket.so.1 =>        /lib/64/libsocket.so.1
        libnsl.so.1 =>   /lib/64/libnsl.so.1
        libgcc_s.so.1 =>         /opt/local/gcc7//lib/amd64/libgcc_s.so.1
        libc.so.1 =>     /lib/64/libc.so.1
        libmp.so.2 =>    /lib/64/libmp.so.2
        libmd.so.1 =>    /lib/64/libmd.so.1
```

### Get entire test suite to run

Headline covers it.

### IPv6 to IPv4 disabled

Support for IPv6 to IPv4 was disabled due to compilation errors. See modifications to `source/common/network/address_impl.cc` for more info.

### Hot restart disabled

Currently we pass `--define hot_restart=disabled` when building  to disable Hot restart (ie. restart Envoy without client connections being closed). Hot restart is disabled because it didn't work without modifications and I didn't have a need for it. 

### Backtrace disabled

Due to issues when building 1.8 (didn't encounter these with 1.7) backtrace is currently disabled with the `--define signal_trace=disabled` flag. 

We run in to the following error when building:

```
DEBUG: /root/envoy/bazel/repositories.bzl:121:5: External dep build exited with return code: 0
INFO: Analysed target //source/exe:envoy-static (1 packages loaded).
INFO: Found 1 target...
INFO: From Compiling external/com_google_absl/absl/time/internal/cctz/src/civil_time_detail.cc:
In file included from external/com_google_absl/absl/time/internal/cctz/src/civil_time_detail.cc:15:0:
external/com_google_absl/absl/time/internal/cctz/include/cctz/civil_time_detail.h: In function 'int absl::time_internal::cctz::detail::impl::days_per_month(absl::time_internal::cctz::year_t, absl::time_internal::cctz::detail::month_t)':
external/com_google_absl/absl/time/internal/cctz/include/cctz/civil_time_detail.h:101:28: warning: array subscript has type 'char' [-Wchar-subscripts]
   return k_days_per_month[m] + (m == 2 && is_leap_year(y));
                            ^
ERROR: /root/envoy/source/exe/BUILD:82:1: C++ compilation of rule '//source/exe:sigaction_lib' failed (Exit 1)
In file included from bazel-out/solaris-opt/bin/source/server/_virtual_includes/backtrace_lib/server/backtrace.h:3:0,
                 from bazel-out/solaris-opt/bin/source/exe/_virtual_includes/sigaction_lib/exe/signal_action.h:10,
                 from source/exe/signal_action.cc:1:
external/com_github_bombela_backward/backward.hpp: In member function 'std::size_t backward::StackTraceImpl<backward::system_tag::unknown_tag>::load_here(std::size_t)':
external/com_github_bombela_backward/backward.hpp:795:22: error: 'backtrace' was not declared in this scope
   size_t trace_cnt = backtrace(&_stacktrace[0], _stacktrace.size());
                      ^~~~~~~~~
external/com_github_bombela_backward/backward.hpp:795:22: note: suggested alternative: '_stacktrace'
   size_t trace_cnt = backtrace(&_stacktrace[0], _stacktrace.size());
                      ^~~~~~~~~
                      _stacktrace
Target //source/exe:envoy-static failed to build
Use --verbose_failures to see the command lines of failed build steps.
```

### Linker spits out massive number of warnings

On completion the linker spits out a massive number of warnings (most about relocations). So massive that it takes a couple of minutes for the terminal to catch up. As far as I can tell this is not a problem for the final binary. However this is something that should obviously be addressed at some point.

# Original Envoy Readme

![Envoy Logo](https://github.com/envoyproxy/artwork/blob/master/PNG/Envoy_Logo_Final_PANTONE.png)

[C++ L7 proxy and communication bus](https://www.envoyproxy.io/)

Envoy is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF). If you are a
company that wants to help shape the evolution of technologies that are container-packaged,
dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details about who's
involved and how Envoy plays a role, read the CNCF
[announcement](https://www.cncf.io/blog/2017/09/13/cncf-hosts-envoy/).

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1266/badge)](https://bestpractices.coreinfrastructure.org/projects/1266)

## Documentation

* [Official documentation](https://www.envoyproxy.io/)
* [FAQ](https://www.envoyproxy.io/docs/envoy/latest/faq/overview)
* [Unofficial Chinese documentation](https://github.com/servicemesher/envoy/)
* Watch [a video overview of Envoy](https://www.youtube.com/watch?v=RVZX4CwKhGE)
([transcript](https://www.microservices.com/talks/lyfts-envoy-monolith-service-mesh-matt-klein/))
to find out more about the origin story and design philosophy of Envoy
* [Blog](https://medium.com/@mattklein123/envoy-threading-model-a8d44b922310) about the threading model
* [Blog](https://medium.com/@mattklein123/envoy-hot-restart-1d16b14555b5) about hot restart
* [Blog](https://medium.com/@mattklein123/envoy-stats-b65c7f363342) about stats architecture
* [Blog](https://medium.com/@mattklein123/the-universal-data-plane-api-d15cec7a) about universal data plane API
* [Blog](https://medium.com/@mattklein123/lyfts-envoy-dashboards-5c91738816b1) on Lyft's Envoy dashboards

## Related

* [data-plane-api](https://github.com/envoyproxy/data-plane-api): v2 API definitions as a standalone
  repository. This is a read-only mirror of [api](api/).
* [envoy-perf](https://github.com/envoyproxy/envoy-perf): Performance testing framework.
* [envoy-filter-example](https://github.com/envoyproxy/envoy-filter-example): Example of how to add new filters
  and link to the main repository.

## Contact

* [envoy-announce](https://groups.google.com/forum/#!forum/envoy-announce): Low frequency mailing
  list where we will email announcements only.
* [envoy-users](https://groups.google.com/forum/#!forum/envoy-users): General user discussion.
* [envoy-dev](https://groups.google.com/forum/#!forum/envoy-dev): Envoy developer discussion (APIs,
  feature design, etc.).
* [envoy-maintainers](https://groups.google.com/forum/#!forum/envoy-maintainers): Use this list
  to reach all core Envoy maintainers.
* [Twitter](https://twitter.com/EnvoyProxy/): Follow along on Twitter!
* [Slack](https://envoyproxy.slack.com/): Slack, to get invited go [here](http://envoyslack.cncf.io).
  We have the IRC/XMPP gateways enabled if you prefer either of those. Once an account is created,
  connection instructions for IRC/XMPP can be found [here](https://envoyproxy.slack.com/account/gateways).
  * NOTE: Response to user questions is best effort on Slack. For a "guaranteed" response please email
    envoy-users@ per the guidance in the following linked thread.

Please see [this](https://groups.google.com/forum/#!topic/envoy-announce/l9zjYsnS3TY) email thread
for information on email list usage.

## Contributing

Contributing to Envoy is fun and modern C++ is a lot less scary than you might think if you don't
have prior experience. To get started:

* [Contributing guide](CONTRIBUTING.md)
* [Beginner issues](https://github.com/envoyproxy/envoy/issues?q=is%3Aopen+is%3Aissue+label%3Abeginner)
* [Build/test quick start using docker](ci#building-and-running-tests-as-a-developer)
* [Developer guide](DEVELOPER.md)
* Consider installing the Envoy [development support toolchain](https://github.com/envoyproxy/envoy/blob/master/support/README.md), which helps automate parts of the development process, particularly those involving code review.
* Please make sure that you let us know if you are working on an issue so we don't duplicate work!

## Community Meeting

The Envoy team meets every other Tuesday at 9am PT. The public Google calendar is here: https://goo.gl/PkDijT

Meeting minutes are here: https://goo.gl/5Cergb

## Security

### Security Audit

A third party security audit was performed by Cure53, you can see the full report [here](docs/SECURITY_AUDIT.pdf).

### Reporting security vulnerabilities

If you've found a vulnerability or a potential vulnerability in Envoy please let us know at
[envoy-security](mailto:envoy-security@googlegroups.com). We'll send a confirmation
email to acknowledge your report, and we'll send an additional email when we've identified the issue
positively or negatively.

For further details please see our complete [security release process](SECURITY_RELEASE_PROCESS.md).
