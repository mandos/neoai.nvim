local log = require("neoai.logger")
local config = require("neoai.config")
local curl = require("plenary.curl")
local utils = require("neoai.utils")

---@class OpenAIModel
---OpenAIModel is a model that uses the OpenAI API to send and recieve messages
---@field name string
---@field get_current_output fun(): string Get's current output of the model
---@field send_to_model fun(chat_history: ChatHistory, on_stdout_chunk: fun(chunk: string), on_complete: fun(err?: string, output?: string)) Sends chat_history to the model

local M = {}
M.name = "OpenAI"

local handler
local chunks = {}
local raw_chunks = {}

---@brief Cancel the current stream and shut down the handler
M.cancel_stream = function()
  if handler ~= nil then
    handler:shutdown()
    handler = nil
  end
end

M.get_current_output = function()
	return table.concat(chunks, "")
end

---@param chunk string
---@param on_stdout_chunk fun(chunk: string) Function to call whenever a stdout chunk occurs
M._receive_chunk = function(chunk, on_stdout_chunk)
	local function safely_extract_delta_content(decoded_json)
		local path = decoded_json.choices
		if not path then
			return nil
		end

		path = path[1]
		if not path then
			return nil
		end

		path = path.delta
		if not path then
			return nil
		end

		return path.content
	end
	-- Remove "data:" prefix from chunk
	local raw_json = string.gsub(chunk, "%s*data:%s*", "")
	table.insert(raw_chunks, raw_json)

	local ok, decoded_json = pcall(vim.json.decode, raw_json)
	if not ok then
		return -- Ignore invalid JSON chunks
	end

	local delta_content = safely_extract_delta_content(decoded_json)
	if delta_content then
		table.insert(chunks, delta_content)
		on_stdout_chunk(delta_content)
	end
end

---@param chat_history ChatHistory
---@param on_stdout_chunk fun(chunk: string) Function to call whenever a stdout chunk occurs
---@param on_complete fun(err?: string, output?: string) Function to call when model has finished
M.send_to_model = function(chat_history, on_stdout_chunk, on_complete)
    local api_key = config.options.open_ai.api_key.get()

	local data = {
		model = chat_history.model,
		stream = true,
		messages = chat_history.messages,
	}
	data = vim.tbl_deep_extend("force", {}, data, chat_history.params)

    chunks = {}
    raw_chunks = {}
    log.debug("Sending to OpenAI: " .. vim.inspect(data))
    utils.exec("curl", {
        "--silent",
        "--show-error",
        "--no-buffer",
        "https://api.openai.com/v1/chat/completions",
        "-H",
        "Content-Type: application/json",
        "-H",
        "Authorization: Bearer " .. api_key,
        "-d",
        vim.json.encode(data),
    }, function(chunk)
        M._recieve_chunk(chunk, on_stdout_chunk)
    end, function(err, _)
        local total_message = table.concat(raw_chunks, "")
        local ok, json = pcall(vim.json.decode, total_message)
        if ok then
            if json.error ~= nil then
                on_complete(json.error.message, nil)
                log.error(json.error)
                return
            end
        end
        on_complete(err, M.get_current_output())
    end)
end

return M
