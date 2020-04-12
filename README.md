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

Create a SmartOS container (`joyent` brand if your on Joyent's public cloud / Triton). Steps below are performed on a container running the `base-64` image version `20.2.0` (`ad6f47f2-c691-11ea-a6a5-cf0776f07bb7`). 

The following things are good to know:

* As stated in the [bazel-smartos](https://github.com/siepkes/bazel-smartos) repo the Bazel binary depends on a specific GCC version (due to hardcoded version in some paths). 
* When using `export NUM_CPUS=2` you probably require at least 16GB of RAM and 32 GB of swap in your VM to build Envoy. Trying to build with an 8GB VM led to an `ld: fatal: mmap anon failed: Resource temporarily unavailable` error while linking in my case. You can experiment with lowering `NUM_CPUS` if you run in to memory problems.

Install required build packages. Envoy makes use of modern C++ so will only work with a modern C++ compiler.

```
$ pkgin install go ninja-build gcc7 git-base zip unzip openjdk8 libtool cmake automake ninja-build autoconf gmake
```

Configure the build environment:
```
# Needed to prevent a CPU detection algorithm from going awry.
$ export NUM_CPUS=1
$ git clone https://github.com/siepkes/envoy-smartos.git
```

Build Envoy:
```
$ cd envoy-smartos
$ bazel --bazelrc=/dev/null build -c dbg --jobs=4 --define hot_restart=disabled --package_path %workspace%:/root/envoy-smartos/ //source/exe:envoy-static
```

WARNING: As you can see we are building with the debug profile (dbg). Building with the optimized profile (opt) leads to segmentation faults when running Envoy.

To troubleshoot build issues Bazel can be made more talkative with the following options:

```
$ bazel --client_debug --bazelrc=/dev/null build -c dbg --jobs=4 --define hot_restart=disabled --sandbox_debug --verbose_failures --toolchain_resolution_debug --package_path %workspace%:/root/envoy-smartos/ //source/exe:envoy-static
```

This will result in a statically linked binary of Envoy in `./bazel-bin/source/exe/envoy-static`. 

The binary will include debug symbols which you can strip to bring down the size of the binary substantially. Beware that this will make the backtrace library unusable (ie. stacktraces become hard to read):

```
$ strip --strip-debug ./bazel-bin/source/exe/envoy-static
```

### Remarks

#### c_ares version bump

c_ares was bumped to version 1.16.1. This version bump is needed because to build on Illumos we need commit 33ed2aa6d13721b395d14cfdaafdb1f80bb05242 "Add missing limits.h include from ares_getaddrinfo.c".

## Known issues / TODO's

Below is a list of known issues of this port. These are mostly open issues because they represent functionality I didn't need right away and stood in the way of doing a sucessful build. I'm obviously open to any PR / help anyone can offer though!

### Make event ports work

Currently we disable event ports by using the environmental variable `EVENT_NOEVPORT=yes`. When using event ports Envoy (or more likely libevent) starts making a massive number of syscalls. I'm guessing this is because some (event) loop in libevent is going haywire. Probably need to take a look at `libevent_scheduler.cc` how libevent is configured.

### Optimized builds segfault

```
# mdb ./envoy-static /var/cores/envoy-static.envoy-build-1.669423.1556867988.core
Loading modules: [ libc.so.1 ld.so.1 ]
> ::stack
_ZNKSt10_HashtableINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_KZNK5Envoy13DateFormatter8fromTimeB5cxx11ERKNSt6chrono10time_pointINSA_3_V212system_clockENSA_8durationIlSt5ratioILl1ELl1000000000EEEEEEEN10CachedTime9FormattedEESaISO_ENSt8__detail10_Select1stESt8equal_toIS5_ESt4hashIS5_ENSQ_18_Mod_range_hashingENSQ_20_Default_ranged_hashENSQ_20_Prime_rehash_policyENSQ_17_Hashtable_traitsILb1ELb0ELb1EEEE19_M_find_before_nodeEmRS7_m.constprop.1063+0x2e()
_ZNK5Envoy13DateFormatter8fromTimeB5cxx11ERKNSt6chrono10time_pointINS1_3_V212system_clockENS1_8durationIlSt5ratioILl1ELl1000000000EEEEEE+0xb9()
_ZN5Envoy13DateFormatter3nowB5cxx11ERNS_10TimeSourceE+0x39()
_ZN5Envoy4Http26TlsCachingDateProviderImpl13onRefreshDateEv+0x32()
_ZN5Envoy4Http26TlsCachingDateProviderImplC1ERNS_5Event10DispatcherERNS_11ThreadLocal13SlotAllocatorE+0x97()
_ZNSt17_Function_handlerIFSt10shared_ptrIN5Envoy9Singleton8InstanceEEvEZNS1_10Extensions14NetworkFilters21HttpConnectionManager40HttpConnectionManagerFilterConfigFactory33createFilterFactoryFromProtoTypedERKN5envoy6config6filter7network23http_connection_manager2v221HttpConnectionManagerERNS1_6Server13Configuration14FactoryContextEEUlvE_E9_M_invokeERKSt9_Any_data+0x61()
_ZN5Envoy9Singleton11ManagerImpl3getERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt8functionIFSt10shared_ptrINS0_8InstanceEEvEE+0x2b6()
_ZN5Envoy10Extensions14NetworkFilters21HttpConnectionManager40HttpConnectionManagerFilterConfigFactory33createFilterFactoryFromProtoTypedERKN5envoy6config6filter7network23http_connection_manager2v221HttpConnectionManagerERNS_6Server13Configuration14FactoryContextE+0xb7()
_ZN5Envoy10Extensions14NetworkFilters6Common11FactoryBaseIN5envoy6config6filter7network23http_connection_manager2v221HttpConnectionManagerESA_E28createFilterFactoryFromProtoERKN6google8protobuf7MessageERNS_6Server13Configuration14FactoryContextE+0x9d()
_ZN5Envoy6Server28ProdListenerComponentFactory31createNetworkFilterFactoryList_ERKN6google8protobuf16RepeatedPtrFieldIN5envoy3api2v28listener6FilterEEERNS0_13Configuration14FactoryContextE+0x864()
_ZN5Envoy6Server12ListenerImplC1ERKN5envoy3api2v28ListenerERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEERNS0_19ListenerManagerImplESF_bbm+0xc30()
_ZN5Envoy6Server19ListenerManagerImpl19addOrUpdateListenerERKN5envoy3api2v28ListenerERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEb+0x22e()
_ZN5Envoy6Server13Configuration8MainImpl10initializeERKN5envoy6conc                                        fig9bootstrap2v29BootstrapERNS0_8InstanceERNS_8Upstream21ClusterManagerFactoryE+0x3a6()
_ZN5Envoy6Server12InstanceImpl10initializeERKNS0_7OptionsESt10shared_ptrIKNS_7Network7Address8InstanceEERNS0_16ComponentFactoryERNS_9TestHooksE+0x1dab()
_ZN5Envoy6Server12InstanceImplC1ERKNS0_7OptionsERNS_5Event10TimeSystemESt10shared_ptrIKNS_7Network7Address8InstanceEERNS_9TestHooksERNS0_10HotRestartERNS_5Stats9StoreRootERNS_6Thread13BasicLockableERNS0_16ComponentFactoryEOSt10unique_ptrINS_7Runtime15RandomGeneratorESt14default_deleteISS_EERNS_11ThreadLocal8InstanceERNSL_13ThreadFactoryERNS_10Filesystem8InstanceE+0x63a()
_ZN5Envoy14MainCommonBaseC1ERKNS_11OptionsImplERNS_5Event10TimeSystemERNS_9TestHooksERNS_6Server16ComponentFactoryEOSt10unique_ptrINS_7Runtime15RandomGeneratorESt14default_deleteISE_EERNS_6Thread13ThreadFactoryERNS_10Filesystem8InstanceE+0x70e()
_ZN5Envoy10MainCommonC1EiPKPKc+0x116()
main+0x36()
_start_crt+0x83()
_start+0x18()
```

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

```
$ export JAVA_HOME="/opt/local/java/openjdk8"
$ bazel test --host_javabase=@local_jdk//:jdk //test/... 
```

### Hot restart disabled

Currently we pass `--define hot_restart=disabled` when building to disable Hot restart (ie. restart Envoy without client connections being closed). Hot restart is disabled because it didn't work without modifications and I didn't have a need for it. 

# Original Envoy Readme

![Envoy Logo](https://github.com/envoyproxy/artwork/blob/master/PNG/Envoy_Logo_Final_PANTONE.png)

[Cloud-native high-performance edge/middle/service proxy](https://www.envoyproxy.io/)

Envoy is hosted by the [Cloud Native Computing Foundation](https://cncf.io) (CNCF). If you are a
company that wants to help shape the evolution of technologies that are container-packaged,
dynamically-scheduled and microservices-oriented, consider joining the CNCF. For details about who's
involved and how Envoy plays a role, read the CNCF
[announcement](https://www.cncf.io/blog/2017/09/13/cncf-hosts-envoy/).

[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1266/badge)](https://bestpractices.coreinfrastructure.org/projects/1266)
[![Azure Pipelines](https://dev.azure.com/cncf/envoy/_apis/build/status/11?branchName=master)](https://dev.azure.com/cncf/envoy/_build/latest?definitionId=11&branchName=master)
[![CircleCI](https://circleci.com/gh/envoyproxy/envoy/tree/master.svg?style=shield)](https://circleci.com/gh/envoyproxy/envoy/tree/master)
[![Fuzzing Status](https://oss-fuzz-build-logs.storage.googleapis.com/badges/envoy.svg)](https://bugs.chromium.org/p/oss-fuzz/issues/list?sort=-opened&can=1&q=proj:envoy)
[![fuzzit](https://app.fuzzit.dev/badge?org_id=envoyproxy)](https://app.fuzzit.dev/orgs/envoyproxy/dashboard)
[![Jenkins](https://img.shields.io/jenkins/s/https/powerci.osuosl.org/job/build-envoy-master/badge/icon/.svg?label=ppc64le%20build)](http://powerci.osuosl.org/job/build-envoy-master/)

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
* [envoy-security-announce](https://groups.google.com/forum/#!forum/envoy-security-announce): Low frequency mailing
  list where we will email security related announcements only.
* [envoy-users](https://groups.google.com/forum/#!forum/envoy-users): General user discussion.
* [envoy-dev](https://groups.google.com/forum/#!forum/envoy-dev): Envoy developer discussion (APIs,
  feature design, etc.).
* [envoy-maintainers](https://groups.google.com/forum/#!forum/envoy-maintainers): Use this list
  to reach all core Envoy maintainers.
* [Twitter](https://twitter.com/EnvoyProxy/): Follow along on Twitter!
* [Slack](https://envoyproxy.slack.com/): Slack, to get invited go [here](https://envoyslack.cncf.io).
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

The Envoy team meets twice per month on Tuesday, alternating between 9am PT and 5PM PT. The public
Google calendar is here: https://goo.gl/PkDijT

* Meeting minutes are [here](https://goo.gl/5Cergb)
* Recorded videos are posted [here](https://www.youtube.com/channel/UCvqbFHwN-nwalWPjPUKpvTA/videos?view=0&sort=dd&shelf_id=1)

## Security

### Security Audit

A third party security audit was performed by Cure53, you can see the full report [here](docs/SECURITY_AUDIT.pdf).

### Reporting security vulnerabilities

If you've found a vulnerability or a potential vulnerability in Envoy please let us know at
[envoy-security](mailto:envoy-security@googlegroups.com). We'll send a confirmation
email to acknowledge your report, and we'll send an additional email when we've identified the issue
positively or negatively.

For further details please see our complete [security release process](SECURITY.md).
