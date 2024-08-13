# openshift-pipelines operator repository

This is the *future* source of truth for building the OpenShift Pipelines operator with [Red Hat Konflux CI](https://github.com/konflux-ci/) instance

## What "needs to happen" here

- We need to be able to re-build everything from scratch
  - the operator
  - the operands, such as pipeline, …
- We need to be able to push them, generate the bundle and then the image index
- We need to have this all happen in konflux…
  - … that doesn't support `ko` today
- We need to track upstream release and map to it ours.
- We need to track release branches as well
