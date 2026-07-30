load(
    "@aspect_bazel_lib//lib:expand_template.bzl",
    "expand_template",
)

def define_version_targets():
    expand_template(
        name = "image_version_tag",
        out = "image_version_tag.txt",
        stamp = -1,
        stamp_substitutions = {
            "__VERSION__": "{{STABLE_VERSION}}",
        },
        substitutions = {
            "__VERSION__": "dev",
        },
        template = [
            "__VERSION__",
        ],
        visibility = ["//visibility:public"],
    )

    expand_template(
        name = "image_labels",
        out = "image_labels.txt",
        stamp = -1,
        stamp_substitutions = {
            "__VERSION__": "{{STABLE_VERSION}}",
        },
        substitutions = {
            "__VERSION__": "dev",
        },
        template = [
            "org.opencontainers.image.source=https://github.com/aeluin-technologies/bistroless",
            "org.opencontainers.image.title=bristroless-python",
            "org.opencontainers.image.version=__VERSION__",
        ],
        visibility = ["//visibility:public"],
    )
