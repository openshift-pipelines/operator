/*
Copyright 2023 The Tekton Authors
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

package pipelinerun

import (
	"context"
	"encoding/json"
	"fmt"

	intoto "github.com/in-toto/attestation/go/v1"
	"github.com/tektoncd/chains/pkg/chains/formats/slsa/extract"
	builddefinition "github.com/tektoncd/chains/pkg/chains/formats/slsa/internal/build_definition"
	"github.com/tektoncd/chains/pkg/chains/formats/slsa/internal/provenance"
	resolveddependencies "github.com/tektoncd/chains/pkg/chains/formats/slsa/internal/resolved_dependencies"
	"github.com/tektoncd/chains/pkg/chains/formats/slsa/internal/slsaconfig"
	"github.com/tektoncd/chains/pkg/chains/objects"
)

const (
	pipelineRunResults = "pipelineRunResults/%s"
	// JsonMediaType is the media type of json encoded content used in resource descriptors
	JsonMediaType = "application/json"
)

// GenerateAttestation generates a provenance statement with SLSA v1.0 predicate for a pipeline run.
func GenerateAttestation(ctx context.Context, pro *objects.PipelineRunObjectV1, slsaconfig *slsaconfig.SlsaConfig) (interface{}, error) {
	bp, err := byproducts(pro)
	if err != nil {
		return nil, err
	}

	bd, err := builddefinition.GetPipelineRunBuildDefinition(ctx, pro, slsaconfig, resolveddependencies.ResolveOptions{})
	if err != nil {
		return nil, err
	}

	sub := extract.SubjectDigests(ctx, pro, slsaconfig)

	return provenance.GetSLSA1Statement(pro, sub, &bd, bp, slsaconfig)
}

// byproducts contains the pipelineRunResults
func byproducts(pro *objects.PipelineRunObjectV1) ([]*intoto.ResourceDescriptor, error) {
	byProd := []*intoto.ResourceDescriptor{}
	for _, key := range pro.Status.Results {
		content, err := json.Marshal(key.Value)
		if err != nil {
			return nil, err
		}
		bp := &intoto.ResourceDescriptor{
			Name:      fmt.Sprintf(pipelineRunResults, key.Name),
			Content:   content,
			MediaType: JsonMediaType,
		}
		byProd = append(byProd, bp)
	}
	return byProd, nil
}
