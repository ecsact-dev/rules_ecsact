load("//ecsact/private:toolchains_repo.bzl", "ecsact_register_toolchains")

_ECSACT_TOOLCHAINS_BUILD_FILE_CONTENTS = """
package(default_visibility = ["//visibility:public"])

ecsact_toolchain(
    name = "ecsact_cli_toolchain",
    target_tool = "@ecsact_cli",
)
"""

def _ecsact_repository_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        executable = False,
        content = _ECSACT_TOOLCHAINS_BUILD_FILE_CONTENTS,
    )

_ecsact_repository = repository_ctx(
    implementation = _ecsact_repository_impl,
    attrs = {
    },
)

def _ecsact_impl(mctx):
    _ecsact_repository(name = "ecsact_toolchains")

escact = module_extension(
    implementation = _ecsact_impl,
    tag_classes = {
        # "toolchain": tag_class(attrs = {
        #     "name": attr.string(doc = "", default = "ecsact"),
        #     "version": attr.string(doc = "Explicit version of escact.", mandatory = True),
        # }),
    },
)
