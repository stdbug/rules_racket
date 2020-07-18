"""Rules to run and test Racket"""

RacketFilesInfo = provider(fields = ["racket_sources"])

def get_transitive_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[RacketFilesInfo].racket_sources for dep in deps],
    )

def _racket_library_impl(ctx):
    srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    return [RacketFilesInfo(racket_sources = srcs)]

racket_library = rule(
    implementation = _racket_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    },
)

def copy_file(ctx, src, dst):
    if ctx.attr.is_windows:
        ctx.actions.run(
            outputs = [dst],
            inputs = depset([src]),
            arguments = ["/c", 'copy {0} {1}'.format(src.path, dst.path).replace('/', '\\')],
            executable = "cmd.exe",
        )
    else:
        ctx.actions.run_shell(
            outputs = [dst],
            inputs = depset([src]),
            command = "cp {0} {1}".format(src.path, dst.path),
        )

def _racket_binary_outputs(ctx):
    if len(ctx.attr.srcs) != 1:
        fail("There may be only one file in srcs")

    dep_srcs = get_transitive_srcs([], ctx.attr.deps).to_list()
    all_outputs = []
    for src in dep_srcs:
        out_filename = "{0}/{1}".format(src.dirname, src.basename)
        out = ctx.actions.declare_file(out_filename)
        copy_file(ctx, src, out)
        all_outputs.append(out)

    src = ctx.attr.srcs[0].files.to_list()[0]
    out = ctx.actions.declare_file(src.basename)
    copy_file(ctx, src, out)
    all_outputs.append(out)

    return all_outputs, src

def _racket_binary_executable(ctx, src):
    executable = None
    content = None
    if ctx.attr.is_windows:
        executable = ctx.actions.declare_file(ctx.label.name + ".bat")
        content = ""
        content += "@echo off\n"
        content += "cd %~dp0\n"
        content += 'set PLTCOLLECTS=";%~dp0"\n'
        content += "racket " + src.basename + "\n"
        content += "if %errorlevel% neq 0 exit /b %errorlevel%\n"
    else:
        executable = ctx.actions.declare_file(ctx.label.name + ".sh")
        content = ""
        content += "#!/usr/bin/env bash\n"
        content += "set -eu -o pipefail\n"
        content += "\n"
        content += 'MY_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )\n'
        content += "cd $MY_DIR\n"
        content += 'export PLTCOLLECTS=":$MY_DIR"\n'
        content += "racket " + src.basename + "\n"

    ctx.actions.write(
        output = executable,
        is_executable = True,
        content = content,
    )

    return executable

def _racket_binary_impl(ctx):
    all_outputs, src = _racket_binary_outputs(ctx)

    runfiles = ctx.runfiles(files = all_outputs)

    executable = _racket_binary_executable(ctx, src)
    all_outputs.append(executable)

    return [DefaultInfo(files = depset(all_outputs), executable = executable, runfiles = runfiles)]

_racket_binary = rule(
    implementation = _racket_binary_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "is_windows": attr.bool(mandatory = True),
    },
    executable = True,
)

def racket_binary(name, srcs, deps, **kwargs):
    _racket_binary(
        name = name,
        srcs = srcs,
        deps = deps,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )

def _racket_test_executable(ctx, src):
    executable = None
    content = None
    if ctx.attr.is_windows:
        executable = ctx.actions.declare_file(ctx.label.name + ".bat")
        content = ""
        content += "@echo off\n"
        content += "cd %~dp0\n"
        content += 'set PLTCOLLECTS=";%~dp0"\n'
        content += "raco test " + src.basename + "\n"
        content += "if %errorlevel% neq 0 exit /b %errorlevel%\n"
    else:
        executable = ctx.actions.declare_file(ctx.label.name + ".sh")
        content = ""
        content += "#!/usr/bin/env bash\n"
        content += "set -eu -o pipefail\n"
        content += "\n"
        content += 'MY_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )\n'
        content += "cd $MY_DIR\n"
        content += 'export PLTCOLLECTS=":$MY_DIR"\n'
        content += "raco test " + src.basename + "\n"

    ctx.actions.write(
        output = executable,
        is_executable = True,
        content = content,
    )

    return executable

def _racket_test_impl(ctx):
    all_outputs, src = _racket_binary_outputs(ctx)

    runfiles = ctx.runfiles(files = all_outputs)

    executable = _racket_test_executable(ctx, src)
    all_outputs.append(executable)

    return [DefaultInfo(files = depset(all_outputs), executable = executable, runfiles = runfiles)]

_racket_test = rule(
    implementation = _racket_test_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "is_windows": attr.bool(mandatory = True),
    },
    test = True,
)

def racket_test(name, srcs, deps, **kwargs):
    _racket_test(
        name = name,
        srcs = srcs,
        deps = deps,
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        **kwargs
    )
