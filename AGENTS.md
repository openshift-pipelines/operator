# Openshift-Pipelines-Operator

This repository is the **source of truth for building and releasing the OpenShift Pipelines operator** using [Red Hat Konflux CI](https://github.com/konflux-ci/).

It vendors [`tektoncd/operator`](https://github.com/tektoncd/operator) and assembles OpenShift-specific customizations, image references, and OLM (Operator Lifecycle Manager) artifacts needed to ship OpenShift Pipelines as a supported Red Hat product.

## What This Repo Does

- Vendors the upstream `tektoncd/operator` source under [`upstream/`](./upstream) (unchanged).
- Applies OpenShift-specific patches, Dockerfiles, and OLM bundle/index manifests under [`openshift/`](./openshift).
- Tracks image references for all component operands (pipeline, triggers, chains, results, CLI, hub, PAC, etc.) in [`project.yaml`](./project.yaml).
- Generates CI/CD manifests (`.konflux/`, `.tekton/`, `.github/`) from the [`openshift-pipelines/hack`](https://github.com/openshift-pipelines/hack) project.
- Provides `hack/` scripts for updating images, rendering OLM catalogs, and managing bundle/index artifacts.

## Key Directories

| Path | Description |
|------|-------------|
| `upstream/` | Vendored, unmodified copy of `tektoncd/operator` |
| `openshift/` | OpenShift-specific code: Dockerfiles, OLM bundle, index, RPM prefetch |
| `hack/` | Shell scripts for image updates, bundle rendering, and catalog management |
| `project.yaml` | Single source of truth for component versions and image references |
| `head` | Current commit SHA of the vendored `tektoncd/operator` |
| `.konflux/` | Konflux CI pipeline manifests (auto-generated) |
| `.tekton/` | Tekton pipeline manifests (auto-generated) |
| `.github/` | GitHub Actions workflows (some auto-generated) |
| `docs/` | Architecture diagrams and supplementary documentation |


## Agent Guidance

When working in this repository, keep the following in mind:

- **Do not manually edit files under `upstream/`** — they are vendored from `tektoncd/operator` and must remain unchanged. Updates happen by bumping the SHA in `head` and re-vendoring.
- **`project.yaml` is the single source of truth** for component image references and version numbers. Update it there first; downstream files are generated from it.
- **Many files are auto-generated** by scripts in `hack/` or by the [`openshift-pipelines/hack`](https://github.com/openshift-pipelines/hack) project. Regenerate them with the appropriate `make` target or `hack/` script rather than editing by hand.
- **OLM bundle and index artifacts** live under `openshift/olm-catalog/`. They are rendered via `hack/render-catalog.sh` and `hack/update-olm-bundle.sh`.
- **CI manifests** (`.konflux/`, `.tekton/`, `.github/`) are largely generated; prefer updating the `hack` source project and re-running generation over hand-editing.
- When updating a component version, use `hack/update-version.sh` and `hack/operator-update-images.sh` to propagate changes consistently.
