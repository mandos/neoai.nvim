local info = require("neoai.openai.info")
local assert = require("luassert")

describe("OpenAI info module", function()
    it("should return correct info for gpt-3.5-turbo", function()
        local expected_info = {
            model = "gpt-3.5-turbo",
            endpoint = "/v1/chat/completions",
            max_tokens = 8192,
            price = 0.002,
        }

        assert.same(expected_info, info.get_info("gpt-3.5-turbo"))
    end)
end)
