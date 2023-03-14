/*
Copyright 2021 The Tekton Authors

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
	"time"
)

const (
	// operatorVersion
	VersionEnvKey = "VERSION"

	// Addon Params
	ClusterTasksParam      = "clusterTasks"
	PipelineTemplatesParam = "pipelineTemplates"
	CommunityClusterTasks  = "communityClusterTasks"

	// Hub Params
	EnableDevconsoleIntegrationParam = "enable-devconsole-integration"

	LastAppliedHashKey     = "operator.tekton.dev/last-applied-hash"
	CreatedByKey           = "operator.tekton.dev/created-by"
	ReleaseVersionKey      = "operator.tekton.dev/release-version"
	Component              = "operator.tekton.dev/component" // Used in case a component has sub-components eg TektonHub
	ReleaseMinorVersionKey = "operator.tekton.dev/release-minor-version"
	TargetNamespaceKey     = "operator.tekton.dev/target-namespace"
	InstallerSetType       = "operator.tekton.dev/type"
	LabelOperandName       = "operator.tekton.dev/operand-name"
	DbSecretHash           = "operator.tekton.dev/db-secret-hash"

	UpgradePending = "upgrade pending"
	Reinstalling   = "reinstalling"

	RequeueDelay = 10 * time.Second
)

var (
	PipelinesAsCodeName = "pipelines-as-code"
)
