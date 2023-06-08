
---@type OpenAIInfo
local M = {}

local model_info = {
    ["gpt-3.5-turbo"] = {
        model = "gpt-3.5-turbo",
        endpoint = "/v1/chat/completions",
        max_tokens = 8192,
        price = 0.002,
    },
}

M.get_info = function(model_name)
    return model_info[model_name]
end

return M
