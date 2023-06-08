local curl = require("plenary.curl")
local log = require("neoai.log")

local M = {}

M.models = function(api_key)
    local models = curl.get(
        {
            url = "https://api.openai.com/v1/models",
            headers = {
                content_type = "application/json",
                Authorization = "Bearer " .. api_key,
            }
        }
    )
    log.debug("Got models: " .. vim.inspect(models))
    return vim.json.decode(models).data
end
