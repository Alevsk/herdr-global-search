#!/usr/bin/env bash

# Global search workspaces, tabs, and panes using fzf

# Path to herdr binary is provided in environment by the plugin runner, but fallback to herdr in PATH
HERDR="${HERDR_BIN_PATH:-herdr}"

# Ensure jq and fzf are available
if ! command -v jq >/dev/null; then
    echo "Error: jq is required for this plugin."
    sleep 2
    exit 1
fi

if ! command -v fzf >/dev/null; then
    echo "Error: fzf is required for this plugin."
    sleep 2
    exit 1
fi

# Fetch list of workspaces, format: workspace <id> <focus_id> <display string>
# In our case focus_id is just the workspace ID
WORKSPACES=$("$HERDR" workspace list | jq -r '
  .result.workspaces[]? | "workspace \(.workspace_id) \(.workspace_id) [Workspace] \(.label)"
')

# Fetch list of tabs
TABS=$("$HERDR" tab list | jq -r '
  .result.tabs[]? | "tab \(.tab_id) \(.tab_id) [Tab] \(.label) (Workspace: \(.workspace_id))"
')

# Fetch list of panes
# Note: we use tab_id as the focus_id because focusing a pane globally requires direction flags 
# in the current version, so we just focus its parent tab instead.
PANES=$("$HERDR" pane list | jq -r '
  .result.panes[]? | "pane \(.pane_id) \(.tab_id) [Pane] \(.terminal_title_stripped // "Pane \(.pane_id)")"
')

# Combine and pass to fzf
# We hide the first 3 fields (<type> <id> <focus_id>) using --with-nth=4..
SELECTED=$(printf "%s\n%s\n%s\n" "$WORKSPACES" "$TABS" "$PANES" | awk 'NF' | fzf --with-nth=4.. --prompt="Search Herdr > " --ansi)

# Exit if nothing selected (user pressed escape)
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Parse selection
TYPE=$(echo "$SELECTED" | awk '{print $1}')
ID=$(echo "$SELECTED" | awk '{print $2}')
FOCUS_ID=$(echo "$SELECTED" | awk '{print $3}')

# Navigate based on selected type
case "$TYPE" in
    workspace)
        "$HERDR" workspace focus "$FOCUS_ID"
        ;;
    tab)
        "$HERDR" tab focus "$FOCUS_ID"
        ;;
    pane)
        # We focus the tab that contains the pane, which brings it to the foreground
        "$HERDR" tab focus "$FOCUS_ID"
        ;;
esac
