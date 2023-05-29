local log = require('neoai.logger')
local assert = require('luassert')
local spy = require('luassert.spy')
local levels = vim.log.levels
local say = require("say")

local log_path = vim.fn.stdpath("log") .. "/neoai.log"

-- Helper function to check if log file exists
local function logfile_exists(state, arguments)
    -- assert.equals({}, state)
    if vim.loop.fs_statfs(arguments[1]) then
        return true
    else
        return false
    end
end
say:set("assertion.logfile_exists.positive", "Expected logfile (path: %s) to exists")
say:set("assertion.logfile_exists.negative", "Expected logfile (path: %s) to not exists")
assert:register("assertion", "logfile_exists", logfile_exists, "assertion.logfile_exists.positive",
    "assertion.logfile_exists.negative")

--- Helper function to clear log files and setup logger
---@param with_defaults boolean?
---@param options Diagnostic_Options?
local function setup_config(with_defaults, options)
    vim.cmd("silent! !rm -rf " .. vim.fn.stdpath("log") .. "/*")
    options = options or {}
    if with_defaults then
        options = vim.tbl_deep_extend("force", require('neoai.config').get_defaults().diagnostic, options)
    end
    log.setup(options)
end


describe("Logger", function()
    describe("with default settings", function()
        before_each(function()
            setup_config(true)
        end)

        it("should show notification with INFO and above", function()
            vim.notify = spy.new(function(msg, level, opts)
            end)
            log.trace("trace message")
            log.debug("debug message")
            log.info("info message")
            log.warn("warning message")
            log.error("error message")
            assert.spy(vim.notify).was_called(3)
            assert.spy(vim.notify).was_called_with("info message", levels.INFO, {
                title = "NeoAI",
            })
            assert.spy(vim.notify).was_called_with("warning message", levels.WARN, {
                title = "NeoAI",
            })
            assert.spy(vim.notify).was_called_with("error message", levels.ERROR, {
                title = "NeoAI",
            })
        end)


        it("should not log to logfile", function()
            log.debug("debug message")
            log.info("info message")
            log.error("error message")
            assert.is_not_logfile_exists(vim.fn.stdpath("log") .. "/neoai.log")
        end)
    end)

    it("should show deprecated message as warning", function()
        vim.notify = spy.new(function(msg, level, opts)
        end)
        log.deprecation("old", "new")
        assert.spy(vim.notify).was_called(1)
        assert.spy(vim.notify).was_called_with("old is deprecated, use new", levels.WARN, {
            title = "NeoAI",
        })
    end)

    describe("with set log level to INFO, and logging to file enabled", function()
        before_each(function()
            setup_config(false, {
                notification_level = levels.OFF,
                log_level = levels.INFO,
                log_path = log_path,
            })
        end)

        it("should created log file", function()
            assert.is_not_logfile_exists(log_path)
            assert.is_not_logfile_exists(log_path)
            log.debug("debug message")
            log.info("info message")
            log.error("error message")
            assert.is_logfile_exists(log_path)
        end)

        it("should have messages with levels INFO and above", function()
            assert.is_not_logfile_exists(log_path)
            log.debug("debug message")
            log.info("info message")
            log.error("error message")

            local fp = assert(io.open(log_path, "r"), "Failed to open log file: .. " .. log_path)
            local content = fp:read("*a")
            assert.is_true(content:match("debug message") == nil, "debug message should not be logged")
            assert.is_true(content:match("info message") ~= nil, "info message should be logged")
            assert.is_true(content:match("error message") ~= nil, "error message should be logged")
            fp:close()
        end)

        it("should log message with timestamp and level information", function()
            assert.is_not_logfile_exists(log_path)
            -- I don't care about the exact time, just make sure it's in the right format
            os.date = function() return "1999-10-19 20:10:05" end
            log.info("info message")
            local fp = assert(io.open(log_path, "r"), "Failed to open log file: .. " .. log_path)
            local content = fp:read("*a")
            assert.equal("1999-10-19 20:10:05 [INFO] info message\n", content)
        end)
    end)
end)
