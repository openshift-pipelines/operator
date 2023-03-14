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

package pipelinesascode

import (
	"context"

	"github.com/openshift-pipelines/operator/pkg/apis/operator/v1alpha1"
	// tektonoperatorv1alpha1 "github.com/tektoncd/operator/pkg/apis/operator/v1alpha1"
	tektonoperatorclient "github.com/tektoncd/operator/pkg/client/injection/client"
	pacInformer "github.com/openshift-pipelines/operator/pkg/client/injection/informers/operator/v1alpha1/pipelinesascode"	
	tektonInstallerinformer "github.com/tektoncd/operator/pkg/client/injection/informers/operator/v1alpha1/tektoninstallerset"
	tektonPipelineinformer "github.com/tektoncd/operator/pkg/client/injection/informers/operator/v1alpha1/tektonpipeline"
	pacreconciler "github.com/openshift-pipelines/operator/pkg/client/injection/reconciler/operator/v1alpha1/pipelinesascode"
	"github.com/tektoncd/operator/pkg/reconciler/common"
	"github.com/tektoncd/operator/pkg/reconciler/kubernetes/tektoninstallerset/client"
	"k8s.io/client-go/tools/cache"
	"knative.dev/pkg/configmap"
	"knative.dev/pkg/controller"
	"knative.dev/pkg/injection"
	"knative.dev/pkg/logging"
)

const versionConfigMap = "pipelines-as-code-info"

// NewController initializes the controller and is called by the generated code
// Registers event handlers to enqueue events
func NewController(ctx context.Context, cmw configmap.Watcher) *controller.Impl {
	return NewExtendedController(OpenShiftExtension)(ctx, cmw)
}

// NewExtendedController returns a controller extended to a specific platform
func NewExtendedController(generator common.ExtensionGenerator) injection.ControllerConstructor {
	return func(ctx context.Context, cmw configmap.Watcher) *controller.Impl {
		logger := logging.FromContext(ctx)

		ctrl := common.Controller{
			Logger:           logger,
			VersionConfigMap: versionConfigMap,
		}
		manifest, pacVersion := ctrl.InitController(ctx, common.PayloadOptions{})

		operatorVer, err := common.OperatorVersion(ctx)
		if err != nil {
			logger.Fatal(err)
		}

		tisClient := tektonoperatorclient.Get(ctx).OperatorV1alpha1().TektonInstallerSets()

		metrics, err := common.NoMetrics()
		if err != nil {
			logger.Errorf("Failed to create trigger metrics recorder %v", err)
		}

		c := &Reconciler{
			pipelineInformer:   tektonPipelineinformer.Get(ctx),
			installerSetClient: client.NewInstallerSetClient(tisClient, operatorVer, pacVersion, v1alpha1.KindPipelinesAsCode, metrics),
			extension:          generator(ctx),
			manifest:           manifest,
			pacVersion:         pacVersion,
		}
		impl := pacreconciler.NewImpl(ctx, c)

		logger.Info("Setting up event handlers for PipelinesAsCode")

		pacInformer.Get(ctx).Informer().AddEventHandler(controller.HandleAll(impl.Enqueue))

		tektonInstallerinformer.Get(ctx).Informer().AddEventHandler(cache.FilteringResourceEventHandler{
			FilterFunc: controller.FilterController(&v1alpha1.PipelinesAsCode{}),
			Handler:    controller.HandleAll(impl.EnqueueControllerOf),
		})
		return impl
	}
}
