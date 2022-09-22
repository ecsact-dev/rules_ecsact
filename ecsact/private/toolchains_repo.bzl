"""Create a repository to hold the toolchains

This follows guidance here:
https://docs.bazel.build/versions/main/skylark/deploying.html#registering-toolchains
"
Note that in order to resolve toolchains in the analysis phase
Bazel needs to analyze all toolchain targets that are registered.
Bazel will not need to analyze all targets referenced by toolchain.toolchain attribute.
If in order to register toolchains you need to perform complex computation in the repository,
consider splitting the repository with toolchain targets
from the repository with <LANG>_toolchain targets.
Former will be always fetched,
and the latter will only be fetched when user actually needs to build <LANG> code.
"
The "complex computation" in our case is simply downloading large artifacts.
This guidance tells us how to avoid that: we put the toolchain targets in the alias repository
with only the toolchain attribute pointing into the platform-specific repositories.
"""

# Add more platforms as needed to mirror all the binaries
# published by the upstream project.
PLATFORMS = {
    "linux_x64": struct(
        compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
    ),
    "windows_x64": struct(
        compatible_with = [
            "@platforms//os:windows",
            "@platforms//cpu:x86_64",
        ],
    ),
}

# Expose a concrete toolchain which is the result of Bazel resolving the
# toolchain for the execution or target platform.
# Workaround for https://github.com/bazelbuild/bazel/issues/14009
_STARLARK_CONTENT = """# Generated by toolchains_repo.bzl

# Forward all the providers
def _resolved_toolchain_impl(ctx):
    toolchain_info = ctx.toolchains["@rules_ecsact//ecsact:toolchain_type"]
    return [
        toolchain_info,
        toolchain_info.default,
        toolchain_info.ecsact_info,
        toolchain_info.template_variables,
    ]

# Copied from java_toolchain_alias
# https://cs.opensource.google/bazel/bazel/+/master:tools/jdk/java_toolchain_alias.bzl
resolved_toolchain = rule(
    implementation = _resolved_toolchain_impl,
    toolchains = ["@rules_ecsact//ecsact:toolchain_type"],
    incompatible_use_toolchain_transition = True,
)
"""

_BUILD_CONTENT = """# Generated by toolchains_repo.bzl
#
# These can be registered in the workspace file or passed to --extra_toolchains flag.
# By default all these toolchains are registered by the ecsact_register_toolchains macro
# so you don't normally need to interact with these targets.

load(":defs.bzl", "resolved_toolchain")

resolved_toolchain(name = "resolved_toolchain", visibility = ["//visibility:public"])

toolchain(
    name = "system_toolchain",
    toolchain = "@{user_repository_name}//:ecsact_toolchain",
    toolchain_type = "@rules_ecsact//ecsact:toolchain_type",
)
"""

_PLATFORM_BUILD_CONTENT = """
# Declare a toolchain Bazel will select for running the tool in an action
# on the execution platform.
toolchain(
    name = "{platform}_toolchain",
    exec_compatible_with = {compatible_with},
    toolchain = "@{user_repository_name}_{platform}//:ecsact_toolchain",
    toolchain_type = "@rules_ecsact//ecsact:toolchain_type",
)
"""

def _toolchains_repo_impl(rctx):
    rctx.file("defs.bzl", _STARLARK_CONTENT)

    build_content = _BUILD_CONTENT.format(
        user_repository_name = rctx.attr.user_repository_name,
    )

    for [platform, meta] in PLATFORMS.items():
        build_content += _PLATFORM_BUILD_CONTENT.format(
            platform = platform,
            name = rctx.attr.name,
            user_repository_name = rctx.attr.user_repository_name,
            compatible_with = meta.compatible_with,
        )

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", build_content)

toolchains_repo = repository_rule(
    _toolchains_repo_impl,
    doc = "Creates a repository with toolchain definitions for all known platforms which can be registered or selected.",
    attrs = {
        "user_repository_name": attr.string(doc = "what the user chose for the base name"),
    },
)
