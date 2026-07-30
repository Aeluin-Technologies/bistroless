load(
    "//bistroless/private:common.bzl",
    "run_checked",
    "write_layer_build",
)

def _shell_quote(value):
    return "'" + value.replace("'", "'\"'\"'") + "'"

def _apt_options():
    values = [
        "Debug::NoLocking=true",
        "Dir::Etc::sourcelist=/work/apt/sources.list",
        "Dir::Etc::sourceparts=-",
        "Dir::State::lists=/work/apt/lists",
        "Dir::State::status=/work/apt/status",
        "Dir::Cache::archives=/work/apt/archives",
        "Acquire::Languages=none",
        "Acquire::Retries=3",
        "Acquire::Check-Valid-Until=false",
    ]

    return " ".join([
        "-o %s" % _shell_quote(value)
        for value in values
    ])

def _platform(architecture):
    platforms = {
        "amd64": "linux/amd64",
        "arm64": "linux/arm64",
    }

    if architecture not in platforms:
        fail("Unsupported Debian architecture: %s" % architecture)

    return platforms[architecture]

def _symlink_lines(symlinks):
    lines = []

    for destination in sorted(symlinks.keys()):
        if not destination.startswith("/"):
            fail("Symlink destination must be absolute: %s" % destination)

        target = symlinks[destination]
        path = "/work/rootfs" + destination

        lines.extend([
            "rm -rf %s" % _shell_quote(path),
            "mkdir -p \"$(dirname %s)\"" % _shell_quote(path),
            "ln -s %s %s" % (
                _shell_quote(target),
                _shell_quote(path),
            ),
        ])

    return lines

def _debian_layer_repository_impl(ctx):
    engine = ctx.which(ctx.attr.container_engine)

    if engine == None:
        fail(
            "Container engine not found: %s\nPATH=%s" % (
                ctx.attr.container_engine,
                ctx.os.environ.get("PATH", ""),
            ),
        )

    if not ctx.attr.packages:
        fail("At least one Debian package is required")

    builder_image = ctx.attr.builder_image

    if not builder_image:
        builder_image = "debian:%s-slim" % ctx.attr.suite

    source = "deb [arch=%s] %s %s %s" % (
        ctx.attr.architecture,
        ctx.attr.mirror,
        ctx.attr.suite,
        " ".join(ctx.attr.components),
    )

    packages = " ".join([
        _shell_quote(package)
        for package in ctx.attr.packages
    ])

    options = _apt_options()

    script = [
        "set -eu",
        "rm -rf /work/rootfs /work/apt /work/layer.tar",
        "mkdir -p /work/rootfs",
        "mkdir -p /work/apt/lists/partial",
        "mkdir -p /work/apt/archives/partial",
        ": > /work/apt/status",
        "printf '%%s\\n' %s > /work/apt/sources.list" % _shell_quote(source),
        "apt-get %s update" % options,
        "test \"$(find /work/apt/lists -type f | wc -l)\" -gt 0",
        "apt-get %s --yes --download-only --no-install-recommends install %s" % (
            options,
            packages,
        ),
        "found=0",
        "for package in /work/apt/archives/*.deb; do",
        "    [ -f \"$package\" ] || continue",
        "    found=1",
        "    dpkg-deb --extract \"$package\" /work/rootfs",
        "done",
        "[ \"$found\" -eq 1 ]",
    ]

    script.extend(
        _symlink_lines(ctx.attr.symlinks),
    )

    script.extend([
        "tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --format=gnu -cf /work/layer.tar -C /work/rootfs .",
        "test -s /work/layer.tar",
    ])

    ctx.file(
        "build-layer.sh",
        "\n".join(script) + "\n",
        executable = True,
    )

    run_checked(
        ctx,
        [
            engine,
            "run",
            "--rm",
            "--platform",
            _platform(ctx.attr.architecture),
            "--volume",
            "%s:/work" % ctx.path("."),
            "--workdir",
            "/work",
            builder_image,
            "/bin/sh",
            "/work/build-layer.sh",
        ],
        timeout = 3600,
    )

    if not ctx.path("layer.tar").exists:
        fail("Debian layer archive was not created")

    write_layer_build(ctx)

debian_layer_repository = repository_rule(
    implementation = _debian_layer_repository_impl,
    attrs = {
        "architecture": attr.string(
            default = "amd64",
        ),
        "builder_image": attr.string(),
        "components": attr.string_list(
            default = ["main"],
        ),
        "container_engine": attr.string(
            default = "docker",
        ),
        "mirror": attr.string(
            default = "http://deb.debian.org/debian",
        ),
        "packages": attr.string_list(
            mandatory = True,
        ),
        "suite": attr.string(
            mandatory = True,
        ),
        "symlinks": attr.string_dict(),
    },
    environ = [
        "DOCKER_CONFIG",
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "NO_PROXY",
        "PATH",
        "http_proxy",
        "https_proxy",
        "no_proxy",
    ],
)
