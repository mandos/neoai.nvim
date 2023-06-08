local ui = require("neoai.ui")
local utils = require("neoai.utils")

M = {}

---Toggles opening and closing neoai window
---@param toggle boolean | nil If true will open GUI and false will close, nil will toggle
---@param prompt string | nil If set then this prompt will be sent to the GUI if toggling on
---@return boolean true if opened and false if closed
function toggle(toggle, prompt)
    local open = (toggle ~= "" and toggle) or (toggle == "" and not ui.is_open())
    if open then
        -- Open
        ui.create_ui()
        if prompt ~= nil then
            ui.send_prompt(prompt)
        end
        return true
    else
        -- Close
        ui.destroy_ui()
        return false
    end
end

---Smart focus, if closed then will open on GUI, if opened and focused then it
---will close GUI and if opened and not focused then it will focus on the GUI.
---@param prompt string The prompt to inject, to inject no prompt just do empty string
function smart_toggle(prompt)
    local send_args = function()
        if not utils.is_empty(prompt) then
            ui.send_prompt(prompt)
        end
    end
    if ui.is_open() then
        if ui.is_focused() then
            toggle(false)
        else
            ui.focus()
            send_args()
        end
    else
        toggle(true)
        send_args()
    end
end


M.setup = function()
    vim.api.nvim_create_user_command("NeoAI", function(opts)
        smart_toggle(opts.args)
    end, {
        nargs = "*",
    })
end

return M
