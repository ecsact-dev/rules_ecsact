load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")

def _ecsact_binary(ctx):
    cc_toolchain = find_cc_toolchain(ctx)

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

    # TODO(zaucy): derive runtime library extension based on ctx and cc_toolchain
    runtime_output_file = ctx.actions.declare_file("{}.dll".format(ctx.attr.name))
    outputs = [runtime_output_file]
    tools = [] + ecsact_toolchain.tool_files

    args = ctx.actions.args()
    args.add("build")
    args.add_all(ctx.files.srcs)
    args.add_all(ctx.files.recipes, before_each = "-r")
    args.add("-o", runtime_output_file)
    args.add("--temp_dir", ctx.attr.name)
    args.add("-f", "none")

    # TODO(zaucy): detect shared library extension
    preferred_output_extension = ".dll"

    compiler_config = {
        "compiler_type": "auto",
        "compiler_path": cc_toolchain.compiler_executable,
        "compiler_version": "bazel c++ toolchain",
        "install_path": "",
        "std_inc_paths": cc_toolchain.built_in_include_directories,
        "std_lib_paths": [],
        "preferred_output_extension": preferred_output_extension,
        "allowed_output_extensions": [preferred_output_extension],
    }

    compiler_config_file = ctx.actions.declare_file("{}.compiler_config.json".format(ctx.attr.name))

    ctx.actions.write(compiler_config_file, json.encode(compiler_config))

    args.add("--compiler_config", compiler_config_file)

    for p in ecsact_toolchain.target_tool_path_runfiles:
        tools.extend(p.files.to_list())

    if len(ctx.files.recipes) > 1:
        fail("Only 1 recipe is allowed at this time")

    ctx.actions.run(
        mnemonic = "EcsactBuild",
        outputs = outputs,
        inputs = ctx.files.srcs + ctx.files.recipes + [compiler_config_file],
        executable = ecsact_toolchain.target_tool_path,
        tools = tools,
        arguments = [args],
        env = env,
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
    fragments = ["cpp"],
)
