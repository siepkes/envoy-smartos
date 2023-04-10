# Envoy SmartOS / Illumos / Solaris port

**(Scroll down for original Envoy readme.md)**

This repo contains a SmartOS port for Envoy. It will probably also work on Solaris though it will probably require modifications since we assume the use of pkgsrc.

To build this Envoy port you need Bazel. This requires a SmartOS / Illumos / Solaris port of Bazel since Bazel does not natively support these platforms. See the [bazel-smartos](https://github.com/siepkes/bazel-smartos) repo for a SmartOS port. My intention being to properly upstream the thing but that takes some work... Feel free to reach out to me if you encounter any issues.

## Running Envoy on SmartOS

**WARNING: When running set the environmental variable `EVENT_NOEVPORT=yes`.**

Envoy uses libevent which uses event ports on Illumos (the native non-blocking IO implementation on Illumos). For some reason when using event ports libevent starts making a massive number of syscalls (as many as the CPU limits allow). Therefor we disable the event ports implementation in libevent for now.

```
$ export EVENT_NOEVPORT=yes
$ ./envoy-static --disable-hot-restart -c ./config.yaml
```

## Building Envoy on SmartOS

Create a SmartOS container (`joyent` brand if your on Joyent's public cloud / Triton). Steps below are performed on a container running the `base-64-lts` image version `20.4.0` (`1d05e788-5409-11eb-b12f-037bd7fee4ee`).

The following things are good to know:

* As stated in the [bazel-smartos](https://github.com/siepkes/bazel-smartos) repo the Bazel binary depends on a specific GCC version (due to hardcoded version in some paths).
* When using `export NUM_CPUS=2` you probably require at least 16GB of RAM and 32 GB of swap in your VM to build Envoy. Trying to build with an 8GB VM led to an `ld: fatal: mmap anon failed: Resource temporarily unavailable` error while linking in my case. You can experiment with lowering `NUM_CPUS` if you run in to memory problems.

Install required build packages. Envoy makes use of modern C++ so will only work with a modern C++ compiler.

```
# pkgin -y install go117 ninja-build gcc9 git-base zip unzip openjdk11 libtool cmake automake ninja-build autoconf gmake python39 py39-expat
```

Recent version of Bazel's `rules_pkg` run some tests which expect the ability to use UTF-8 characters in directory and file names. Modify `/etc/defaults/init` and add the following to enable UTF-8 support. Reboot the container after making these modifications:

```
CMASK=022
# Specifies the locale to use for all purposes except as overridden by the variables below.
LANG=en_US.UTF-8
# Determines the effect of character handling functions.
LC_CTYPE=en_US.UTF-8
# Determines the decimal point character and thousands separator character.
LC_NUMERIC=en_US.UTF-8
# Determines the date/time format.
LC_TIME=en_US.UTF-8
# Determines the order in which the output is sorted.
LC_COLLATE=en_US.UTF-8
# Determines the format for monetary symbols.
LC_MONETARY=en_US.UTF-8
# Determines the format of standard operating system messages.
LC_MESSAGES=en_US.UTF-8
# Used to set a single locale for all purposes, overrides all variables listed above.
# Not always supported by all applications.
LC_ALL=en_US.UTF-8
```

Bazel will try to build the extensions that use Python (for example Kafka filter) for every Python version that is installed. Meaning you need to have the Python modules such as `py39-expat` installed for every installed Python version (for example `py37-expat` if Python 3.7 is also installed). When bumping Triton image version verify the package Python version. So beware that having other versions of Python installed in your build VM might complicate the build process. The same goes for Go; Having a more recent version or multiple versions of Go installed can lead to build issues.

Configure the build environment:
```
$ git clone https://github.com/siepkes/envoy-smartos.git
```

Build Envoy with clang (building with GCC might not work due to [issues](https://github.com/envoyproxy/envoy/issues/14788)):
```
$ cd envoy-smartos
$ git checkout smartos-v1.22.10
$ export NUM_CPUS=2  # Needed to prevent a CPU detection algorithm from going awry.
$ export JAVA_HOME="/opt/local/java/openjdk11"
$ bazel build -c opt --jobs=3 \
   --config=illumos \
   --define hot_restart=disabled \
   --verbose_failures \
   --subcommands \
   --sandbox_debug \
   --toolchain_resolution_debug \
   --//source/extensions/bootstrap/wasm:enabled=false \
   --//source/extensions/wasm_runtime/v8:enabled=false \
   --package_path %workspace%:/root/envoy-smartos/ \
   //source/exe:envoy-static
```

To troubleshoot build issues Bazel can be made more talkative by adding the following flags:

```
--sandbox_debug --verbose_failures --toolchain_resolution_debug
```

This will result in a statically linked binary of Envoy in `./bazel-bin/source/exe/envoy-static`.

The binary will include debug symbols which you can strip to bring down the size of the binary substantially. Beware that this will make the backtrace library unusable (ie. stacktraces become hard to read):

```
$ strip --strip-debug ./bazel-bin/source/exe/envoy-static
```

## Known issues / TODO's / Remarks

Below is a list of known issues of this port. These are mostly open issues because they represent functionality I didn't need right away and stood in the way of doing a sucessful build. I'm obviously open to any PR / help anyone can offer though!

### Make webassembly runtime work

We currently disable WASM in `.bazerc` when building. Reason for this is that the V8 WASM runtime currently doesn't build on Illumos. Envoy can be configured to use a different WASM runtime but for now WASM is just disabled.

Additionally building the WASM extensions which GCC does not work. Leading to errors such as the one below. Apparantly these issues are not present when using clang instead of GCC (See [Envoy issue 14788](https://github.com/envoyproxy/envoy/issues/14788)).

```
external/com_google_absl/absl/time/internal/cctz/include/cctz/civil_time_detail.h: In function 'constexpr int absl::time_internal::cctz::detail::impl::days_per_month(absl::time_internal::cctz::year_t, absl::time_internal::cctz::detail::month_t)':
external/com_google_absl/absl/time/internal/cctz/include/cctz/civil_time_detail.h:104:28: warning: array subscript has type 'char' [-Wchar-subscripts]
   return k_days_per_month[m] + (m == 2 && is_leap_year(y));
                            ^
external/com_google_cel_cpp/eval/eval/ternary_step.cc: In function 'absl::StatusOr<std::unique_ptr<google::api::expr::runtime::ExpressionStep> > google::api::expr::runtime::CreateTernaryStep(int64_t)':
external/com_google_cel_cpp/eval/eval/ternary_step.cc:75:10: error: could not convert 'step' from 'std::unique_ptr<google::api::expr::runtime::ExpressionStep>' to 'absl::StatusOr<std::unique_ptr<google::api::expr::runtime::ExpressionStep> >'
   return step;
          ^~~~

```

### Make event ports work

Currently we disable event ports by using the environmental variable `EVENT_NOEVPORT=yes`. When using event ports Envoy (or more likely libevent) starts making a massive number of syscalls. I'm guessing this is because some (event) loop in libevent is going haywire. Probably need to take a look at `libevent_scheduler.cc` how libevent is configured.

### Final binary requires GCC package

Due to the way the linking is currently configured the final Envoy binary requires the GCC package to be installed in the container:

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

```
$ export JAVA_HOME="/opt/local/java/openjdk11"
$ bazel test --host_javabase=@local_jdk//:jdk //test/...
```

### Hot restart disabled

Currently we pass `--define hot_restart=disabled` via `.bazelrc` when building to disable Hot restart (ie. restart Envoy without client connections being closed). Hot restart is disabled because it didn't work without modifications and I didn't have a need for it.

#### py37-expat package requirement.

The `py37-expat` package must be installed otherwise the build dies with the output below. I (@siepkes) think this might actually be a bug in upstream since requiring manual install of the package is not really what Bazel is about?

```
[INFO 08:56:26.568 src/main/cpp/rc_file.cc:131] Skipped optional import of /root/envoy-smartos/local_tsan.bazelrc, the specified rc file either does not exist or is not readable.
[INFO 08:56:26.568 src/main/cpp/rc_file.cc:56] Parsing the RcFile /dev/null
[INFO 08:56:26.569 src/main/cpp/blaze.cc:1623] Debug logging requested, sending all client log statements to stderr
[INFO 08:56:26.570 src/main/cpp/blaze.cc:1506] Acquired the client lock, waited 0 milliseconds
[INFO 08:56:26.577 src/main/cpp/blaze.cc:1694] Trying to connect to server (timeout: 30 secs)...
[INFO 08:56:26.590 src/main/cpp/blaze_util_illumos.cc:126] PID: 658256 (/root/envoy-smartos).
[INFO 08:56:26.590 src/main/cpp/blaze.cc:1261] Connected (server pid=658256).
[INFO 08:56:26.590 src/main/cpp/blaze.cc:1971] Releasing client lock, let the server manage concurrent requests.
INFO: Repository config_validation_pip3 instantiated at:
  no stack (--record_rule_instantiation_callstack not enabled)
Repository rule pip_import defined at:
  /root/.cache/bazel/_bazel_root/7558a64af10a6eb79f74e70211660103/external/rules_python/python/pip.bzl:51:29: in <toplevel>
ERROR: An error occurred during the fetch of repository 'config_validation_pip3':
   pip_import failed:  (Traceback (most recent call last):
  File "/opt/local/lib/python3.7/runpy.py", line 193, in _run_module_as_main
    "__main__", mod_spec)
  File "/opt/local/lib/python3.7/runpy.py", line 85, in _run_code
    exec(code, run_globals)
  File "/root/.cache/bazel/_bazel_root/7558a64af10a6eb79f74e70211660103/external/rules_python/tools/piptool.par/__main__.py", line 26, in <module>
  File "/root/.cache/bazel/_bazel_root/7558a64af10a6eb79f74e70211660103/external/rules_python/tools/piptool.par/piptool_deps_pypi__setuptools_44_0_0/pkg_resources/__init__.py", line 35, in <module>
  File "/opt/local/lib/python3.7/plistlib.py", line 65, in <module>
    from xml.parsers.expat import ParserCreate
  File "/opt/local/lib/python3.7/xml/parsers/expat.py", line 4, in <module>
    from pyexpat import *
ModuleNotFoundError: No module named 'pyexpat'
)
ERROR: no such package '@config_validation_pip3//': pip_import failed:  (Traceback (most recent call last):
  File "/opt/local/lib/python3.7/runpy.py", line 193, in _run_module_as_main
    "__main__", mod_spec)
  File "/opt/local/lib/python3.7/runpy.py", line 85, in _run_code
    exec(code, run_globals)
  File "/root/.cache/bazel/_bazel_root/7558a64af10a6eb79f74e70211660103/external/rules_python/tools/piptool.par/__main__.py", line 26, in <module>
  File "/root/.cache/bazel/_bazel_root/7558a64af10a6eb79f74e70211660103/external/rules_python/tools/piptool.par/piptool_deps_pypi__setuptools_44_0_0/pkg_resources/__init__.py", line 35, in <module>
  File "/opt/local/lib/python3.7/plistlib.py", line 65, in <module>
    from xml.parsers.expat import ParserCreate
  File "/opt/local/lib/python3.7/xml/parsers/expat.py", line 4, in <module>
    from pyexpat import *
ModuleNotFoundError: No module named 'pyexpat'
)
INFO: Elapsed time: 10.114s
INFO: 0 processes.
FAILED: Build did NOT complete successfully (0 packages loaded)
    Fetching @headersplit_pip3; fetching 9s
    Fetching @configs_pip3; fetching 9s
    Fetching @kafka_pip3; fetching 9s
    Fetching @thrift_pip3; fetching 9s
    Fetching @protodoc_pip3; fetching 9s
```

# Original Envoy Readme

![Envoy Logo](https://github.com/envoyproxy/artwork/blob/main/PNG/Envoy_Logo_Final_PANTONE.png)

[Cloud-native high-performance edge/middle/service proxy](https://www.envoyproxy.io/)

Envoy is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF). If you are a
company that wants to help shape the evolution of technologies that are container-packaged,
dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details about who's
involved and how Envoy plays a role, read the CNCF
[announcement](https://www.cncf.io/blog/2017/09/13/cncf-hosts-envoy/).

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1266/badge)](https://bestpractices.coreinfrastructure.org/projects/1266)
[![Azure Pipelines](https://dev.azure.com/cncf/envoy/_apis/build/status/11?branchName=main)](https://dev.azure.com/cncf/envoy/_build/latest?definitionId=11&branchName=main)
[![Fuzzing Status](https://oss-fuzz-build-logs.storage.googleapis.com/badges/envoy.svg)](https://bugs.chromium.org/p/oss-fuzz/issues/list?sort=-opened&can=1&q=proj:envoy)
[![Jenkins](https://powerci.osuosl.org/buildStatus/icon?job=build-envoy-static-master&subject=ppc64le%20build)](https://powerci.osuosl.org/job/build-envoy-static-master/)

## Documentation

* [Official documentation](https://www.envoyproxy.io/)
* [FAQ](https://www.envoyproxy.io/docs/envoy/latest/faq/overview)
* [Unofficial Chinese documentation](https://cloudnative.to/envoy/)
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
* [envoy-security-announce](https://groups.google.com/forum/#!forum/envoy-security-announce): Low frequency mailing
  list where we will email security related announcements only.
* [envoy-users](https://groups.google.com/forum/#!forum/envoy-users): General user discussion.
* [envoy-dev](https://groups.google.com/forum/#!forum/envoy-dev): Envoy developer discussion (APIs,
  feature design, etc.).
* [envoy-maintainers](https://groups.google.com/forum/#!forum/envoy-maintainers): Use this list
  to reach all core Envoy maintainers.
* [Twitter](https://twitter.com/EnvoyProxy/): Follow along on Twitter!
* [Slack](https://envoyproxy.slack.com/): Slack, to get invited go [here](https://envoyproxy.io/slack).
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
* Consider installing the Envoy [development support toolchain](https://github.com/envoyproxy/envoy/blob/main/support/README.md), which helps automate parts of the development process, particularly those involving code review.
* Please make sure that you let us know if you are working on an issue so we don't duplicate work!

## Community Meeting

The Envoy team meets twice per month on Tuesday at 9am PT. The public
Google calendar is here: https://goo.gl/PkDijT

* Meeting minutes are [here](https://goo.gl/5Cergb)
* Recorded videos are posted [here](https://www.youtube.com/channel/UC5z5mvPgqMs1xo5VuIWzYTA)

## Security

### Security Audit

There has been several third party engagements focused on Envoy security:
* In 2018 Cure53 performed a security audit, [full report](docs/security/audit_cure53_2018.pdf).
* In 2021 Ada Logics performed an audit on our fuzzing infrastructure with recommendations for improvements, [full report](docs/security/audit_fuzzer_adalogics_2021.pdf).

### Reporting security vulnerabilities

If you've found a vulnerability or a potential vulnerability in Envoy please let us know at
[envoy-security](mailto:envoy-security@googlegroups.com). We'll send a confirmation
email to acknowledge your report, and we'll send an additional email when we've identified the issue
positively or negatively.

For further details please see our complete [security release process](SECURITY.md).
