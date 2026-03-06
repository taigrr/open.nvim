# AGENTS.md

AI agent guide for working in open.nvim.

## Project Overview

**open.nvim** is a minimal Neovim plugin that opens the word under cursor using macOS `open` command. Useful for opening URLs, file paths, or any text that `open` can handle.

- **Language**: Lua (Neovim plugin)
- **Requirements**: Neovim >= 0.9, macOS
- **Author**: Tai Groot (taigrr)

## Directory Structure

```
lua/open/
└── init.lua      # Main module: setup, word detection, open command
```

## Key Concepts

### Word Detection

Gets whitespace-delimited word under cursor, strips surrounding quotes/brackets/parens, passes to `open` command.

### Commands

| Command            | Description                    |
| ------------------ | ------------------------------ |
| `:OpenUnderCursor` | Open word under cursor         |

## Testing

**No automated tests.** Manual testing:

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

- `setup(opts)` - Create user command
- `open_under_cursor()` - Open word under cursor
