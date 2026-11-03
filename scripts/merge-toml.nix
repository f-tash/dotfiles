{ pkgs }:
let
  # Evaluate the live file only during activation, without putting its data
  # in a derivation or copying it into the Nix store.
  mergeExpression = pkgs.writeText "merge-toml-expression.nix" ''
    { source, destination }:
    let
      lib = import ${pkgs.path}/lib;
      exists = builtins.pathExists destination;
      current =
        if exists then builtins.fromTOML (builtins.readFile destination)
        else { };
      managed = builtins.fromTOML (builtins.readFile source);
      merged = lib.recursiveUpdate current managed;
    in
    if exists && current == merged then ""
    else builtins.toJSON merged
  '';
in
pkgs.writeShellApplication {
  name = "merge-toml";
  runtimeInputs = [ pkgs.coreutils pkgs.diffutils pkgs.nix pkgs.remarshal ];
  text = ''
    source=$1
    destination=$2
    if [ -L "$destination" ] || { [ -e "$destination" ] && [ ! -f "$destination" ]; }; then
      echo "Expected a regular config file: $destination" >&2
      exit 1
    fi

    umask 077
    mkdir -p "$(dirname "$destination")"
    work=$(mktemp -d "$(dirname "$destination")/.merge-toml.XXXXXX")
    trap 'rm -f "$work/original.toml" "$work/merged.json" "$work/updated.toml"; rmdir "$work"' EXIT
    existed=false
    if [ -f "$destination" ]; then
      cp -p "$destination" "$work/original.toml"
      existed=true
    fi

    TOML_MERGE_SOURCE="$source" TOML_MERGE_DESTINATION="$work/original.toml" \
      nix eval --extra-experimental-features nix-command --impure --raw --expr '
        import ${mergeExpression} {
          source = builtins.getEnv "TOML_MERGE_SOURCE";
          destination = builtins.getEnv "TOML_MERGE_DESTINATION";
        }
      ' > "$work/merged.json"
    if [ ! -s "$work/merged.json" ]; then
      exit 0
    fi
    json2toml "$work/merged.json" "$work/updated.toml"

    # Preserve an app edit that happened while the merge was being prepared.
    if [ -L "$destination" ]; then
      echo "Config became a symlink; run apply again: $destination" >&2
      exit 1
    fi
    if "$existed"; then
      if ! cmp -s "$destination" "$work/original.toml"; then
        echo "Config changed during the merge; run apply again: $destination" >&2
        exit 1
      fi
      chmod --reference="$work/original.toml" "$work/updated.toml"
    elif [ -e "$destination" ]; then
      echo "Config was created during the merge; run apply again: $destination" >&2
      exit 1
    fi
    mv -f "$work/updated.toml" "$destination"
  '';
}
