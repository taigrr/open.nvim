vim.opt.runtimepath:append(vim.fn.getcwd())

local private = require("open")._private
local uv = vim.uv or vim.loop
local directory = vim.fn.tempname() .. " opener paths"
vim.fn.mkdir(directory, "p")
local executable = directory .. "/open tool"
vim.fn.writefile({ "#!/bin/sh", "exit 0" }, executable)

local ok, failure = pcall(function()
  assert(not private.opener_exists(directory), "directories are not executable openers")
  assert(not private.opener_exists(executable), "non-executable files are not openers")
  assert(not private.opener_exists({ executable, "--flag" }), "list openers require an executable file")
  assert(not private.opener_exists(directory .. "/missing"), "missing paths are not openers")

  assert(uv.fs_chmod(executable, 493)) -- 0755
  assert(private.opener_exists(executable), "executable paths with spaces are valid openers")
  assert(private.opener_exists({ executable, "--flag" }), "list openers support executable paths")
end)

vim.fn.delete(directory, "rf")
if not ok then
  error(failure)
end
print("opener path tests passed")
