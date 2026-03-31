package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"sort"
	"strings"

	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
	"golang.org/x/mod/semver"
	"gopkg.in/yaml.v3"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run olm.go config.yaml")
		return
	}

	// Read YAML
	var filePath = os.Args[1]

	var outputFile = "catalog-template.json"
	if len(os.Args) > 2 {
		outputFile = os.Args[2]
	}

	olmFileName := filepath.Join(os.TempDir(), "olm.yaml")
	if len(os.Args) > 3 {
		olmFileName = os.Args[3]
	}
	reuseBundle := false
	var cfg Config
	if fileExists(olmFileName) {
		log.Println("OLM config file already exists. Parsing", olmFileName)
		raw, err := ioutil.ReadFile(olmFileName)
		if err != nil {
			log.Println("Error reading OLM config file:", err)
		} else if err := yaml.Unmarshal(raw, &cfg); err != nil {
			log.Printf("Error parsing %s: %v", olmFileName, err)
			reuseBundle = false
		} else {
			reuseBundle = cfg.Channels != nil && cfg.BundleVersions != nil
		}
		if reuseBundle {
			log.Println("OLM File is valid, Skipping Bundle Creation")
		}

	}
	if !reuseBundle {
		raw, err := ioutil.ReadFile(filePath)
		if err != nil {
			panic(err)
		}
		if err := yaml.Unmarshal(raw, &cfg); err != nil {
			log.Fatalf("Error reading config  %s: %v", olmFileName, err)
		}

		var bundles = cfg.BundleVersions
		var channels = cfg.Channels

		minVersion := cfg.MinVersion
		if minVersion == "" {
			minVersion = "v1.15.0"
		}
		if !strings.HasPrefix(minVersion, "v") {
			minVersion = "v" + minVersion
		}

		for _, b := range cfg.Bundles {
			updateBundleImage(&b)
			bundleVersion := BundleVersion{parseVersion(b.Version), b.Image}
			channel := channelName(bundleVersion)
			if !slices.Contains(channels, channel) {
				channels = append(channels, channel)
			}
			bundles = append(bundles, bundleVersion)
		}
		for _, tag := range findBundleTags(minVersion) {
			bundleImage := getBundleImage(tag)
			bundleVersion := BundleVersion{parseVersion(strings.Trim(tag, "v")), bundleImage}
			channel := channelName(bundleVersion)
			if !slices.Contains(channels, channel) {
				channels = append(channels, channel)
			}
			if !slices.Contains(bundles, bundleVersion) {
				bundles = append(bundles, bundleVersion)
			}
		}

		sort.Slice(bundles, func(i, j int) bool {
			return bundles[i].Version.Compare(bundles[j].Version) < 0
		})

		fmt.Printf("Channels: %s\n", strings.Join(channels, ", "))
		for _, b := range bundles {
			fmt.Printf("  %s\n", b.Version.Raw)
		}

		cfg.BundleVersions = bundles
		cfg.Channels = channels

		// Write to olm.yaml
		olmFile := createFile(olmFileName)
		defer olmFile.Close()
		encoder := yaml.NewEncoder(olmFile)
		encoder.SetIndent(2)

		err = encoder.Encode(cfg)
		if err != nil {
			panic(err)
		}
	}

	var bundles = cfg.BundleVersions
	var channels = cfg.Channels

	// Build output template
	out := Template{
		Schema:  "olm.template.basic",
		Entries: []interface{}{},
	}

	// Add package entry
	out.Entries = append(out.Entries, PackageEntry{
		Schema:         "olm.package",
		Name:           cfg.Package,
		DefaultChannel: cfg.DefaultChannel,
		Icon: &Icon{
			Base64Data: cfg.Base64data,
			MediaType:  "image/png",
		},
	})

	// Add latest channel
	allEntries := buildAllEntries(cfg.Package, bundles)

	out.Entries = append(out.Entries, buildChannel(cfg.Package, "latest", allEntries))
	// Add each minor channel
	for _, channelName := range channels {
		out.Entries = append(out.Entries, buildChannel(cfg.Package, channelName, allEntries))
	}

	// Add bundle entries
	for _, b := range bundles {
		out.Entries = append(out.Entries, Bundle{
			Schema: "olm.bundle",
			Name:   fmt.Sprintf("%s.v%s", cfg.Package, b.Version.Raw),
			Image:  b.Image,
		})
	}

	// Output JSON
	// Open file
	log.Println("Writing catalog to output file:", outputFile)
	// Create file
	f := createFile(outputFile)
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	enc.SetEscapeHTML(false)
	enc.Encode(out)

	log.Println("Catalog Template file written to:", outputFile)

	err := f.Close()
	if err != nil {
		log.Fatal("could not close catalog file:"+outputFile, err)
	}
}

func generateBundles() {

}

// Input Configuration Struct
type Config struct {
	Package        string          `yaml:"package"`
	Base64data     string          `yaml:"base64data"`
	DefaultChannel string          `yaml:"defaultChannel"`
	Bundles        []BundleConfig  `yaml:"bundles"`
	BundleVersions []BundleVersion `yaml:"bundleVersions"`
	Channels       []string        `yaml:"channels"`
	MinVersion     string          `yaml:"minVersion"`
}

type BundleConfig struct {
	Version string
	Image   string
	Tag     string
}

// Output JSON structs
type Template struct {
	Schema  string        `json:"schema"`
	Entries []interface{} `json:"entries"`
}

type PackageEntry struct {
	DefaultChannel string `json:"defaultChannel"`
	Icon           *Icon  `json:"icon,omitempty"`
	Name           string `json:"name"`
	Schema         string `json:"schema"`
}

type Icon struct {
	Base64Data string `json:"base64data"`
	MediaType  string `json:"mediatype"`
}

type Channel struct {
	Entries []ChannelEntry `json:"entries"`
	Name    string         `json:"name"`
	Package string         `json:"package"`
	Schema  string         `json:"schema"`
}

type ChannelEntry struct {
	Name      string `json:"name"`
	Replaces  string `json:"replaces,omitempty"`
	SkipRange string `json:"skipRange"`
}

type Bundle struct {
	Schema string `json:"schema"`
	Name   string `json:"name"`
	Image  string `json:"image"`
}
type BundleVersion struct {
	Version Version `json:"version"`
	Image   string  `json:"image"`
}

// Parse & sort versions

// parse semantic version including extra suffix (5.0.5-742)
var verRegex = regexp.MustCompile(`^v?(\d+)\.(\d+)\.(\d+)(-\d+)?$`)
var tagRegex = regexp.MustCompile(`^v(\d+)\.(\d+)\.(\d+)$`)

type Version struct {
	Raw    string
	Major  int
	Minor  int
	Patch  int
	Suffix string
}

func parseVersion(v string) Version {
	m := verRegex.FindStringSubmatch(v)
	if m == nil {
		panic("Invalid version: " + v)
	}

	var ver Version
	ver.Raw = v
	fmt.Sscanf(m[1], "%d", &ver.Major)
	fmt.Sscanf(m[2], "%d", &ver.Minor)
	fmt.Sscanf(m[3], "%d", &ver.Patch)
	ver.Suffix = m[4]
	return ver
}

func (v Version) Compare(other Version) int {
	if v.Major != other.Major {
		return v.Major - other.Major
	}
	if v.Minor != other.Minor {
		return v.Minor - other.Minor
	}
	if v.Patch != other.Patch {
		return v.Patch - other.Patch
	}
	return strings.Compare(v.Suffix, other.Suffix)
}

func buildAllEntries(pkg string, bundles []BundleVersion) map[string][]ChannelEntry {
	var entries = make(map[string][]ChannelEntry)
	for i, b := range bundles {

		// skipRange rule: previous minor .0
		var skip string
		prevMinor := b.Version.Minor - 1
		if prevMinor > 0 {
			skip = fmt.Sprintf(">=%d.%d.0 <%s", b.Version.Major, prevMinor, b.Version.Raw)
		} else if i > 0 {
			skip = fmt.Sprintf(">=%d.%d.0 <%s", bundles[i-1].Version.Major, bundles[i-1].Version.Minor, b.Version.Raw)
		} else {
			skip = fmt.Sprintf(">=%d.%d.%d <%s", b.Version.Major, b.Version.Minor, b.Version.Patch-1, b.Version.Raw)
		}

		var replaces string
		if i > 0 {
			replaces = fmt.Sprintf("%s.v%s", pkg, bundles[i-1].Version.Raw)
		}

		entry := ChannelEntry{
			Name:      fmt.Sprintf("%s.v%s", pkg, b.Version.Raw),
			Replaces:  replaces,
			SkipRange: skip,
		}
		versionEntry := entries[channelName(b)]
		entries[channelName(b)] = append(versionEntry, entry)
	}

	return entries

}

func channelName(b BundleVersion) string {
	return fmt.Sprintf("pipelines-%d.%d", b.Version.Major, b.Version.Minor)
}

func buildChannel(pkg, name string, allEntries map[string][]ChannelEntry) Channel {
	channel := Channel{
		Schema:  "olm.channel",
		Name:    name,
		Package: pkg,
	}

	var channelEntries []ChannelEntry
	for _, entry := range allEntries {
		if name == "latest" {
			channelEntries = append(channelEntries, entry...)
		} else {
			channelEntries = allEntries[name]
		}
	}
	sort.Slice(channelEntries, func(i, j int) bool {
		return channelEntries[i].Name < channelEntries[j].Name
	})
	channel.Entries = channelEntries
	return channel
}

const (
	BUNDLE_REPO = "registry.redhat.io/openshift-pipelines/pipelines-operator-bundle"
)

func findBundleTags(minVersion string) []string {
	repo, err := name.NewRepository(BUNDLE_REPO)
	if err != nil {
		log.Fatalf("failed to parse image name: %v", err)
	}
	tags, _ := remote.List(repo, remote.WithAuthFromKeychain(authn.DefaultKeychain))
	var result []string
	for _, tag := range tags {
		if tagRegex.MatchString(tag) {
			if semver.Compare(tag, minVersion) >= 0 {
				result = append(result, tag)
			}

		}
	}
	fmt.Println("found bundle tags:", result)
	return result
}

func getBundleImage(tag string) string {
	inputImage := BUNDLE_REPO + ":" + tag
	ref, err := name.ParseReference(inputImage)
	if err != nil {
		log.Fatalf("failed to parse image name: %v", err)
	}

	// 2. Fetch the descriptor from the remote registry
	// This uses your local docker/podman credentials automatically
	desc, err := remote.Get(ref, remote.WithAuthFromKeychain(authn.DefaultKeychain))
	if err != nil {
		log.Fatalf("failed to fetch image descriptor: %v", err)
	}

	// 3. Construct the new string using the digest
	// desc.Digest contains the sha256 hash
	digestImage := fmt.Sprintf("%s@%s", ref.Context().Name(), desc.Digest.String())
	//log.Printf("fetched image %s:%s", tag, digestImage)
	return digestImage
}

func updateBundleImage(b *BundleConfig) {
	if !strings.Contains(b.Image, "@sha256") {
		if b.Tag == "" {
			b.Tag = "v" + b.Version
		}
		inputImage := "registry.redhat.io/openshift-pipelines/pipelines-operator-bundle:" + b.Tag
		ref, err := name.ParseReference(inputImage)
		if err != nil {
			log.Fatalf("failed to parse image name: %v", err)
		}

		// 2. Fetch the descriptor from the remote registry
		// This uses your local docker/podman credentials automatically
		desc, err := remote.Get(ref, remote.WithAuthFromKeychain(authn.DefaultKeychain))
		if err != nil {
			log.Fatalf("failed to fetch image descriptor: %v", err)
		}

		// 3. Construct the new string using the digest
		// desc.Digest contains the sha256 hash
		digestImage := fmt.Sprintf("%s@%s", ref.Context().Name(), desc.Digest.String())

		fmt.Printf("Original: %s\n", inputImage)
		fmt.Printf("Resolved: %s\n", digestImage)
		b.Image = digestImage
	}
}

func createFile(filename string) *os.File {

	dir := filepath.Dir(filename)
	if err := os.MkdirAll(dir, 0755); err != nil {
		log.Fatalf("failed to create dir %s: %v", dir, err)
	}
	file, err := os.Create(filename)
	if err != nil {
		log.Fatalf("failed to create %s: %v", filename, err)
	}
	return file

}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}
