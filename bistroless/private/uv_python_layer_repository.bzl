load(
    "//bistroless/private:common.bzl",
    "run_checked",
    "write_layer_build",
)

def _validate_imports(ctx):
    site_packages = ctx.path("rootfs/site-packages")

    if not site_packages.exists:
        fail("Python site-packages directory was not created")

    for import_name in ctx.attr.required_imports:
        relative_path = import_name.replace(".", "/")
        package_path = ctx.path(
            "rootfs/site-packages/%s" % relative_path,
        )
        module_path = ctx.path(
            "rootfs/site-packages/%s.py" % relative_path,
        )

        if not package_path.exists and not module_path.exists:
            fail(
                "Required Python import was not installed: %s" %
                import_name,
            )

def _archive_layer(ctx):
    engine = ctx.which(ctx.attr.container_engine)

    if engine == None:
        fail(
            "Container engine not found: %s\nPATH=%s" % (
                ctx.attr.container_engine,
                ctx.os.environ.get("PATH", ""),
            ),
        )

    ctx.file(
        "archive-layer.sh",
        "\n".join([
            "set -eu",
            "test -d /work/rootfs/site-packages",
            "rm -f /work/layer.tar",
            "tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --format=gnu -cf /work/layer.tar -C /work/rootfs .",
            "test -s /work/layer.tar",
            "",
        ]),
        executable = True,
    )

    run_checked(
        ctx,
        [
            engine,
            "run",
            "--rm",
            "--platform",
            ctx.attr.container_platform,
            "--volume",
            "%s:/work" % ctx.path("."),
            "--workdir",
            "/work",
            ctx.attr.archive_builder_image,
            "/bin/sh",
            "/work/archive-layer.sh",
        ],
        timeout = 3600,
    )

    if not ctx.path("layer.tar").exists:
        fail("Python layer archive was not created")

def _uv_environment(ctx):
    environment = dict(ctx.os.environ)
    environment["UV_CACHE_DIR"] = str(ctx.path("uv-cache"))
    environment["UV_NO_PROGRESS"] = "1"
    environment["UV_PYTHON_DOWNLOADS"] = "automatic"
    environment["UV_SYSTEM_CERTS"] = "1"
    return environment

def _uv_python_layer_repository_impl(ctx):
    uv = ctx.which(ctx.attr.uv)

    if uv == None:
        fail(
            "uv executable not found: %s\nPATH=%s" % (
                ctx.attr.uv,
                ctx.os.environ.get("PATH", ""),
            ),
        )

    ctx.symlink(
        ctx.path(ctx.attr.pyproject),
        "project/pyproject.toml",
    )

    ctx.symlink(
        ctx.path(ctx.attr.lock),
        "project/uv.lock",
    )

    environment = _uv_environment(ctx)

    run_checked(
        ctx,
        [
            uv,
            "export",
            "--project",
            ctx.path("project"),
            "--frozen",
            "--no-dev",
            "--no-emit-project",
            "--format",
            "requirements-txt",
            "--output-file",
            ctx.path("requirements.txt"),
        ],
        environment = environment,
        timeout = 1800,
    )

    arguments = [
        uv,
        "pip",
        "install",
        "--target",
        ctx.path("rootfs/site-packages"),
        "--requirement",
        ctx.path("requirements.txt"),
        "--python-version",
        ctx.attr.python_version,
        "--python-platform",
        ctx.attr.python_platform,
        "--require-hashes",
        "--no-deps",
        "--link-mode",
        "copy",
        "--no-cache",
    ]

    if ctx.attr.only_binary:
        arguments.extend([
            "--only-binary",
            ":all:",
        ])

    run_checked(
        ctx,
        arguments,
        environment = environment,
        timeout = 3600,
    )

    _validate_imports(ctx)
    _archive_layer(ctx)
    write_layer_build(ctx)

uv_python_layer_repository = repository_rule(
    implementation = _uv_python_layer_repository_impl,
    attrs = {
        "archive_builder_image": attr.string(
            default = "debian:trixie-slim",
        ),
        "container_engine": attr.string(
            default = "docker",
        ),
        "container_platform": attr.string(
            mandatory = True,
        ),
        "lock": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "only_binary": attr.bool(
            default = True,
        ),
        "pyproject": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "python_platform": attr.string(
            mandatory = True,
        ),
        "python_version": attr.string(
            mandatory = True,
        ),
        "required_imports": attr.string_list(),
        "uv": attr.string(
            default = "uv",
        ),
    },
    environ = [
        "DOCKER_CONFIG",
        "HOME",
        "HTTP_PROXY",
        "HTTPS_PROXY",
        "NO_PROXY",
        "PATH",
        "SSL_CERT_DIR",
        "SSL_CERT_FILE",
        "UV_EXTRA_INDEX_URL",
        "UV_INDEX_URL",
        "UV_SYSTEM_CERTS",
        "http_proxy",
        "https_proxy",
        "no_proxy",
    ],
)
