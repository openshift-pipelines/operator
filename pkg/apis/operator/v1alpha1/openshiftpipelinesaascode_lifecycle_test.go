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

package v1alpha1

import (
	"testing"

	tektonoperatorv1alpha1 "github.com/tektoncd/operator/pkg/apis/operator/v1alpha1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	apistest "knative.dev/pkg/apis/testing"
)

func TestPipelinesAsCodeGroupVersionKind(t *testing.T) {
	r := &PipelinesAsCode{}
	want := schema.GroupVersionKind{
		Group:   GroupName,
		Version: SchemaVersion,
		Kind:    KindPipelinesAsCode,
	}
	if got := r.GetGroupVersionKind(); got != want {
		t.Errorf("got: %v, want: %v", got, want)
	}
}

func TestPipelinesAsCodeHappyPath(t *testing.T) {
	pac := &PipelinesAsCodeStatus{}
	pac.InitializeConditions()

	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.DependenciesInstalled, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.PreReconciler, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.InstallerSetAvailable, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.InstallerSetReady, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.PostReconciler, t)

	// Dependencies installed
	pac.MarkDependenciesInstalled()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.DependenciesInstalled, t)

	// Pre reconciler completes execution
	pac.MarkPreReconcilerComplete()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.PreReconciler, t)

	// Installer set created
	pac.MarkInstallerSetAvailable()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.InstallerSetAvailable, t)

	// InstallerSet is not ready when deployment pods are not up
	pac.MarkInstallerSetNotReady("waiting for deployments")
	apistest.CheckConditionFailed(pac, tektonoperatorv1alpha1.InstallerSetReady, t)

	// InstallerSet and then PostReconciler become ready and we're good.
	pac.MarkInstallerSetReady()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.InstallerSetReady, t)

	pac.MarkPostReconcilerComplete()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.PostReconciler, t)

	if ready := pac.IsReady(); !ready {
		t.Errorf("pac.IsReady() = %v, want true", ready)
	}
}

func TestPipelinesAsCodeErrorPath(t *testing.T) {
	pac := &PipelinesAsCodeStatus{}
	pac.InitializeConditions()

	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.DependenciesInstalled, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.PreReconciler, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.InstallerSetAvailable, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.InstallerSetReady, t)
	apistest.CheckConditionOngoing(pac, tektonoperatorv1alpha1.PostReconciler, t)

	// Dependencies installed
	pac.MarkDependenciesInstalled()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.DependenciesInstalled, t)

	// Pre reconciler completes execution
	pac.MarkPreReconcilerComplete()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.PreReconciler, t)

	// Installer set created
	pac.MarkInstallerSetAvailable()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.InstallerSetAvailable, t)

	// InstallerSet is not ready when deployment pods are not up
	pac.MarkInstallerSetNotReady("waiting for deployments")
	apistest.CheckConditionFailed(pac, tektonoperatorv1alpha1.InstallerSetReady, t)

	// InstallerSet and then PostReconciler become ready and we're good.
	pac.MarkInstallerSetReady()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.InstallerSetReady, t)

	pac.MarkPostReconcilerComplete()
	apistest.CheckConditionSucceeded(pac, tektonoperatorv1alpha1.PostReconciler, t)

	if ready := pac.IsReady(); !ready {
		t.Errorf("pac.IsReady() = %v, want true", ready)
	}

	// In further reconciliation deployment might fail and installer
	// set will change to not ready

	pac.MarkInstallerSetNotReady("webhook not ready")
	apistest.CheckConditionFailed(pac, tektonoperatorv1alpha1.InstallerSetReady, t)
	if ready := pac.IsReady(); ready {
		t.Errorf("pac.IsReady() = %v, want false", ready)
	}
}
