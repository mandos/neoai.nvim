local commands = require('neoai.commands')
-- local assert = require('luassert')
-- local spy = require('luassert.spy')
-- local levels = vim.log.levels
-- local say = require("say")


describe("Commands", function()
    describe("should be setuped without error", function()
        commands.setup()
    end)
end)


-- describe("Command", function()
--     describe("NeoAI should have 3 subcommand", function()
--         commands.setup()
--         local subcommands = commands.subcommands
--         assert.are.equal(3, #subcommands)
--     end)
-- end)
