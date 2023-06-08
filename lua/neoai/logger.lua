---@class Logger
---@field setup function
---@field deprecation function
---@field trace function
---@field debug function
---@field info function
---@field warn function
---@field error function
---@field config Diagnostic_Options

local M = {}


local level_names = {
    [vim.log.levels.TRACE] = "TRACE",
    [vim.log.levels.DEBUG] = "DEBUG",
    [vim.log.levels.INFO] = "INFO",
    [vim.log.levels.WARN] = "WARN",
    [vim.log.levels.ERROR] = "ERROR",
}

---@param level number
---@return boolean
function should_not_log(level)
    return level < M.config.log_level
end

---@param level number
---@return boolean
function should_not_notify(level)
    return level < M.config.notification_level
end

---@param message string
---@param level number
function notify(message, level)
    if should_not_notify(level) then
        return
    end
    vim.notify(message, level, {
        title = "NeoAI",
    })
end

---@param message string
---@param level number
local function log(message, level)
    if should_not_log(level) then
        return
    end
    local log_path = M.config.log_path
    if log_path == nil then
        error("log_path is not set")
    end
    -- NOTE: Without it test fails, is any better way to achive it?
    vim.fn.mkdir(vim.fn.fnamemodify(log_path, ":h"), "p")
    local fp = assert(io.open(log_path, "a"), "Failed to open log file: " .. log_path)
    -- NOTE: Maybe it should be customizable (date or full logging msg)?
    local date = os.date("%Y-%m-%d %H:%M:%S")
    local level_name = level_names[level]
    fp:write(string.format("%s [%s] %s\n", date, level_name, message))
    fp:close()
end

---@param options Diagnostic_Options
---@return nil
M.setup = function(options)
    M.config = options
end

---@param what string
---@param instead string
M.deprecation = function(what, instead)
    notify(what .. " is deprecated, use " .. instead, vim.log.levels.WARN)
end

---@param message string
M.trace = function(message)
    notify(message, vim.log.levels.TRACE)
    log(message, vim.log.levels.TRACE)
end

---@param message string
M.debug = function(message)
    notify(message, vim.log.levels.DEBUG)
    log(message, vim.log.levels.DEBUG)
end

---@param message string
M.info = function(message)
    notify(message, vim.log.levels.INFO)
    log(message, vim.log.levels.INFO)
end

---@param message string
M.warn = function(message)
    notify(message, vim.log.levels.WARN)
    log(message, vim.log.levels.WARN)
end

---@param message string
M.error = function(message)
    notify(message, vim.log.levels.ERROR)
    log(message, vim.log.levels.ERROR)
end

return M
