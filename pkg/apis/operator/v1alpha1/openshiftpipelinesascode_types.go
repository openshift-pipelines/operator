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
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	duckv1 "knative.dev/pkg/apis/duck/v1"
)

// PipelinesAsCode is the Schema for the PipelinesAsCode API
// +genclient
// +genreconciler:krshapedlogic=false
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
// +genclient:nonNamespaced
type PipelinesAsCode struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PipelinesAsCodeSpec   `json:"spec,omitempty"`
	Status PipelinesAsCodeStatus `json:"status,omitempty"`
}

// GetSpec implements TektonComponent
func (pac *PipelinesAsCode) GetSpec() TektonComponentSpec {
	return &pac.Spec
}

// GetStatus implements TektonComponent
func (pac *PipelinesAsCode) GetStatus() TektonComponentStatus {
	return &pac.Status
}

// PipelinesAsCodeSpec defines the desired state of PipelinesAsCode
type PipelinesAsCodeSpec struct {
	CommonSpec  `json:",inline"`
	Config      Config `json:"config,omitempty"`
	PACSettings `json:",inline"`
}

// PipelinesAsCodeStatus defines the observed state of PipelinesAsCode
type PipelinesAsCodeStatus struct {
	duckv1.Status `json:",inline"`

	// The version of the installed release
	// +optional
	Version string `json:"version,omitempty"`
}

// PipelinesAsCodeList contains a list of PipelinesAsCode
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object
type PipelinesAsCodeList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PipelinesAsCode `json:"items"`
}

type PACSettings struct {
	Settings map[string]string `json:"settings,omitempty"`
}
