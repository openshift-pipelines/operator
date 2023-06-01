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
	tektonoperatorv1alpha1 "github.com/tektoncd/operator/pkg/apis/operator/v1alpha1"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"knative.dev/pkg/apis"
)

var (
	_ tektonoperatorv1alpha1.TektonComponentStatus = (*OpenShiftPipelinesAsCodeStatus)(nil)

	opacCondSet = apis.NewLivingConditionSet(
		tektonoperatorv1alpha1.DependenciesInstalled,
		tektonoperatorv1alpha1.PreReconciler,
		tektonoperatorv1alpha1.InstallerSetAvailable,
		tektonoperatorv1alpha1.InstallerSetReady,
		tektonoperatorv1alpha1.PostReconciler,
	)
)

func (pac *OpenShiftPipelinesAsCode) GroupVersionKind() schema.GroupVersionKind {
	return SchemeGroupVersion.WithKind(KindOpenShiftPipelinesAsCode)
}

func (pac *OpenShiftPipelinesAsCode) GetGroupVersionKind() schema.GroupVersionKind {
	return SchemeGroupVersion.WithKind(KindOpenShiftPipelinesAsCode)
}

func (pac *OpenShiftPipelinesAsCodeStatus) GetCondition(t apis.ConditionType) *apis.Condition {
	return opacCondSet.Manage(pac).GetCondition(t)
}

func (pac *OpenShiftPipelinesAsCodeStatus) InitializeConditions() {
	opacCondSet.Manage(pac).InitializeConditions()
}

func (pac *OpenShiftPipelinesAsCodeStatus) IsReady() bool {
	return opacCondSet.Manage(pac).IsHappy()
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkPreReconcilerComplete() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.PreReconciler)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkInstallerSetAvailable() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.InstallerSetAvailable)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkInstallerSetReady() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.InstallerSetReady)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkPostReconcilerComplete() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.PostReconciler)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkNotReady(msg string) {
	opacCondSet.Manage(pac).MarkFalse(
		apis.ConditionReady,
		"Error",
		"Ready: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkPreReconcilerFailed(msg string) {
	pac.MarkNotReady("PreReconciliation failed")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.PreReconciler,
		"Error",
		"PreReconciliation failed with message: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkInstallerSetNotAvailable(msg string) {
	pac.MarkNotReady("TektonInstallerSet not ready")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.InstallerSetAvailable,
		"Error",
		"Installer set not ready: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkInstallerSetNotReady(msg string) {
	pac.MarkNotReady("TektonInstallerSet not ready")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.InstallerSetReady,
		"Error",
		"Installer set not ready: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkPostReconcilerFailed(msg string) {
	pac.MarkNotReady("PostReconciliation failed")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.PostReconciler,
		"Error",
		"PostReconciliation failed with message: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkDependenciesInstalled() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.DependenciesInstalled)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkDependencyInstalling(msg string) {
	pac.MarkNotReady("Dependencies installing")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.DependenciesInstalled,
		"Error",
		"Dependencies are installing: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) MarkDependencyMissing(msg string) {
	pac.MarkNotReady("Missing Dependencies for TektonTriggers")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.DependenciesInstalled,
		"Error",
		"Dependencies are missing: %s", msg)
}

func (pac *OpenShiftPipelinesAsCodeStatus) GetVersion() string {
	return pac.Version
}

func (pac *OpenShiftPipelinesAsCodeStatus) SetVersion(version string) {
	pac.Version = version
}
