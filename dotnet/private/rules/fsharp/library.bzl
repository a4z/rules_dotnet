"F# library rules"

load("@io_bazel_rules_dotnet//dotnet/private:context.bzl", "dotnet_context")
load(
    "//dotnet/private:providers.bzl",
    "DotnetLibraryInfo",
    "DotnetResourceListInfo",
)
load("@io_bazel_rules_dotnet//dotnet/platform:list.bzl", "DOTNET_CORE_FRAMEWORKS", "DOTNET_NETSTANDARD")
load("@io_bazel_rules_dotnet//dotnet/private:rules/versions.bzl", "parse_version")

def _library_impl(ctx):
    """_library_impl emits actions for compiling dotnet executable assembly."""
    if not ctx.label.name.endswith(".exe") and not ctx.label.name.endswith(".dll"):
        fail("All fsharp_library targets must have their extension declared in their name (.dll or .exe)")

    dotnet = dotnet_context(ctx, "fsharp")
    name = ctx.label.name

    library = dotnet.toolchain.actions.assembly(
        dotnet,
        name = name,
        srcs = ctx.attr.srcs,
        design_time_resources = ctx.attr.design_time_resources,
        deps = ctx.attr.deps,
        resources = ctx.attr.resources,
        out = ctx.attr.out,
        defines = ctx.attr.defines,
        data = ctx.attr.data,
        keyfile = ctx.attr.keyfile,
        executable = False,
        target_framework = ctx.attr.target_framework,
        nowarn = ctx.attr.nowarn,
        langversion = ctx.attr.langversion,
        version = (0, 0, 0, 0, "") if ctx.attr.version == "" else parse_version(ctx.attr.version),
    )

    return [
        library,
        DefaultInfo(
            files = depset([library.result]),
            runfiles = ctx.runfiles(files = [], transitive_files = depset(transitive = [t.runfiles for t in library.transitive])),
        ),
    ]

fsharp_library = rule(
    _library_impl,
    attrs = {
        "deps": attr.label_list(providers = [DotnetLibraryInfo], doc = "The direct dependencies of this library. These may be dotnet_library rules or compatible rules with the [DotnetLibraryInfo](api.md#dotnetlibraryinfo) provider."),
        "version": attr.string(doc = "Version to be set for the assembly. The version is set by compiling in [AssemblyVersion](https://docs.microsoft.com/en-us/troubleshoot/visualstudio/general/assembly-version-assembly-file-version) attribute."),
        "resources": attr.label_list(providers = [DotnetResourceListInfo], doc = "The list of resources to compile with. Usually provided via reference to [core_resx](api.md#core_resx) or the rules compatible with [DotnetResourceInfo](api.md#dotnetresourceinfo) provider."),
        "srcs": attr.label_list(allow_files = [".fs"], doc = "The list of .fs source files that are compiled to create the assembly."),
        "design_time_resources": attr.label_list(allow_files = True, doc = "Resources that are made available at design time. Primarily used by Type Providers."),
        "out": attr.string(doc = "An alternative name of the output file."),
        "defines": attr.string_list(doc = "The list of defines passed via /define compiler option."),
        "data": attr.label_list(allow_files = True, doc = "The list of additional files to include in the list of runfiles for the assembly."),
        "keyfile": attr.label(allow_files = True, doc = "The key to sign the assembly with."),
        "target_framework": attr.string(values = DOTNET_CORE_FRAMEWORKS.keys() + DOTNET_NETSTANDARD.keys() + [""], default = "", doc = "Target framework."),
        "nowarn": attr.string_list(doc = "The list of warnings to be ignored. The warnings are passed to -nowarn compiler opion."),
        "langversion": attr.string(default = "latest", doc = "Version of the language to use."),
    },
    toolchains = ["@io_bazel_rules_dotnet//dotnet:toolchain_type_fsharp_core"],
    executable = False,
    doc = """This builds a dotnet assembly from a set of source files.

    Providers
    ^^^^^^^^^

    * [DotnetLibraryInfo](api.md#dotnetlibraryinfo)
    * [DotnetResourceInfo](api.md#dotnetresourceinfo)

    Example:
    ^^^^^^^^
    ```python
    [fsharp_library(
        name = "{}_TransitiveClass-core.dll".format(framework),
        srcs = [
            "TransitiveClass.fs",
        ],
        visibility = ["//visibility:public"],
        deps = [
            "@io_bazel_rules_dotnet//dotnet/stdlib.core/{}:libraryset".format(framework),
        ],
    ) for framework in DOTNET_CORE_FRAMEWORKS]
    ```
    """,
)
