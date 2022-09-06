"""
"""

def _ecsact_codegen(ctx):
    info = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info

    outputs = []
    outdir = ctx.actions.declare_directory(ctx.attr.name)

    args = ctx.actions.args()
    args.add("codegen")
    args.add_all(ctx.files.srcs)
    args.add("--plugin", "cpp_header")
    args.add("--outdir", outdir.path)

    outputs.append(outdir)
    for src in ctx.files.srcs:
        out_basename = ctx.attr.name + "/" + src.basename
        outputs.append(ctx.actions.declare_file(out_basename + ".hh"))

    ctx.actions.run(
        mnemonic = "EcsactCodegen",
        outputs = outputs,
        inputs = ctx.files.srcs,
        executable = info.target_tool_path,
        arguments = [args],
    )

    return [
        DefaultInfo(
            files = depset(outputs),
        ),
    ]

ecsact_codegen = rule(
    implementation = _ecsact_codegen,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "plugins": attr.label_list(),
    },
    toolchains = ["//ecsact:toolchain_type"],
)
