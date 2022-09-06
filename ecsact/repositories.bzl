"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", _http_archive = "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//ecsact/private:toolchains_repo.bzl", "PLATFORMS", "toolchains_repo")
load("//ecsact/private:versions.bzl", "LATEST_TOOL_VERSION", "TOOL_VERSIONS")

def http_archive(name, **kwargs):
    maybe(_http_archive, name = name, **kwargs)

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.LATEST_TOOL_VERSION
# This is all fixed by bzlmod, so we just tolerate it for now.
def rules_ecsact_dependencies():
    # The minimal version of bazel_skylib we require
    http_archive(
        name = "bazel_skylib",
        sha256 = "f7be3474d42aae265405a592bb7da8e171919d74c16f082a5457840f06054728",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.2.1/bazel-skylib-1.2.1.tar.gz",
        ],
    )

########
# Remaining content of the file is only used to support toolchains.
########
_DOC = "Fetch external tools needed for ecsact toolchain"

_BUILD_CONTENT = """#Generated by ecsact/repositories.bzl
load("@rules_ecsact//ecsact:toolchain.bzl", "ecsact_toolchain")

ecsact_toolchain(
    name = "ecsact_toolchain",
    target_tool = select({
        "@bazel_tools//src/conditions:host_windows": "bin/ecsact.exe",
        "//conditions:default": "bin/ecsact",
    }),
)
"""

def _download_repo(rctx, platform):
    archive_extname = "tar.gz"
    if platform.find("windows") != -1:
        archive_extname = "zip"

    url = "https://github.com/ecsact-dev/ecsact_sdk/releases/download/{0}/ecsact_sdk_{0}_{1}.{2}".format(
        rctx.attr.ecsact_version,
        platform,
        archive_extname,
    )
    rctx.download_and_extract(
        url = url,
        integrity = TOOL_VERSIONS[rctx.attr.ecsact_version][platform],
    )

    # Base BUILD file for this repository
    rctx.file("BUILD.bazel", _BUILD_CONTENT)

def _ecsact_repo_impl(rctx):
    _download_repo(rctx, rctx.attr.platform)

def _host_platform(rctx):
    if rctx.os.name.find("windows") != -1:
        return "windows_x64"
    if rctx.os.name == "linux" and rctx.os.arch == "amd64":
        return "linux_x64"

    fail("Unsupported host platform %s %s" % (rctx.os.name, rctx.os.arch))

def _ecsact_host_repo_impl(rctx):
    _download_repo(rctx, _host_platform(rctx))

ecsact_repository = repository_rule(
    _ecsact_repo_impl,
    doc = _DOC,
    attrs = {
        "ecsact_version": attr.string(mandatory = True, values = TOOL_VERSIONS.keys()),
        "platform": attr.string(mandatory = True, values = PLATFORMS.keys()),
    },
)

ecsact_host_repository = repository_rule(
    _ecsact_host_repo_impl,
    doc = _DOC,
    attrs = {
        "ecsact_version": attr.string(mandatory = True, values = TOOL_VERSIONS.keys()),
    },
)

# Wrapper macro around everything above, this is the primary API
def ecsact_register_toolchains(name = "ecsact", ecsact_version = LATEST_TOOL_VERSION, **kwargs):
    """Convenience macro for users which does typical setup.

    - create a repository for each built-in platform like "ecsact_windows_x64" -
      this repository is lazily fetched when ecsact is needed for that platform.
    - create a repository exposing toolchains for each platform like "ecsact_platforms"
    - register a toolchain pointing at each platform
    Users can avoid this macro and do these steps themselves, if they want more control.
    Args:
        name: name for host repository and base name for all created repos platform
        ecsact_version: specific ecsact version. Defaults to latest.
        **kwargs: passed to each ecsact_repository call
    """
    ecsact_host_repository(
        name = name,
        ecsact_version = ecsact_version,
        **kwargs
    )

    for platform in PLATFORMS.keys():
        ecsact_repository(
            name = name + "_" + platform,
            platform = platform,
            ecsact_version = ecsact_version,
            **kwargs
        )
        native.register_toolchains("@%s_toolchains//:%s_toolchain" % (name, platform))

    toolchains_repo(
        name = name + "_toolchains",
        user_repository_name = name,
    )
