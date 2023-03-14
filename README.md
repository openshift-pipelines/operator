# Proof of Concept: OpenShift Pipelines Operator

This is the repository of a *proof-of-concept* of OpenShift Operator based of the upstream [`tektoncd/operator`](https://github.com/tektoncd/operator).


- [x] Import `cmd/…`
- [x] Import `config/…`
- [x] Import `openshift` specific package
- [x] GitHub workflows
- [x] Import `OpenShiftPipelinesAsCode` in here
- [x] Rename `OpenShiftPipelinesAsCode` to `PipelinesAsCode`
- [ ] `Makefile`
- [ ] Automated/scripted import payload (copy from tektoncd/operator)
- [ ] Automated/scripted import `tektoncd/operator` CRDs
- [ ] e2e tests
  Run upstream ones, import "and forget" ?
- [ ] Handle "component" *payload* images rebuild
  - We can use the upstream images…
  - but we could also *rebuild them all*, to be even closer to
    downstream. The question is how ?
- [ ] Create `v1beta1.OpenShiftPipelineConfig` to *replace* `TektonConfig`
- [ ] openshift-ci for tests
- [ ] Remove openshift specifics from upstream
