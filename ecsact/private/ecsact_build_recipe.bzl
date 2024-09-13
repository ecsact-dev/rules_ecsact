load("@rules_cc//cc:find_cc_toolchain.bzl", "use_cc_toolchain")
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

    for cc_dep in ctx.attr.cc_deps:
        cc_info = cc_dep[CcInfo]

        for hdr in cc_info.compilation_context.headers.to_list():
            hdr_prefix = ""

            for quote_inc in cc_info.compilation_context.quote_includes.to_list():
                if hdr.path.startswith(quote_inc):
                    hdr_prefix = quote_inc
                    break
            for sys_inc in cc_info.compilation_context.system_includes.to_list():
                if hdr.path.startswith(sys_inc):
                    hdr_prefix = sys_inc
                    break

            if hdr_prefix:
                hdr_prefix_base = hdr.path.removeprefix(hdr_prefix)
                hdr_prefix_base_idx = hdr_prefix_base.rindex("/")
                hdr_prefix_base = hdr_prefix_base[:hdr_prefix_base_idx]
                sources.append({
                    "path": hdr.path,
                    "outdir": "include" + hdr_prefix_base,
                    "relative_to_cwd": True,
                })
                recipe_data.append(hdr)

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
        "cc_deps": attr.label_list(
            providers = [CcInfo],
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

def _ecsact_build_recipe_bundle(ctx):
    # type: (ctx) -> None

    ecsact_toolchain = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info
    bundle_output_file = ctx.actions.declare_file("{}.ecsact-recipe-bundle".format(ctx.attr.name))

    args = ctx.actions.args()
    args.add("recipe-bundle")
    args.add_all(ctx.files.recipes)
    args.add("-o", bundle_output_file)

    report_filter = ctx.var.get("ECSACT_CLI_REPORT_FILTER", "errors_and_warnings")
    args.add("--report_filter", report_filter)

    executable = ecsact_toolchain.target_tool if ecsact_toolchain.target_tool != None else ecsact_toolchain.target_tool_path

    recipes_data = []
    for recipe in ctx.attr.recipes:
        recipes_data.extend(recipe[EcsactBuildRecipeInfo].data)

    ctx.actions.run(
        mnemonic = "EcsactRecipeBundle",
        progress_message = "Bundling Ecsact Build Recipe %{output}",
        outputs = [bundle_output_file],
        inputs = ctx.files.recipes + recipes_data,
        executable = executable,
        arguments = [args],
        toolchain = Label("//ecsact:toolchain_type"),
        # need curl in PATH due to https://github.com/ecsact-dev/ecsact_cli/issues/115
        use_default_shell_env = True,
    )
    return [
        DefaultInfo(
            files = depset([bundle_output_file]),
        ),
        EcsactBuildRecipeInfo(
            recipe_path = bundle_output_file,
            data = [],
        ),
    ]

ecsact_build_recipe_bundle = rule(
    implementation = _ecsact_build_recipe_bundle,
    attrs = {
        "recipes": attr.label_list(
            providers = [EcsactBuildRecipeInfo],
        ),
    },
    toolchains = ["//ecsact:toolchain_type"] + use_cc_toolchain(),
)
