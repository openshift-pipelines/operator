//
// Copyright 2021, Sander van Harmelen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

package gitlab

import (
	"fmt"
	"net/http"
)

type (
	ProjectBadgesServiceInterface interface {
		ListProjectBadges(pid interface{}, opt *ListProjectBadgesOptions, options ...RequestOptionFunc) ([]*ProjectBadge, *Response, error)
		GetProjectBadge(pid interface{}, badge int, options ...RequestOptionFunc) (*ProjectBadge, *Response, error)
		AddProjectBadge(pid interface{}, opt *AddProjectBadgeOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error)
		EditProjectBadge(pid interface{}, badge int, opt *EditProjectBadgeOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error)
		DeleteProjectBadge(pid interface{}, badge int, options ...RequestOptionFunc) (*Response, error)
		PreviewProjectBadge(pid interface{}, opt *ProjectBadgePreviewOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error)
	}

	// ProjectBadgesService handles communication with the project badges
	// related methods of the GitLab API.
	//
	// GitLab API docs: https://docs.gitlab.com/ee/api/project_badges.html
	ProjectBadgesService struct {
		client *Client
	}
)

var _ ProjectBadgesServiceInterface = (*ProjectBadgesService)(nil)

// ProjectBadge represents a project badge.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#list-all-badges-of-a-project
type ProjectBadge struct {
	ID               int    `json:"id"`
	Name             string `json:"name"`
	LinkURL          string `json:"link_url"`
	ImageURL         string `json:"image_url"`
	RenderedLinkURL  string `json:"rendered_link_url"`
	RenderedImageURL string `json:"rendered_image_url"`
	// Kind represents a project badge kind. Can be empty, when used PreviewProjectBadge().
	Kind string `json:"kind"`
}

// ListProjectBadgesOptions represents the available ListProjectBadges()
// options.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#list-all-badges-of-a-project
type ListProjectBadgesOptions struct {
	ListOptions
	Name *string `url:"name,omitempty" json:"name,omitempty"`
}

// ListProjectBadges gets a list of a project's badges and its group badges.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#list-all-badges-of-a-project
func (s *ProjectBadgesService) ListProjectBadges(pid interface{}, opt *ListProjectBadgesOptions, options ...RequestOptionFunc) ([]*ProjectBadge, *Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, nil, err
	}
	u := fmt.Sprintf("projects/%s/badges", PathEscape(project))

	req, err := s.client.NewRequest(http.MethodGet, u, opt, options)
	if err != nil {
		return nil, nil, err
	}

	var pb []*ProjectBadge
	resp, err := s.client.Do(req, &pb)
	if err != nil {
		return nil, resp, err
	}

	return pb, resp, nil
}

// GetProjectBadge gets a project badge.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#get-a-badge-of-a-project
func (s *ProjectBadgesService) GetProjectBadge(pid interface{}, badge int, options ...RequestOptionFunc) (*ProjectBadge, *Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, nil, err
	}
	u := fmt.Sprintf("projects/%s/badges/%d", PathEscape(project), badge)

	req, err := s.client.NewRequest(http.MethodGet, u, nil, options)
	if err != nil {
		return nil, nil, err
	}

	pb := new(ProjectBadge)
	resp, err := s.client.Do(req, pb)
	if err != nil {
		return nil, resp, err
	}

	return pb, resp, nil
}

// AddProjectBadgeOptions represents the available AddProjectBadge() options.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#add-a-badge-to-a-project
type AddProjectBadgeOptions struct {
	LinkURL  *string `url:"link_url,omitempty" json:"link_url,omitempty"`
	ImageURL *string `url:"image_url,omitempty" json:"image_url,omitempty"`
	Name     *string `url:"name,omitempty" json:"name,omitempty"`
}

// AddProjectBadge adds a badge to a project.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#add-a-badge-to-a-project
func (s *ProjectBadgesService) AddProjectBadge(pid interface{}, opt *AddProjectBadgeOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, nil, err
	}
	u := fmt.Sprintf("projects/%s/badges", PathEscape(project))

	req, err := s.client.NewRequest(http.MethodPost, u, opt, options)
	if err != nil {
		return nil, nil, err
	}

	pb := new(ProjectBadge)
	resp, err := s.client.Do(req, pb)
	if err != nil {
		return nil, resp, err
	}

	return pb, resp, nil
}

// EditProjectBadgeOptions represents the available EditProjectBadge() options.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#edit-a-badge-of-a-project
type EditProjectBadgeOptions struct {
	LinkURL  *string `url:"link_url,omitempty" json:"link_url,omitempty"`
	ImageURL *string `url:"image_url,omitempty" json:"image_url,omitempty"`
	Name     *string `url:"name,omitempty" json:"name,omitempty"`
}

// EditProjectBadge updates a badge of a project.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#edit-a-badge-of-a-project
func (s *ProjectBadgesService) EditProjectBadge(pid interface{}, badge int, opt *EditProjectBadgeOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, nil, err
	}
	u := fmt.Sprintf("projects/%s/badges/%d", PathEscape(project), badge)

	req, err := s.client.NewRequest(http.MethodPut, u, opt, options)
	if err != nil {
		return nil, nil, err
	}

	pb := new(ProjectBadge)
	resp, err := s.client.Do(req, pb)
	if err != nil {
		return nil, resp, err
	}

	return pb, resp, nil
}

// DeleteProjectBadge removes a badge from a project. Only project's
// badges will be removed by using this endpoint.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#remove-a-badge-from-a-project
func (s *ProjectBadgesService) DeleteProjectBadge(pid interface{}, badge int, options ...RequestOptionFunc) (*Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, err
	}
	u := fmt.Sprintf("projects/%s/badges/%d", PathEscape(project), badge)

	req, err := s.client.NewRequest(http.MethodDelete, u, nil, options)
	if err != nil {
		return nil, err
	}

	return s.client.Do(req, nil)
}

// ProjectBadgePreviewOptions represents the available PreviewProjectBadge() options.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#preview-a-badge-from-a-project
type ProjectBadgePreviewOptions struct {
	LinkURL  *string `url:"link_url,omitempty" json:"link_url,omitempty"`
	ImageURL *string `url:"image_url,omitempty" json:"image_url,omitempty"`
}

// PreviewProjectBadge returns how the link_url and image_url final URLs would be after
// resolving the placeholder interpolation.
//
// GitLab API docs:
// https://docs.gitlab.com/ee/api/project_badges.html#preview-a-badge-from-a-project
func (s *ProjectBadgesService) PreviewProjectBadge(pid interface{}, opt *ProjectBadgePreviewOptions, options ...RequestOptionFunc) (*ProjectBadge, *Response, error) {
	project, err := parseID(pid)
	if err != nil {
		return nil, nil, err
	}
	u := fmt.Sprintf("projects/%s/badges/render", PathEscape(project))

	req, err := s.client.NewRequest(http.MethodGet, u, opt, options)
	if err != nil {
		return nil, nil, err
	}

	pb := new(ProjectBadge)
	resp, err := s.client.Do(req, &pb)
	if err != nil {
		return nil, resp, err
	}

	return pb, resp, nil
}
