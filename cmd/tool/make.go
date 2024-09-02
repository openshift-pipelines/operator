package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"github.com/tektoncd/operator/cmd/tool/commands"
	"golang.org/x/sync/errgroup"
)

var (
	target string
	clean  bool
)

func makeSourcesCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use: "make-sources",
		RunE: func(cmd *cobra.Command, args []string) error {
			componentFile := args[0]
			components, err := commands.ReadComponents(componentFile)
			if err != nil {
				return err
			}
			if clean {
				if err := os.RemoveAll(target); err != nil {
					return err
				}
			}
			eg, _ := errgroup.WithContext(context.Background())
			for c, repo := range components {
				eg.Go(cloneComponent(c, repo.Github, repo.Version, target))
			}
			if err := eg.Wait(); err != nil {
				return err
			}
			return nil
		},
	}
	cmd.Flags().StringVar(&target, "target", "components", "target folder to clone repository in.")
	cmd.Flags().BoolVar(&clean, "clean", true, "clean the target folder")
	return cmd
}

func cloneComponent(component, repo, version, target string) func() error {
	return func() error {
		folder := filepath.Join(target, component)
		// mkdir folder
		if err := os.MkdirAll(folder, 0o755); err != nil {
			return err
		}
		// git init
		if err := git(folder, "init"); err != nil {
			return err
		}
		// git fetch
		if err := git(folder, "fetch", "--depth", "1", "https://github.com/"+repo, version); err != nil {
			return err
		}
		// git checkout
		if err := git(folder, "checkout", "FETCH_HEAD"); err != nil {
			return err
		}
		// Remove .git folder
		if err := os.RemoveAll(filepath.Join(folder, ".git")); err != nil {
			return err
		}
		fmt.Printf("%s: cloning %s@%s in %s\n", component, repo, version, folder)
		return nil
	}
}

func git(workingdir string, args ...string) error {
	gitInitCmd := exec.Command("git", args...)
	gitInitCmd.Dir = workingdir
	out, err := gitInitCmd.Output()
	if err != nil {
		return fmt.Errorf("git %s failed: %w\noutput: %s",
			strings.Join(args, " "), err, string(out))
	}
	return nil
}
