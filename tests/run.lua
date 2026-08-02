vim.opt.runtimepath:append(vim.fn.getcwd())

local open = require("open")
local private = open._private

local function assert_equal(actual, expected, label)
  if not vim.deep_equal(actual, expected) then
    error(
      (label or "assert_equal failed") .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
    )
  end
end

local function assert_truthy(value, label)
  if not value then
    error(label or "expected truthy value")
  end
end

assert_equal(
  private.clean_word('("https://example.com/path"),'),
  "https://example.com/path",
  "clean_word strips wrappers"
)
assert_equal(private.clean_word("~/notes.txt..."), "~/notes.txt", "clean_word strips trailing punctuation")
assert_equal(private.expand_home("~/notes.txt"), (os.getenv("HOME") or "") .. "/notes.txt", "expand_home expands tilde")

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha beta", "gamma delta" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
assert_equal(private.get_word_under_cursor(), "alpha", "get_word_under_cursor reads current token")
vim.api.nvim_win_set_cursor(0, { 1, 5 })
assert_equal(private.get_word_under_cursor(), "", "get_word_under_cursor ignores whitespace")
vim.api.nvim_win_set_cursor(0, { 1, 6 })
assert_equal(private.get_word_under_cursor(), "beta", "get_word_under_cursor reads following token")

vim.api.nvim_buf_set_mark(0, "<", 1, 6, {})
vim.api.nvim_buf_set_mark(0, ">", 1, 9, {})
assert_equal(private.get_visual_selection(), "beta", "get_visual_selection reads single-line marks")
vim.api.nvim_buf_set_mark(0, "<", 1, 6, {})
vim.api.nvim_buf_set_mark(0, ">", 2, 4, {})
assert_equal(private.get_visual_selection(), "beta gamma", "get_visual_selection joins multi-line marks")
vim.api.nvim_buf_set_mark(0, "<", 2, 4, {})
vim.api.nvim_buf_set_mark(0, ">", 1, 6, {})
assert_equal(private.get_visual_selection(), "beta gamma", "get_visual_selection normalizes reversed marks")

assert_equal(
  private.build_open_command("xdg-open", "https://example.com"),
  { "xdg-open", "https://example.com" },
  "build_open_command handles string opener"
)
assert_equal(
  private.build_open_command({ "cmd.exe", "/c", "start", "" }, "https://example.com?a=1&b=2"),
  { "cmd.exe", "/c", "start", "", '"https://example.com?a=1&b=2"' },
  "build_open_command quotes Windows start targets"
)
assert_equal(
  private.build_open_command({ "cmd.exe", "/c" }, "https://example.com"),
  { "cmd.exe", "/c", "https://example.com" },
  "build_open_command tolerates short cmd.exe opener lists"
)
assert_equal(
  private.build_open_command({ "python", "-m", "webbrowser" }, "https://example.com"),
  { "python", "-m", "webbrowser", "https://example.com" },
  "build_open_command preserves generic list opener args"
)

local detect_cases = {
  {
    name = "darwin",
    uname = { sysname = "Darwin", release = "23.0.0" },
    expected = "open",
  },
  {
    name = "linux",
    uname = { sysname = "Linux", release = "6.8.0" },
    expected = "xdg-open",
  },
  {
    name = "wsl",
    uname = { sysname = "Linux", release = "5.15.153.1-microsoft-standard-WSL2" },
    expected = "wslview",
  },
  {
    name = "windows",
    uname = { sysname = "Windows_NT", release = "10.0.22631" },
    expected = { "cmd.exe", "/c", "start", "" },
  },
}

local original_os_uname = vim.loop.os_uname
for _, case in ipairs(detect_cases) do
  vim.loop.os_uname = function()
    return case.uname
  end
  assert_equal(private.detect_opener(), case.expected, "detect_opener " .. case.name)
end
vim.loop.os_uname = original_os_uname

assert_truthy(private.opener_exists("sh"), "opener_exists detects available binary")
assert_equal(private.opener_exists("definitely-not-a-real-open-command"), false, "opener_exists rejects missing binary")

open.setup({ keymap = { open = "gx" } })
assert_truthy(vim.fn.exists(":OpenUnderCursor") == 2, "OpenUnderCursor command exists")
assert_truthy(vim.fn.exists(":OpenVisual") == 2, "OpenVisual command exists")
assert_truthy(vim.fn.maparg("gx", "n") ~= "", "normal mode keymap is installed")
assert_equal(vim.fn.maparg("gx", "v"), ":<C-U>OpenVisual<CR>", "visual mode keymap is installed")

open.setup({ opener = "custom-open" })
assert_equal(private.get_opener(), "custom-open", "setup applies custom opener")
open.setup()
assert_equal(private.get_opener(), private.detect_opener(), "setup resets opener to default")

print("tests passed")
