# open.nvim

Open the word under cursor with macOS `open` command.

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

## Requirements

- Neovim >= **0.9.0**
- macOS (uses `open` command)

## Usage

```vim
:OpenUnderCursor
```

Opens URLs, file paths, or any text under cursor using the system `open` command.

## API

```lua
local open = require("open")

open.setup()                -- Create :OpenUnderCursor command
open.open_under_cursor()    -- Open word under cursor
```

## License

[0BSD](LICENSE) © [Tai Groot](https://github.com/taigrr)
