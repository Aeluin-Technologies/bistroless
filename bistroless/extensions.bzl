load(
    "//bistroless/private:debian_layer_repository.bzl",
    "debian_layer_repository",
)

load(
    "//bistroless/private:uv_python_layer_repository.bzl",
    "uv_python_layer_repository",
)

def _bistroless_impl(module_ctx):
    names = {}

    for module in module_ctx.modules:
        for tag in module.tags.python:
            if tag.name in names:
                fail("Duplicate bistroless repository name: %s" % tag.name)

            names[tag.name] = True

            uv_python_layer_repository(
                name = tag.name,
                archive_builder_image = tag.archive_builder_image,
                container_engine = tag.container_engine,
                container_platform = tag.container_platform,
                lock = tag.lock,
                only_binary = tag.only_binary,
                pyproject = tag.pyproject,
                python_platform = tag.python_platform,
                python_version = tag.python_version,
                required_imports = tag.required_imports,
                uv = tag.uv,
            )

        for tag in module.tags.debian:
            if tag.name in names:
                fail("Duplicate bistroless repository name: %s" % tag.name)

            names[tag.name] = True

            debian_layer_repository(
                name = tag.name,
                architecture = tag.architecture,
                builder_image = tag.builder_image,
                components = tag.components,
                container_engine = tag.container_engine,
                mirror = tag.mirror,
                packages = tag.packages,
                suite = tag.suite,
                symlinks = tag.symlinks,
            )

_python = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
        ),
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
            mandatory = True,
        ),
        "only_binary": attr.bool(
            default = True,
        ),
        "pyproject": attr.label(
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
)

_debian = tag_class(
    attrs = {
        "name": attr.string(
            mandatory = True,
        ),
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
)

bistroless = module_extension(
    implementation = _bistroless_impl,
    tag_classes = {
        "debian": _debian,
        "python": _python,
    },
)
