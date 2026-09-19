# Herdr Global Search 🔍

A fast, `fzf`-powered fuzzy finder for Herdr. 

When you have multiple AI agents working simultaneously across different workspaces, tabs, and panes, losing track of where a specific task is running is common. This plugin solves that by indexing all active Herdr contexts and allowing you to fuzzy-search them.

## Features
- **Cross-environment indexing:** Searches across Workspaces, Tabs, and Panes natively using `herdr <resource> list`.
- **Instant navigation:** Hitting `Enter` on a result automatically fires `herdr workspace focus` and `herdr tab focus` to teleport you directly to that pane.
- **Floating UI:** Renders cleanly as a centered `placement = "popup"` pane over your current work.

## Requirements
- `herdr` CLI
- `jq` (for parsing the socket API responses)
- `fzf` (for the fuzzy search interface)

## Installation

1. Install the plugin directly from GitHub:
   ```bash
   herdr plugin install <username>/herdr-global-search
   ```

2. Add the keybinding to your `~/.config/herdr/config.toml`:
   ```toml
   [[keys.command]]
   key = "prefix+f"
   type = "plugin_action"
   command = "alevsk.global-search.trigger-search"
   description = "Global Search"
   ```

3. Reload the Herdr server:
   ```bash
   herdr server reload-config
   ```

## Usage
Press `prefix+f` (or your configured keybinding) to open the search popup. Type to filter, use arrow keys to select, and hit `Enter` to jump.
