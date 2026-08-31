# Herdr pane layout helpers. Sourced from ~/.zshrc.
#
# Naming: h + <panes in the left column> + <panes in the right column>.
#   h13 -> one tall pane on the left, three stacked on the right
#   h23 -> two stacked on the left (~2:1), three stacked on the right
#
# Both only run on a tab that still has a single pane, so they can assume the
# starting geometry instead of trying to reason about an existing split.

# Extract the first "pane_id" from a herdr JSON response.
_herdr_pane_id() {
  print -r -- "$1" | command grep -o '"pane_id":"[^"]*"' | command head -1 | command cut -d'"' -f4
}

# Refuse to run unless we are inside herdr and the current tab has one pane.
_herdr_require_single_pane_tab() {
  local cmd=${1:-herdr}
  local layout count

  if [[ "${HERDR_ENV:-}" != 1 ]]; then
    print -u2 "$cmd: not inside herdr"
    return 1
  fi

  layout=$(herdr pane layout --current 2>/dev/null) || {
    print -u2 "$cmd: could not read the current layout"
    return 1
  }
  # Count "pane_id" keys in the layout snapshot. "focused_pane_id" does not
  # match, since the quote before pane_id is what anchors it.
  count=$(print -r -- "$layout" | command grep -o '"pane_id"' | command wc -l | tr -d ' ')

  if (( count != 1 )); then
    print -u2 "$cmd: current tab has ${count} pane(s) (need exactly 1)"
    return 1
  fi
}

# Split the given pane into three equal rows. 0.333 leaves two thirds below,
# and halving that gives three equal parts.
_herdr_stack3() {
  local pane=$1 json lower
  json=$(herdr pane split "$pane" --direction down --ratio 0.333 --cwd "$PWD" --no-focus) || return 1
  lower=$(_herdr_pane_id "$json")
  [[ -n $lower ]] || { print -u2 'herdr: split did not return a pane id'; return 1; }
  herdr pane split "$lower" --direction down --ratio 0.5 --cwd "$PWD" --no-focus >/dev/null || return 1
}

# h13 — left 1 tall, right 3 stacked.
h13() {
  _herdr_require_single_pane_tab h13 || return 1

  local json right
  json=$(herdr pane split --current --direction right --ratio 0.5 --cwd "$PWD" --no-focus) || return 1
  right=$(_herdr_pane_id "$json")
  [[ -n $right ]] || { print -u2 'h13: split did not return a pane id'; return 1; }

  _herdr_stack3 "$right"
}

# h23 — left 2 stacked (~2:1), right 3 stacked.
h23() {
  _herdr_require_single_pane_tab h23 || return 1

  local json right
  json=$(herdr pane split --current --direction right --ratio 0.67 --cwd "$PWD" --no-focus) || return 1
  right=$(_herdr_pane_id "$json")
  [[ -n $right ]] || { print -u2 'h23: split did not return a pane id'; return 1; }

  # Left column: 2:1 top/bottom.
  herdr pane split --current --direction down --ratio 0.67 --cwd "$PWD" --no-focus >/dev/null || return 1

  _herdr_stack3 "$right"
}
