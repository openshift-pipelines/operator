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
	_ tektonoperatorv1alpha1.TektonComponentStatus = (*PipelinesAsCodeStatus)(nil)

	opacCondSet = apis.NewLivingConditionSet(
		tektonoperatorv1alpha1.DependenciesInstalled,
		tektonoperatorv1alpha1.PreReconciler,
		tektonoperatorv1alpha1.InstallerSetAvailable,
		tektonoperatorv1alpha1.InstallerSetReady,
		tektonoperatorv1alpha1.PostReconciler,
	)
)

func (pac *PipelinesAsCode) GroupVersionKind() schema.GroupVersionKind {
	return SchemeGroupVersion.WithKind(KindPipelinesAsCode)
}

func (pac *PipelinesAsCode) GetGroupVersionKind() schema.GroupVersionKind {
	return SchemeGroupVersion.WithKind(KindPipelinesAsCode)
}

func (pac *PipelinesAsCodeStatus) GetCondition(t apis.ConditionType) *apis.Condition {
	return opacCondSet.Manage(pac).GetCondition(t)
}

func (pac *PipelinesAsCodeStatus) InitializeConditions() {
	opacCondSet.Manage(pac).InitializeConditions()
}

func (pac *PipelinesAsCodeStatus) IsReady() bool {
	return opacCondSet.Manage(pac).IsHappy()
}

func (pac *PipelinesAsCodeStatus) MarkPreReconcilerComplete() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.PreReconciler)
}

func (pac *PipelinesAsCodeStatus) MarkInstallerSetAvailable() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.InstallerSetAvailable)
}

func (pac *PipelinesAsCodeStatus) MarkInstallerSetReady() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.InstallerSetReady)
}

func (pac *PipelinesAsCodeStatus) MarkPostReconcilerComplete() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.PostReconciler)
}

func (pac *PipelinesAsCodeStatus) MarkNotReady(msg string) {
	opacCondSet.Manage(pac).MarkFalse(
		apis.ConditionReady,
		"Error",
		"Ready: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkPreReconcilerFailed(msg string) {
	pac.MarkNotReady("PreReconciliation failed")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.PreReconciler,
		"Error",
		"PreReconciliation failed with message: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkInstallerSetNotAvailable(msg string) {
	pac.MarkNotReady("TektonInstallerSet not ready")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.InstallerSetAvailable,
		"Error",
		"Installer set not ready: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkInstallerSetNotReady(msg string) {
	pac.MarkNotReady("TektonInstallerSet not ready")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.InstallerSetReady,
		"Error",
		"Installer set not ready: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkPostReconcilerFailed(msg string) {
	pac.MarkNotReady("PostReconciliation failed")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.PostReconciler,
		"Error",
		"PostReconciliation failed with message: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkDependenciesInstalled() {
	opacCondSet.Manage(pac).MarkTrue(tektonoperatorv1alpha1.DependenciesInstalled)
}

func (pac *PipelinesAsCodeStatus) MarkDependencyInstalling(msg string) {
	pac.MarkNotReady("Dependencies installing")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.DependenciesInstalled,
		"Error",
		"Dependencies are installing: %s", msg)
}

func (pac *PipelinesAsCodeStatus) MarkDependencyMissing(msg string) {
	pac.MarkNotReady("Missing Dependencies for TektonTriggers")
	opacCondSet.Manage(pac).MarkFalse(
		tektonoperatorv1alpha1.DependenciesInstalled,
		"Error",
		"Dependencies are missing: %s", msg)
}

func (pac *PipelinesAsCodeStatus) GetVersion() string {
	return pac.Version
}

func (pac *PipelinesAsCodeStatus) SetVersion(version string) {
	pac.Version = version
}
