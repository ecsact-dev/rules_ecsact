"""
"""

load("@ecsact_runtime//:codegen_plugin.bzl", "EcsactCodegenPluginInfo")

def _ecsact_codegen(ctx):
    info = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info

    outputs = []
    tools = [] + info.tool_files
    outdir = ctx.actions.declare_directory(ctx.attr.name)

    args = ctx.actions.args()
    args.add("codegen")
    args.add_all(ctx.files.srcs)
    args.add("--outdir", outdir.path)

    plugin_data = []

    for plugin in ctx.attr.plugins:
        plugin_info = plugin[EcsactCodegenPluginInfo]
        args.add("--plugin", plugin_info.plugin)
        plugin_data.extend(plugin_info.data)
        for src in ctx.files.srcs:
            out_basename = ctx.attr.name + "/" + src.basename
            outputs.append(ctx.actions.declare_file(out_basename + "." + plugin_info.output_extension))

    for p in info.target_tool_path_runfiles:
        tools.extend(p.files.to_list())

    ctx.actions.run(
        mnemonic = "EcsactCodegen",
        outputs = [outdir] + outputs,
        inputs = ctx.files.srcs + plugin_data,
        executable = info.target_tool_path,
        tools = tools,
        arguments = [args],
    )

    return [
        DefaultInfo(
            files = depset(outputs),
        ),
    ]

ecsact_codegen = rule(
    implementation = _ecsact_codegen,
    doc = "Ecsact codegen rule. Executes `ecsact codegen` with specified plugins.",
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = ".ecsact source files",
        ),
        "plugins": attr.label_list(
            providers = [EcsactCodegenPluginInfo],
            mandatory = True,
            cfg = "exec",
            doc = "List of plugin to use for code generation. Default ones are available at `@ecsact//codegen_plugins:*`",
        ),
    },
    toolchains = ["//ecsact:toolchain_type"],
)
