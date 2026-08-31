# Interactive aliases and small wrappers. Sourced from ~/.zshrc.

alias cl='claude'
# Cursor CLI. nixpkgs' cursor-cli ships the binary as cursor-agent.
alias cr='cursor-agent'
alias n='nvim'
alias h='herdr'
# Render markdown in the terminal, mermaid diagrams as kitty graphics.
alias md='mdroll --mermaid image --graphics kitty'

# yazi, but cd to wherever the file manager was left when it exits.
function y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  command yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
