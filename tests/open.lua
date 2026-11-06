vim.opt.runtimepath:append(vim.fn.getcwd())

local open = require("open")
local original = {
  executable = vim.fn.executable,
  jobstart = vim.fn.jobstart,
  notify = vim.notify,
  schedule = vim.schedule,
}
local launches, notices, scheduled
local job_result = 42

local function assert_equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. "\nactual: " .. vim.inspect(actual))
end

local function reset(opener)
  launches, notices, scheduled = {}, {}, {}
  job_result = 42
  open.setup({ opener = opener or "test-open" })
end

local function assert_notice(message, level)
  assert_equal(notices, { { message, level } }, "notification")
end

local ok, err = xpcall(function()
  vim.fn.executable = function(command)
    return command == "test-open" and 1 or 0
  end
  vim.fn.jobstart = function(command, opts)
    table.insert(launches, { command = command, opts = opts })
    return job_result
  end
  vim.notify = function(message, level)
    table.insert(notices, { message, level })
  end
  vim.schedule = function(callback)
    table.insert(scheduled, callback)
  end

  reset()
  open.open("")
  assert_equal(#launches, 0, "empty target never launches")
  assert_notice("open.nvim: nothing to open", vim.log.levels.WARN)

  reset()
  open.open('(""),')
  assert_equal(#launches, 0, "punctuation-only target never launches")
  assert_notice("open.nvim: nothing to open after cleanup", vim.log.levels.WARN)

  reset("missing-opener")
  open.open("https://example.com")
  assert_equal(#launches, 0, "missing opener never launches")
  assert_notice("open.nvim: opener not found", vim.log.levels.ERROR)

  reset({ "test-open", "--new-window" })
  local target = (os.getenv("HOME") or "") .. "/my notes.txt"
  open.open('("~/my notes.txt"),')
  assert_equal(#launches, 1, "exactly one launch")
  assert_equal(launches[1].command, { "test-open", "--new-window", target }, "clean expanded target is one argument")
  assert_equal(launches[1].opts.detach, true, "opener is detached")
  assert_equal(open._private.get_opener(), { "test-open", "--new-window" }, "configured command is not mutated")
  assert_notice("Opening: " .. target, vim.log.levels.INFO)

  for _, result in ipairs({ 0, -1 }) do
    reset()
    job_result = result
    open.open("https://example.com")
    assert_equal(#launches, 1, "failed launch attempted once")
    assert_notice("open.nvim: failed to start opener", vim.log.levels.ERROR)
  end

  reset()
  open.open("https://example.com")
  notices = {}
  local on_stderr = launches[1].opts.on_stderr
  on_stderr(42, { "", "  ", "" })
  assert_equal(#scheduled, 0, "blank stderr does not schedule a notification")
  assert_equal(#notices, 0, "blank stderr is silent")
  on_stderr(42, { "  cannot open", "permission denied  ", "" })
  assert_equal(#scheduled, 1, "stderr notification is scheduled")
  assert_equal(#notices, 0, "stderr notification waits for main loop")
  scheduled[1]()
  assert_notice("open.nvim: cannot open\npermission denied", vim.log.levels.ERROR)
end, debug.traceback)

vim.fn.executable = original.executable
vim.fn.jobstart = original.jobstart
vim.notify = original.notify
vim.schedule = original.schedule
open.setup()
assert(ok, err)
print("open lifecycle tests passed (7 cases)")
