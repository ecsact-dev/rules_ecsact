oad("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _ecsact_binary(ctx):
    cc_toolchain = find_cc_toolchain(ctx)

ecsact_binary = rule(
    implementation = _ecsact_binary,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".ecsact"],
        ),
        "recipes": attr.label_list(
            allow_empty = False,
            mandatory = True,
            allow_files = True,
        ),
        "_cc_toolchain": attr.label(
            default = Label(
                "@rules_cc//cc:current_cc_toolchain",
            ),
        ),
    },
    toolchains = ["//ecsact:toolchain_type"] + use_cc_toolchain(),
)
