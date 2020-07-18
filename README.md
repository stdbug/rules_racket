# Bazel Rules for Racket Applications and Tests

## Setup
You need to have Racket installed and added to your PATH environment variable

Add the following to your `WORKSPACE` file to link rules_racket repository:
```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# Only master branch is available at the moment
git_repository(
    name = "rules_racket",
    branch = "master",
    remote = "https://github.com/codefables/rules_racket.git",
)
```

## Rules
See `examples` dir for usage examples (`racket_binary`, `racket_library` and `racket_test`)
