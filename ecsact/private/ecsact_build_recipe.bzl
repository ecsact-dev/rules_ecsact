load("//ecsact/private:ecsact_codegen_plugin.bzl", "EcsactCodegenPluginInfo")

EcsactBuildRecipeInfo = provider(
    doc = "",
    fields = {
        "recipe_path": "path to recipe yaml file",
        "data": "files needed to build recipe",
    },
)

CPP_HEADER_SUFFIXES = [
    ".hh",
    ".h",
    ".hpp",
    ".inl",
]

def _strip_external(p):
    # type: (string) -> string
    EXTERNAL_PREFIX = "external/"
    if p.startswith(EXTERNAL_PREFIX):
        return p[p.index("/", len(EXTERNAL_PREFIX)) + 1:]
    return p

def _source_outdir(src):
    # type: (File) -> string
    src_path = src.path
    for cpp_header_suffix in CPP_HEADER_SUFFIXES:
        if src.path.endswith(cpp_header_suffix):
            return "include/" + _strip_external(src.dirname)
    return _strip_external(src.dirname)

def _ecsact_build_recipe(ctx):
    # type: (ctx) -> None

    recipe_yaml = ctx.actions.declare_file("{}.yml".format(ctx.attr.name))

    sources = []
    recipe_data = []

    for src in ctx.files.srcs:
        sources.append({
            "path": src.path,
            "outdir": _source_outdir(src),
            "relative_to_cwd": True,
        })
        recipe_data.append(src)

    for fetch_src_outdir in ctx.attr.fetch_srcs:
        fetch_srcs = []
        for fetch_url in ctx.attr.fetch_srcs[fetch_src_outdir]:
            fetch_srcs.append({
                "fetch": fetch_url,
                "outdir": fetch_src_outdir,
            })
        sources.extend(fetch_srcs)

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
        "fetch_srcs": attr.string_list_dict(
            allow_empty = True,
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
