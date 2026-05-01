# AGENTS.md

AI agent guide for working in open.nvim.

## Project Overview

**open.nvim** is a minimal Neovim plugin that opens the word under cursor (or visual selection) using the system opener. Cross-platform: macOS, Linux, WSL, Windows.

- **Language**: Lua (Neovim plugin)
- **Requirements**: Neovim >= 0.9
- **Author**: Tai Groot (taigrr)

## Directory Structure

```
lua/open/
└── init.lua      # Main module: setup, word detection, open command
```

## Key Concepts

### Word Detection

Gets whitespace-delimited word under cursor, strips surrounding quotes/brackets/parens, expands `~`, passes to system opener.

### Visual Selection

Supports visual mode — select text and open it.

### Platform Detection

Auto-detects opener: `open` (macOS), `xdg-open` (Linux), `wslview` (WSL), `start` (Windows). Configurable via `opener` option.

### Commands

| Command            | Mode   | Description                    |
| ------------------ | ------ | ------------------------------ |
| `:OpenUnderCursor` | Normal | Open word under cursor         |
| `:OpenVisual`      | Visual | Open visual selection          |

## Configuration

```lua
require("open").setup({
  opener = nil,              -- Auto-detect (or set custom command)
  keymap = { open = "gx" },  -- Optional keymap (normal + visual)
})
```

## Testing

Automated headless tests live in `tests/run.lua`:

```bash
nvim --headless -u NONE -c "set rtp+=." -l tests/run.lua
```

Manual smoke testing is still useful:

```lua
-- In Neovim:
:luafile %           -- Reload current file
:OpenUnderCursor     -- Test with cursor on URL or path
```

## Code Conventions

### Module Pattern

```lua
local M = {}
function M.public_fn() end
return M
```

### Type Annotations

Uses LuaCATS (`---@param`, `---@return`) for type hints.

## API Reference

Main module (`require("open")`):

- `setup(opts)` - Create user commands, optional keymaps
- `open_under_cursor()` - Open word under cursor
- `open_visual()` - Open visual selection
- `open(target)` - Open any string
