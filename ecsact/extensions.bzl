load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_EXPORTS_ALL_BUILD_FILE_CONTENTS = """
package(default_visibility = ["//visibility:public"])
exports_files(glob["**/*"])
"""

_ECSACT_TOOLCHAINS_BUILD_FILE_CONTENTS = """
load("@rules_ecsact//ecsact:toolchain.bzl", "ecsact_toolchain")

package(default_visibility = ["//visibility:public"])

ecsact_toolchain(
    name = "ecsact_sdk_system",
    target_tool_path = "{ecsact_exe_path}",
)

toolchain(
    name = "ecsact_sdk_system_toolchain",
    toolchain = ":ecsact_sdk_system",
    toolchain_type = "@rules_ecsact//ecsact:toolchain_type",
)
"""

_ECSACT_SDK_BUILD_FILE_CONTENTS = """
load("@rules_ecsact//ecsact:defs.bzl", "ecsact_codegen_plugin")

package(default_visibility = ["//visibility:public"])

ecsact_codegen_plugin(
    name = "cpp_header", 
    output_extension = "hh",
    plugin_path = "cpp_header",
)
"""

def _ecsact_sdk_repository_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        executable = False,
        content = "",
    )

    rctx.file(
        "codegen_plugins/BUILD.bazel",
        executable = False,
        content = _ECSACT_SDK_BUILD_FILE_CONTENTS,
    )

_ecsact_sdk_repository = repository_rule(
    implementation = _ecsact_sdk_repository_impl,
    attrs = {
    },
)

def _ecsact_toolchains_repository_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        executable = False,
        content = _ECSACT_TOOLCHAINS_BUILD_FILE_CONTENTS.format(
            ecsact_exe_path = rctx.attr.ecsact_exe.replace("\\", "/"),
        ),
    )

_ecsact_toolchains_repository = repository_rule(
    implementation = _ecsact_toolchains_repository_impl,
    attrs = {
        "ecsact_exe": attr.string(mandatory = True),
    },
)

def _windows_find_ecsact_from_app_installer(ctx):
    # ctx.which doesn't work for everything available on Windows. Using cmd's
    # built-in 'where' command can find programs installed from the Microsoft
    # store or MSIX packages.
    cmd = ctx.which("cmd.exe")
    if cmd:
        where_result = ctx.execute([cmd, "/C", "where ecsact.exe"])
        if where_result.stdout:
            return ctx.path(where_result.stdout.strip())

    return None

def _ecsact_impl(mctx):
    wanted_ecsact_version = None

    for mod in mctx.modules:
        for sdk_toolchain in mod.tags.sdk_toolchain:
            if wanted_ecsact_version != None:
                fail("ecsact extension sdk_toolchain called multiple times. Please only call it once.")
            wanted_ecsact_version = sdk_toolchain.version

    ecsact_exe = mctx.which("ecsact")

    if ecsact_exe == None and mctx.os.name.startswith("windows"):
        ecsact_exe = _windows_find_ecsact_from_app_installer(mctx)

    if ecsact_exe == None:
        fail("Cannot find the Ecsact SDK installed on your system. See https://ecsact.dev/start for instructions.")

    ecsact_version_output = mctx.execute([ecsact_exe, "--version"])
    if ecsact_version_output.return_code != 0:
        fail(
            "Failed to get Ecsact SDK version (exit code {}). " +
            "Please make sure it's installed correctly.\n" +
            "\tEcsact Executable = {}\n".format(ecsact_exe) +
            "\tExit Code = {}\n".format(ecsact_version_output.return_code),
        )

    found_ecsact_version = ecsact_version_output.stdout.strip()
    if wanted_ecsact_version != None:
        # workaround for https://github.com/ecsact-dev/ecsact_sdk/issues/293
        if found_ecsact_version != wanted_ecsact_version and found_ecsact_version != "refs/tags/{}".format(wanted_ecsact_version):
            fail("Wanted Ecsact SDK {}, but {} is installed on your system".format(wanted_ecsact_version, found_ecsact_version))

    _ecsact_sdk_repository(
        name = "ecsact_sdk",
    )
    _ecsact_toolchains_repository(
        name = "ecsact_toolchains",
        ecsact_exe = str(ecsact_exe),
    )

ecsact = module_extension(
    implementation = _ecsact_impl,
    tag_classes = {
        "sdk_toolchain": tag_class(attrs = {
            "version": attr.string(mandatory = True),
        }),
    },
)
