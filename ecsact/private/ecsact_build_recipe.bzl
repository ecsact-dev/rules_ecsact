load("//ecsact/private:ecsact_codegen_plugin.bzl", "EcsactCodegenPluginInfo")

EcsactBuildRecipeInfo = provider(
    doc = "",
    fields = {
        "recipe_path": "path to recipe yaml file",
        "data": "files needed to build recipe",
    },
)

def _ecsact_build_recipe(ctx):
    # type: (ctx) -> None

    recipe_yaml = ctx.actions.declare_file("{}.yml".format(ctx.attr.name))

    sources = []
    recipe_data = []

    for src in ctx.files.srcs:
        sources.append({
            "path": src.path,
            "outdir": src.dirname,
            "relative_to_cwd": True,
        })
        recipe_data.append(src)

    for codegen_plugin in ctx.attr.codegen_plugins:
        info = codegen_plugin[EcsactCodegenPluginInfo]
        sources.append({
            "codegen": info.plugin.path,
            "outdir": ctx.attr.codegen_plugins[codegen_plugin],
        })
        recipe_data.append(info.plugin)

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

def _ecsact_build_recipe_bundle(ctx):
    # type: (ctx) -> None

    ecsact_toolchain = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info
    bundle_output_file = ctx.actions.declare_file("{}.ecsact-recipe-bundle".format(ctx.attr.name))

    args = ctx.actions.args()
    args.add("recipe-bundle")
    args.add("-o", bundle_output_file)

    report_filter = ctx.var.get("ECSACT_CLI_REPORT_FILTER", "errors_and_warnings")
    args.add("--report_filter", report_filter)

    executable = ecsact_toolchain.target_tool if ecsact_toolchain.target_tool != None else ecsact_toolchain.target_tool_path

    ctx.actions.run(
        mnemonic = "EcsactRecipeBundle",
        progress_message = "Bundling Ecsact Build Recipe %{output}",
        outputs = outputs + [temp_dir],
        inputs = inputs,
        executable = executable,
        tools = tools,
        arguments = [args],
        env = env,
        toolchain = Label("//ecsact:toolchain_type"),
    )
    pass

ecsact_build_recipe_bundle = rule(
    implementation = _ecsact_build_recipe_bundle,
    attrs = {
        "recipes": attr.label_list(
            providers = [EcsactBuildRecipeInfo],
        ),
    },
)
