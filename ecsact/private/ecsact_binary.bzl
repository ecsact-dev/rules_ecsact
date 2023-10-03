load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")

def _ecsact_binary(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    ecsact_toolchain = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info

    # TODO(zaucy): derive runtime library extension based on ctx and cc_toolchain
    runtime_output_file = ctx.actions.declare_file("{}.dll".format(ctx.attr.name))
    outputs = [runtime_output_file]
    tools = [] + ecsact_toolchain.tool_files

    args = ctx.actions.args()
    args.add("build")
    args.add_all(ctx.files.srcs)
    args.add_all(ctx.files.recipes, before_each = "-r")
    args.add("-o", runtime_output_file)

    for p in ecsact_toolchain.target_tool_path_runfiles:
        tools.extend(p.files.to_list())

    if len(ctx.files.recipes) > 1:
        fail("Only 1 recipe is allowed at this time")

    ctx.actions.run(
        mnemonic = "EcsactBuild",
        outputs = outputs,
        inputs = ctx.files.srcs + ctx.files.recipes,
        executable = ecsact_toolchain.target_tool_path + ".exe",
        tools = tools,
        arguments = [args],
    )

    return [
        DefaultInfo(
            files = depset(outputs),
        ),
    ]

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
