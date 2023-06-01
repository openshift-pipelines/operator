/*
Copyright 2022 The Tekton Authors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package openshiftplatform

import (
	k8sInstallerSet "github.com/tektoncd/operator/pkg/reconciler/kubernetes/tektoninstallerset"
	"github.com/openshift-pipelines/operator/pkg/reconciler/pipelinesascode"
	openshiftAddon "github.com/openshift-pipelines/operator/pkg/reconciler/tektonaddon"
	openshiftChain "github.com/openshift-pipelines/operator/pkg/reconciler/tektonchain"
	openshiftConfig "github.com/openshift-pipelines/operator/pkg/reconciler/tektonconfig"
	openshiftHub "github.com/openshift-pipelines/operator/pkg/reconciler/tektonhub"
	openshiftPipeline "github.com/openshift-pipelines/operator/pkg/reconciler/tektonpipeline"
	openshiftTrigger "github.com/openshift-pipelines/operator/pkg/reconciler/tektontrigger"
	"github.com/tektoncd/operator/pkg/reconciler/platform"
	"knative.dev/pkg/injection"
)

const (
	ControllerTektonAddon              platform.ControllerName = "tektonaddon"
	ControllerPipelinesAsCode platform.ControllerName = "openshiftpipelinesascode"
	PlatformNameOpenShift              string                  = "openshift"
)

var (
	// openshiftControllers define a platform.ControllerMap of
	// all controllers(reconcilers) supported by OpenShift platform
	openshiftControllers = platform.ControllerMap{
		platform.ControllerTektonConfig: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonConfig),
			ControllerConstructor: openshiftConfig.NewController,
		},
		platform.ControllerTektonPipeline: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonPipeline),
			ControllerConstructor: openshiftPipeline.NewController,
		},
		platform.ControllerTektonTrigger: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonTrigger),
			ControllerConstructor: openshiftTrigger.NewController,
		},
		platform.ControllerTektonHub: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonHub),
			ControllerConstructor: openshiftHub.NewController,
		},
		platform.ControllerTektonChain: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonChain),
			ControllerConstructor: openshiftChain.NewController,
		},
		ControllerTektonAddon: injection.NamedControllerConstructor{
			Name:                  string(ControllerTektonAddon),
			ControllerConstructor: openshiftAddon.NewController,
		},
		ControllerPipelinesAsCode: injection.NamedControllerConstructor{
			Name:                  string(ControllerPipelinesAsCode),
			ControllerConstructor: pipelinesascode.NewController,
		},
		// there is no openshift specific extension for TektonInstallerSet Reconciler (yet 🤓)
		platform.ControllerTektonInstallerSet: injection.NamedControllerConstructor{
			Name:                  string(platform.ControllerTektonInstallerSet),
			ControllerConstructor: k8sInstallerSet.NewController,
		},
	}
)
