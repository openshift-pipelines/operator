# _Work in progress_ : OpenShift Pipelines Operator

This is the repository for OpenShift Pipelines operator, based of the
upstream [`tektoncd/operator`](https://github.com/tektoncd/operator).

*It is still marked as wip until a release is using this instead of upstream*.

This README needs to be updated as we go and get this repository to a ready-to-use state.

# Developement/design notes

- This repository uses `tektoncd/operator` as a dependency
- By default it tracks released components, just like `tektoncd/operator` but it should be easy to build a nightly or "based-of" components PR version
- We track `tektoncd/operator` `main` branch for the dependency, and will update it daily if it passes tests (not necessarily all of them).
- It should be very easy to run end-to-end tests based of a clean OpenShift instance (provided by openshift-ci, clusterbot, or anything)
