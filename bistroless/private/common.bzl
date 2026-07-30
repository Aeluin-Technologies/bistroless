def run_checked(
        ctx,
        arguments,
        timeout = 600,
        environment = None):
    if environment == None:
        result = ctx.execute(
            arguments,
            quiet = True,
            timeout = timeout,
        )
    else:
        result = ctx.execute(
            arguments,
            environment = environment,
            quiet = True,
            timeout = timeout,
        )

    if result.return_code != 0:
        fail(
            "Command failed:\n%s\n\nstdout:\n%s\n\nstderr:\n%s" % (
                " ".join([str(argument) for argument in arguments]),
                result.stdout,
                result.stderr,
            ),
        )

    return result

def write_layer_build(ctx):
    ctx.file(
        "BUILD.bazel",
        "\n".join([
            "filegroup(",
            "    name = \"layer\",",
            "    srcs = [\"layer.tar\"],",
            "    visibility = [\"//visibility:public\"],",
            ")",
            "",
        ]),
    )
