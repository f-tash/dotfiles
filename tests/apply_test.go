package tests

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func command(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command(args[0], args[1:]...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("%v: %v\n%s", args, err, out)
	}
	return string(out)
}

func write(t *testing.T, path, content string, mode os.FileMode) {
	t.Helper()
	if err := os.WriteFile(path, []byte(content), mode); err != nil {
		t.Fatal(err)
	}
}

// All Git data, fake local settings and command doubles live in t.TempDir.
// No real Nix command or activation is executed.
func TestApply(t *testing.T) {
	script, err := os.ReadFile("../apply.sh")
	if err != nil {
		t.Fatal(err)
	}
	for _, scenario := range []string{"build", "switch", "default-switch", "nix-failure", "term", "staged-private", "no-private", "missing-local", "wrong-user", "wrong-home", "linux", "invalid-mode", "extra-arg", "missing-tracked"} {
		t.Run(scenario, func(t *testing.T) {
			root := t.TempDir()
			repo := filepath.Join(root, "repo with spaces")
			bin := filepath.Join(root, "bin")
			temp := filepath.Join(root, "snapshots with spaces")
			for _, dir := range []string{repo, bin, temp} {
				if err := os.Mkdir(dir, 0700); err != nil {
					t.Fatal(err)
				}
			}
			write(t, filepath.Join(repo, "apply.sh"), string(script), 0700)
			write(t, filepath.Join(repo, ".gitignore"), "/local.nix\n/private.nix\n", 0600)
			write(t, filepath.Join(repo, "tracked file"), "original", 0600)
			command(t, repo, "git", "init", "-q")
			command(t, repo, "git", "add", ".")
			command(t, repo, "git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "fixture")
			// The staged version deliberately differs from the working-tree version.
			write(t, filepath.Join(repo, "tracked file"), "staged", 0600)
			command(t, repo, "git", "add", "tracked file")
			write(t, filepath.Join(repo, "tracked file"), "working", 0600)
			write(t, filepath.Join(repo, "new file"), "new", 0600)
			command(t, repo, "git", "add", "new file")
			write(t, filepath.Join(repo, "untracked"), "must not be copied", 0600)
			write(t, filepath.Join(repo, "local.nix"), "{ username = \"test\"; }", 0600)
			write(t, filepath.Join(repo, "private.nix"), "{ }", 0600)
			if scenario == "staged-private" {
				command(t, repo, "git", "add", "-f", "private.nix")
			}
			if scenario == "no-private" {
				if err := os.Remove(filepath.Join(repo, "private.nix")); err != nil {
					t.Fatal(err)
				}
			}
			if scenario == "missing-local" {
				if err := os.Remove(filepath.Join(repo, "local.nix")); err != nil {
					t.Fatal(err)
				}
			}
			if scenario == "missing-tracked" {
				if err := os.Remove(filepath.Join(repo, "tracked file")); err != nil {
					t.Fatal(err)
				}
			}
			before, err := os.ReadFile(filepath.Join(repo, ".git/index"))
			if err != nil {
				t.Fatal(err)
			}
			write(t, filepath.Join(bin, "uname"), "#!/bin/sh\nif [ \"$CASE\" = linux ]; then echo Linux; elif [ \"$1\" = -s ]; then echo Darwin; else echo arm64; fi\n", 0700)
			write(t, filepath.Join(bin, "id"), "#!/bin/sh\necho test\n", 0700)
			write(t, filepath.Join(bin, "nix"), `#!/bin/sh
set -eu
printf '%s\n' "$@" >> "$LOG"
if [ "$1" = eval ]; then
 case "$*" in
  *home.username*) if [ "$CASE" = wrong-user ]; then echo other; else echo test; fi ;;
  *home.homeDirectory*) if [ "$CASE" = wrong-home ]; then echo /Users/other; else echo /Users/test; fi ;;
 esac
 exit 0
fi
[ "$1" = run ] && [ "$2" = --no-update-lock-file ]
source=${3#path:}
source=${source%#home-manager}
[ "$4" = -- ] && [ "$5" = "$MODE" ] && [ "$6" = --flake ]
[ "$7" = "path:$source#default" ] && [ "$8" = --impure ] && [ "$9" = --no-update-lock-file ]
[ "$(cat "$source/tracked file")" = working ]
[ "$(cat "$source/new file")" = new ]
[ -f "$source/local.nix" ] && [ ! -e "$source/untracked" ] && [ ! -e "$source/.git" ]
if [ "$CASE" = no-private ]; then [ ! -e "$source/private.nix" ]; else [ -f "$source/private.nix" ]; fi
if [ "$CASE" != staged-private ]; then
 [ -z "$(git ls-files local.nix private.nix)" ]
fi
printf '%s' "$source" > "$SNAPSHOT"
if [ "$CASE" = nix-failure ]; then exit 42; fi
if [ "$CASE" = term ]; then kill -TERM "$PPID"; fi
`, 0700)
			mode := "build"
			if scenario == "switch" || scenario == "default-switch" || scenario == "wrong-user" || scenario == "wrong-home" || scenario == "linux" {
				mode = "switch"
			}
			args := []string{"./apply.sh", mode}
			if scenario == "default-switch" {
				args = []string{"./apply.sh"}
			}
			if scenario == "invalid-mode" {
				args = []string{"./apply.sh", "invalid"}
			}
			if scenario == "extra-arg" {
				args = append(args, "extra")
			}
			cmd := exec.Command("sh", args...)
			cmd.Dir = repo
			cmd.Env = append(os.Environ(), "PATH="+bin+":"+os.Getenv("PATH"), "TMPDIR="+temp, "HOME=/Users/test", "CASE="+scenario, "MODE="+mode, "LOG="+filepath.Join(root, "log"), "SNAPSHOT="+filepath.Join(root, "snapshot"))
			out, runErr := cmd.CombinedOutput()
			wantSuccess := scenario == "build" || scenario == "switch" || scenario == "default-switch" || scenario == "staged-private" || scenario == "no-private"
			if (runErr == nil) != wantSuccess {
				t.Fatalf("success=%v, err=%v, output=%s", wantSuccess, runErr, out)
			}
			after, err := os.ReadFile(filepath.Join(repo, ".git/index"))
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal(before, after) {
				t.Fatal("Git index changed")
			}
			entries, err := os.ReadDir(temp)
			if err != nil {
				t.Fatal(err)
			}
			if len(entries) != 0 {
				t.Fatal("Snapshot was not cleaned up")
			}
			log, _ := os.ReadFile(filepath.Join(root, "log"))
			if !wantSuccess && scenario != "nix-failure" && scenario != "term" && strings.Contains(string(log), "run\n") {
				t.Fatal("Unsafe input reached nix run")
			}
			if scenario == "nix-failure" {
				if e, ok := runErr.(*exec.ExitError); !ok || e.ExitCode() != 42 {
					t.Fatalf("lost Nix exit status: %v", runErr)
				}
			}
		})
	}
}
