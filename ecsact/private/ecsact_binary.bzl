load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("//ecsact/private:ecsact_build_recipe.bzl", "EcsactBuildRecipeInfo")

def _ecsact_binary_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)

    temp_dir = ctx.actions.declare_directory("{}.ecsact_binary".format(ctx.attr.name))

    inputs = []

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
    )

    variables = cc_common.create_link_variables(
        cc_toolchain = cc_toolchain,
        feature_configuration = feature_configuration,
    )

    env = cc_common.get_environment_variables(
        feature_configuration = feature_configuration,
        action_name = ACTION_NAMES.cpp_link_dynamic_library,
        variables = variables,
    )

    ecsact_toolchain = ctx.toolchains["//ecsact:toolchain_type"].ecsact_info

    preferred_output_extension = ctx.attr.lib_extension

    runtime_output_file = ctx.actions.declare_file("{}{}".format(ctx.attr.name, preferred_output_extension))
    outputs = [runtime_output_file]
    tools = [] + ecsact_toolchain.tool_files

    args = ctx.actions.args()
    args.add("build")
    args.add_all(ctx.files.srcs)
    args.add_all(ctx.files.recipes, before_each = "-r")
    args.add("-o", runtime_output_file)
    args.add("--temp_dir", temp_dir.path)
    args.add("-f", "text")

    report_filter = ctx.var.get("ECSACT_CLI_REPORT_FILTER", "errors_and_warnings")
    args.add("--report_filter", report_filter)

    compiler_config = {
        "compiler_type": "auto",
        "compiler_path": cc_toolchain.compiler_executable,
        "compiler_version": "bazel c++ toolchain",
        "install_path": "",
        "sysroot": cc_toolchain.sysroot,
        "std_inc_paths": cc_toolchain.built_in_include_directories,
        "std_lib_paths": [],
        "preferred_output_extension": preferred_output_extension,
        "allowed_output_extensions": [preferred_output_extension],
    }

    tools.append(cc_toolchain.all_files)

    compiler_config_file = ctx.actions.declare_file("{}.compiler_config.json".format(ctx.attr.name))

    ctx.actions.write(compiler_config_file, json.encode(compiler_config))

    args.add("--compiler_config", compiler_config_file)

    if len(ctx.files.recipes) > 1:
        fail("Only 1 recipe is allowed at this time")

    inputs.extend(ctx.files.srcs)
    inputs.extend(ctx.files.recipes)
    inputs.append(compiler_config_file)

    for recipe in ctx.attr.recipes:
        recipe_info = recipe[EcsactBuildRecipeInfo]
        inputs.extend(recipe_info.data)

    executable = ecsact_toolchain.target_tool if ecsact_toolchain.target_tool != None else ecsact_toolchain.target_tool_path

    ctx.actions.run(
        mnemonic = "EcsactBuild",
        progress_message = "Building Ecsact Runtime %{output}",
        outputs = outputs + [temp_dir],
        inputs = inputs,
        executable = executable,
        tools = tools,
        arguments = [args],
        env = env,
        toolchain = Label("//ecsact:toolchain_type"),
    )

    return [
        DefaultInfo(
            files = depset(outputs),
        ),
    ]

_ecsact_binary = rule(
    implementation = _ecsact_binary_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".ecsact"],
        ),
        "recipes": attr.label_list(
            allow_empty = False,
            mandatory = True,
            providers = [EcsactBuildRecipeInfo],
        ),
        "_cc_toolchain": attr.label(
            default = Label(
                "@rules_cc//cc:current_cc_toolchain",
            ),
        ),
        "lib_extension": attr.string(
            mandatory = True,
        ),
    },
    toolchains = ["//ecsact:toolchain_type"] + use_cc_toolchain(),
    fragments = ["cpp"],
)

def ecsact_binary(**kwargs):
    _ecsact_binary(
        lib_extension = select({
            "@platforms//os:windows": ".dll",
            "@platforms//os:linux": ".so",
            "@platforms//os:macos": ".dylib",
            "@platforms//os:wasi": ".wasm",
            "@platforms//os:none": ".wasm",  # for non-wasi
        }),
        **kwargs
    )
