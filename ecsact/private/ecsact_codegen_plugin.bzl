"""
"""

EcsactCodegenPluginInfo = provider(
    doc = "",
    fields = {
        "output_extension": "Plugin name. Also used as output file extension. This must match the extension specified by the plugin.",
        "plugin": "Path to plugin or name of builtin plugin",
    },
)

def _ecsact_codegen_plugin(ctx):
    return [
        EcsactCodegenPluginInfo(
            output_extension = ctx.attr.output_extension,
            plugin = ctx.attr.plugin,
        ),
    ]

ecsact_codegen_plugin = rule(
    implementation = _ecsact_codegen_plugin,
    attrs = {
        "output_extension": attr.string(mandatory = True),
        "plugin": attr.string(mandatory = True),
    },
)
