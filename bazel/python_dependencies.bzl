load("@envoy_toolshed//:packages.bzl", "load_packages")
load("@rules_python//python:pip.bzl", "pip_parse")

def envoy_python_dependencies():
    # TODO(phlax): rename base_pip3 -> pip3 and remove this
    load_packages()
    pip_parse(
        name = "base_pip3",
        experimental_requirement_cycles = {
            "sphinx": [
                "sphinx",
                "sphinxcontrib-serializinghtml",
                "sphinxcontrib-qthelp",
                "sphinxcontrib-htmlhelp",
                "sphinxcontrib-devhelp",
                "sphinxcontrib-applehelp",
            ],
        },
        requirements_lock = "@envoy//tools/base:requirements.txt",
        extra_pip_args = ["--require-hashes"],
    )

    pip_parse(
        name = "dev_pip3",
        requirements_lock = "@envoy//tools/dev:requirements.txt",
    )

    pip_parse(
        name = "fuzzing_pip3",
        requirements_lock = "@rules_fuzzing//fuzzing:requirements.txt",
        extra_pip_args = ["--require-hashes"],
    )
