EcsactCodegenPluginInfo = provider(
    doc = "",
    fields = {
        "output_extension": "Plugin name. Also used as default output extension.",
        "plugin": "Path to plugin"
    }
)

def _ecsact_codegen_plugin(ctx)
    return [
        EcsactCodegenPluginInfo(
            output_extension = ctx.attr.output_extension,
            plugin = ctx.attr.plugin,
        )
    ]

ecsact_codegen_plugin = rule(
    implementation = _ecsact_codegen_plugin,
    attrs = {
        "output_extension": attr.string(),
        "plugin": attr.label(allow_single_file = True),
    },
)
