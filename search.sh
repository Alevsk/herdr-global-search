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

# Fetch list of workspaces, tabs, and panes
WS_JSON=$("$HERDR" workspace list 2>/dev/null)
WS_JSON=${WS_JSON:-"{}"}
TAB_JSON=$("$HERDR" tab list 2>/dev/null)
TAB_JSON=${TAB_JSON:-"{}"}
PANE_JSON=$("$HERDR" pane list 2>/dev/null)
PANE_JSON=${PANE_JSON:-"{}"}

# Generate formatted output strings with lookups
COMBINED=$(jq -n -r \
  --argjson ws "$WS_JSON" \
  --argjson tab "$TAB_JSON" \
  --argjson pane "$PANE_JSON" '
  
  (($ws.result.workspaces // []) | map({key: .workspace_id, value: .label}) | from_entries) as $ws_map |
  (($tab.result.tabs // []) | map({key: .tab_id, value: {label: .label, ws_id: .workspace_id}}) | from_entries) as $tab_map |

  (($ws.result.workspaces // [])[] | "workspace \(.workspace_id) \(.workspace_id) [Workspace] \(.label)"),
  (($tab.result.tabs // [])[] | "tab \(.tab_id) \(.tab_id) [Tab] \(.label) (Workspace: \($ws_map[.workspace_id] // "Unknown"))"),
  (($pane.result.panes // [])[] | "pane \(.pane_id) \(.tab_id) [Pane] \(.terminal_title_stripped // "Pane \(.pane_id)") (Tab: \($tab_map[.tab_id].label // "Unknown"), Workspace: \($ws_map[$tab_map[.tab_id].ws_id] // "Unknown"))")
')

# Pass to fzf
# We hide the first 3 fields (<type> <id> <focus_id>) using --with-nth=4..
SELECTED=$(awk 'NF' <<< "$COMBINED" | fzf --with-nth=4.. --prompt="Search Herdr > " --ansi)

# Exit if nothing selected (user pressed escape)
if [[ -z "$SELECTED" ]]; then
    exit 0
fi

# Parse selection
read -r TYPE ID FOCUS_ID _ <<< "$SELECTED"

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
