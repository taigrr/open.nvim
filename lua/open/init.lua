local M = {}

--- Get the word under cursor (whitespace delimited)
---@return string
local function get_word_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- Find start of word (non-whitespace)
  local start_col = col
  while start_col > 1 and not line:sub(start_col - 1, start_col - 1):match('%s') do
    start_col = start_col - 1
  end

  -- Find end of word (non-whitespace)
  local end_col = col
  while end_col <= #line and not line:sub(end_col, end_col):match('%s') do
    end_col = end_col + 1
  end

  return line:sub(start_col, end_col - 1)
end

--- Open the word under cursor using system `open` command
function M.open_under_cursor()
  local word = get_word_under_cursor()
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  -- Strip common surrounding characters like quotes, parens, brackets
  word = word:gsub('^[%[%]()<>"\']', ''):gsub('[%[%]()<>"\']$', '')

  vim.fn.jobstart({ 'open', word }, { detach = true })
  vim.notify('Opening: ' .. word, vim.log.levels.INFO)
end

--- Setup function for lazy.nvim
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  -- Create user command
  vim.api.nvim_create_user_command('OpenUnderCursor', M.open_under_cursor, {
    desc = 'Open word under cursor with system open command',
  })
end

return M
