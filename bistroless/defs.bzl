load(
    "@rules_oci//oci:defs.bzl",
    "oci_image",
    "oci_image_index",
    "oci_load",
    "oci_push",
)

def bistroless_image(
        name,
        base,
        layers = [],
        architecture = None,
        cmd = None,
        entrypoint = None,
        env = None,
        labels = None,
        os = None,
        user = None,
        variant = None,
        visibility = None,
        workdir = None):
    arguments = {
        "name": name,
        "base": base,
        "tars": layers,
    }

    if architecture != None:
        arguments["architecture"] = architecture

    if cmd != None:
        arguments["cmd"] = cmd

    if entrypoint != None:
        arguments["entrypoint"] = entrypoint

    if env != None:
        arguments["env"] = env

    if labels != None:
        arguments["labels"] = labels

    if os != None:
        arguments["os"] = os

    if user != None:
        arguments["user"] = user

    if variant != None:
        arguments["variant"] = variant

    if visibility != None:
        arguments["visibility"] = visibility

    if workdir != None:
        arguments["workdir"] = workdir

    oci_image(**arguments)

def bistroless_image_index(
        name,
        images,
        annotations = None,
        visibility = None):
    arguments = {
        "name": name,
        "images": images,
    }

    if annotations != None:
        arguments["annotations"] = annotations

    if visibility != None:
        arguments["visibility"] = visibility

    oci_image_index(**arguments)

def bistroless_load(
        name,
        image,
        repo_tags,
        visibility = None):
    arguments = {
        "name": name,
        "image": image,
        "repo_tags": repo_tags,
    }

    if visibility != None:
        arguments["visibility"] = visibility

    oci_load(**arguments)

def bistroless_push(
        name,
        image,
        repository,
        remote_tags,
        visibility = None):
    arguments = {
        "name": name,
        "image": image,
        "remote_tags": remote_tags,
        "repository": repository,
    }

    if visibility != None:
        arguments["visibility"] = visibility

    oci_push(**arguments)
