# OpenShift Pipeline's e2e operator's tests

This folder is the "root" of all end-to-end tests that will execute on
top of an operator's build and deployed on an OpenShift cluster.

We want to run the following set of tests:
- The operator's own test suites.
- [`openshift-pipelines/release-tests`](https://github.com/openshift-pipelines/release-tests/)
- Upstream components tests
  - `pipeline`, `triggers`, `chains`, …
  - we may skip some if they don't work with the openshift's flavor
