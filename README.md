# open.nvim

Open the word under cursor (or visual selection) with your system opener.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "taigrr/open.nvim",
  config = function()
    require("open").setup()
  end,
}
```

With keymap:

```lua
{
  "taigrr/open.nvim",
  config = function()
    require("open").setup({
      keymap = { open = "gx" },
    })
  end,
}
```

## Requirements

- Neovim >= **0.9.0**

## Platform Support

The opener command is auto-detected:

| Platform     | Command                    |
| ------------ | -------------------------- |
| macOS        | `open`                     |
| Linux        | `xdg-open`                 |
| WSL          | `wslview`                  |
| Windows      | `cmd.exe /c start "" ...` |

Override with `opener` option:

```lua
require("open").setup({
  opener = "/usr/bin/xdg-open",
})
```

## Usage

### Commands

| Command            | Mode     | Description                    |
| ------------------ | -------- | ------------------------------ |
| `:OpenUnderCursor` | Normal   | Open word under cursor         |
| `:OpenVisual`      | Visual   | Open visual selection          |

### API

```lua
local open = require("open")

open.setup()              -- Create commands
open.open_under_cursor()  -- Open word under cursor
open.open_visual()        -- Open visual selection
open.open("https://...")  -- Open any string
```

## What Gets Opened

The plugin grabs the whitespace-delimited word under cursor (or visual selection), strips surrounding punctuation (quotes, brackets, parens), expands `~` to home, and passes it to the system opener. Works with:

- URLs (`https://github.com/taigrr/open.nvim`)
- File paths (`~/Documents/notes.txt`)
- Anything your system opener handles

## Testing

Run the headless test suite:

```bash
nvim --headless -u NONE -c "set rtp+=." -l tests/run.lua
```

The tests cover opener detection, command building, command registration, and visual-mode keymap setup.

## License

[0BSD](LICENSE) © [Tai Groot](https://github.com/taigrr)
