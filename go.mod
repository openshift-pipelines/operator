module github.com/openshift-pipelines/operator

go 1.19

require (
	github.com/tektoncd/plumbing v0.0.0-20230309231045-dbb204980ea8
	k8s.io/code-generator v0.27.1
	knative.dev/pkg v0.0.0-20230320014357-4c84b1b51ee8
)

replace (
	k8s.io/api => k8s.io/api v0.25.9
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.25.9
	k8s.io/apimachinery => k8s.io/apimachinery v0.25.9
	k8s.io/client-go => k8s.io/client-go v0.25.9
	k8s.io/code-generator => k8s.io/code-generator v0.25.9
	knative.dev/pkg => knative.dev/pkg v0.0.0-20230221145627-8efb3485adcf
)

require (
	github.com/go-logr/logr v1.2.4 // indirect
	github.com/google/go-cmp v0.5.9 // indirect
	github.com/spf13/pflag v1.0.5 // indirect
	golang.org/x/mod v0.11.0 // indirect
	golang.org/x/sync v0.3.0 // indirect
	golang.org/x/sys v0.8.0 // indirect
	golang.org/x/text v0.9.0 // indirect
	golang.org/x/tools v0.7.0 // indirect
	k8s.io/apimachinery v0.27.1 // indirect
	k8s.io/gengo v0.0.0-20221011193443-fad74ee6edd9 // indirect
	k8s.io/klog/v2 v2.90.1 // indirect
)
