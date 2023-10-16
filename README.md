# _Work in progress_ : OpenShift Pipelines Operator

This is the repository for OpenShift Pipelines operator, based of the
upstream [`tektoncd/operator`](https://github.com/tektoncd/operator).

*It is still marked as wip until a release is using this instead of upstream*.

This README needs to be updated as we go and get this repository to a ready-to-use state.

# Developement/design notes

- This repository "pulls" `tektoncd/operator` release, installs it and manages it
    - Fetch the upstream repository (using `vendir`)
    - Build the upstream operator (openshift flavor, long term, no flavor just upstream)
    - Run the upstream operator
- This repository can build any `tektoncd/operator` commits (PRs, branches, tags, forks, etc.) as well as any operands (pipeline, triggers, etc.)
- It should be very easy to run end-to-end tests based of a clean OpenShift instance (provided by openshift-ci, clusterbot, or anything)
- Build using `go` and container runtime
    - The same command can act differently if it's in a container or not