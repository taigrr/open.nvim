local M = {}

--- Default configuration
---@type table
local config = {
  --- Custom opener command (auto-detected if nil)
  ---@type string|string[]|nil
  opener = nil,
  --- Keymaps to set up (nil = no keymaps)
  ---@type table|nil
  keymap = nil,
}

--- Detect the system opener command
---@return string|string[]
local function detect_opener()
  local uname = vim.loop.os_uname()
  local sysname = uname.sysname

  if sysname == "Darwin" then
    return "open"
  elseif sysname == "Linux" then
    -- Check for WSL
    if uname.release and uname.release:match("[Mm]icrosoft") then
      return "wslview"
    end
    return "xdg-open"
  elseif sysname:match("^Windows") or sysname:match("^MINGW") or sysname:match("^MSYS") then
    return { "cmd.exe", "/c", "start", "" }
  end

  -- Fallback: try xdg-open
  return "xdg-open"
end

--- Get the opener command (user-configured or auto-detected)
---@return string|string[]
local function get_opener()
  return config.opener or detect_opener()
end

--- Normalize opener into a jobstart command list.
---@param opener string|string[]
---@param target string
---@return string[]
local function build_open_command(opener, target)
  if type(opener) == "table" then
    local command = vim.deepcopy(opener)
    table.insert(command, target)
    return command
  end

  return { opener, target }
end

--- Check whether the opener executable is available.
---@param opener string|string[]
---@return boolean
local function opener_exists(opener)
  local executable = type(opener) == "table" and opener[1] or opener
  if not executable or executable == "" then
    return false
  end

  if executable:match("[/\\]") then
    return vim.loop.fs_stat(executable) ~= nil
  end

  return vim.fn.executable(executable) == 1
end

--- Get the word under cursor (whitespace delimited)
---@return string
local function get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Find start of word (non-whitespace)
  local start_col = col
  while start_col > 1 and not line:sub(start_col - 1, start_col - 1):match("%s") do
    start_col = start_col - 1
  end

  -- Find end of word (non-whitespace)
  local end_col = col
  while end_col <= #line and not line:sub(end_col, end_col):match("%s") do
    end_col = end_col + 1
  end

  return line:sub(start_col, end_col - 1)
end

--- Get visually selected text
---@return string
local function get_visual_selection()
  -- Exit visual mode to set '< and '> marks
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)

  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")
  local start_row, start_col = start_pos[1], start_pos[2]
  local end_row, end_col = end_pos[1], end_pos[2]

  if start_row ~= end_row then
    -- Multi-line: join with spaces
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    if #lines == 0 then
      return ""
    end
    lines[1] = lines[1]:sub(start_col + 1)
    lines[#lines] = lines[#lines]:sub(1, end_col + 1)
    return table.concat(lines, " ")
  end

  local line = vim.api.nvim_buf_get_lines(0, start_row - 1, start_row, false)[1]
  if not line then
    return ""
  end
  return line:sub(start_col + 1, end_col + 1)
end

--- Clean up surrounding punctuation from a word
---@param word string
---@return string
local function clean_word(word)
  -- Strip common surrounding characters like quotes, parens, brackets, commas
  word = word:gsub("^[%[%]()<>\"',`]+", ""):gsub("[%[%]()<>\"',`]+$", "")

  -- Strip trailing punctuation that's unlikely part of a URL/path
  word = word:gsub("[%.;:]+$", "")

  return word
end

--- Expand ~ to home directory
---@param word string
---@return string
local function expand_home(word)
  if word:sub(1, 1) == "~" then
    local home = os.getenv("HOME") or ""
    word = home .. word:sub(2)
  end
  return word
end

--- Open a target string using the system opener
---@param target string
function M.open(target)
  if target == "" then
    vim.notify("open.nvim: nothing to open", vim.log.levels.WARN)
    return
  end

  target = clean_word(target)
  target = expand_home(target)

  if target == "" then
    vim.notify("open.nvim: nothing to open after cleanup", vim.log.levels.WARN)
    return
  end

  local opener = get_opener()
  if not opener_exists(opener) then
    vim.notify("open.nvim: opener not found", vim.log.levels.ERROR)
    return
  end

  local command = build_open_command(opener, target)
  local job = vim.fn.jobstart(command, {
    detach = true,
    on_stderr = function(_, data)
      local msg = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
      if msg ~= "" then
        vim.schedule(function()
          vim.notify("open.nvim: " .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })

  if job <= 0 then
    vim.notify("open.nvim: failed to start opener", vim.log.levels.ERROR)
    return
  end

  vim.notify("Opening: " .. target, vim.log.levels.INFO)
end

--- Open the word under cursor using system opener
function M.open_under_cursor()
  local word = get_word_under_cursor()
  M.open(word)
end

--- Open visual selection using system opener
function M.open_visual()
  local selection = get_visual_selection()
  M.open(selection)
end

--- Setup function
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  config = vim.tbl_deep_extend("force", config, opts)

  -- Create user commands
  vim.api.nvim_create_user_command("OpenUnderCursor", M.open_under_cursor, {
    desc = "Open word under cursor with system opener",
  })

  vim.api.nvim_create_user_command("OpenVisual", function()
    M.open_visual()
  end, {
    range = true,
    desc = "Open visual selection with system opener",
  })

  -- Set up keymaps if configured
  if opts.keymap then
    local key = opts.keymap.open or opts.keymap[1]
    if key then
      vim.keymap.set("n", key, M.open_under_cursor, {
        desc = "Open under cursor",
        silent = true,
      })
      vim.keymap.set("v", key, ":<C-u>OpenVisual<CR>", {
        desc = "Open visual selection",
        silent = true,
      })
    end
  end
end

M._private = {
  build_open_command = build_open_command,
  clean_word = clean_word,
  detect_opener = detect_opener,
  expand_home = expand_home,
  opener_exists = opener_exists,
}

return M
