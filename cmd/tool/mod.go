package main

import (
	"fmt"
	"io"
	"os"

	"github.com/openshift-pipelines/pipelines-as-code/pkg/cli"
	"github.com/spf13/cobra"
	"golang.org/x/mod/modfile"
	"golang.org/x/mod/module"
)

// Parse upstream one…
// … and Get replace from upstream
// Parse downstream one…
// … and mutate replace from upstream ones
// … keeping additional ones
func modCommand(ioStreams *cli.IOStreams) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "mod",
		Short: fmt.Sprintf("Update go.mod dependencies"),
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) != 2 {
				return fmt.Errorf("Requires 2 arguments")
			}
			return gomod(args[0], args[1], ioStreams.Out)
		},
		Annotations: map[string]string{
			"commandType": "main",
		},
	}
	return cmd
}

func gomod(upstreamGoModFile, goModFile string, out io.Writer) error {
	// Parse upstream go.mod
	upstreammod, err := readModFile(upstreamGoModFile)
	if err != nil {
		return err
	}

	upstreamMap := map[string]module.Version{}
	for _, replace := range upstreammod.Replace {
		upstreamMap[replace.Old.Path] = replace.New
	}

	// Update current go.mod
	gomod, err := readModFile(goModFile)
	if err != nil {
		return err
	}
	for _, replace := range gomod.Replace {
		m, present := upstreamMap[replace.Old.Path]
		if !present {
			continue
		}
		replace.New = m
	}

	newContent, err := gomod.Format()
	if err != nil {
		return err
	}
	if err := os.WriteFile(goModFile, newContent, 0o666); err != nil {
		return err
	}
	return nil
}

func readModFile(file string) (*modfile.File, error) {
	data, err := os.ReadFile(file)
	if err != nil {
		return nil, err
	}
	mod, err := modfile.Parse(file, data, nil)
	if err != nil {
		return nil, err
	}
	return mod, nil
}
