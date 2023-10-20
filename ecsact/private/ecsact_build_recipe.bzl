load("//ecsact/private:ecsact_codegen_plugin.bzl", "EcsactCodegenPluginInfo")

EcsactBuildRecipeInfo = provider(
    doc = "",
    fields = {
        "recipe_path": "path to recipe yaml file",
        "data": "files needed to build recipe",
    },
)

def _ecsact_build_recipe(ctx):
    recipe_yaml = ctx.actions.declare_file("{}.yml".format(ctx.attr.name))

    sources = []
    recipe_data = []

    for src in ctx.files.srcs:
        sources.append({
            "path": src.path,
            "outdir": "src",
            "relative_to_cwd": True,
        })
        recipe_data.append(src)

    for codegen_plugin in ctx.attr.codegen_plugins:
        info = codegen_plugin[EcsactCodegenPluginInfo]
        sources.append({
            "codegen": [info.plugin.path],
            "outdir": ctx.attr.codegen_plugins[codegen_plugin],
        })

    recipe = {
        "name": ctx.attr.name,
        "sources": sources,
        "imports": ctx.attr.imports,
        "exports": ctx.attr.exports,
    }

    ctx.actions.write(recipe_yaml, json.encode(recipe))

    return [
        DefaultInfo(
            files = depset([recipe_yaml]),
        ),
        EcsactBuildRecipeInfo(
            recipe_path = recipe_yaml,
            data = recipe_data,
        ),
    ]

ecsact_build_recipe = rule(
    implementation = _ecsact_build_recipe,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
        ),
        "codegen_plugins": attr.label_keyed_string_dict(
            providers = [EcsactCodegenPluginInfo],
        ),
        "imports": attr.string_list(
        ),
        "exports": attr.string_list(
            mandatory = True,
        ),
    },
)
