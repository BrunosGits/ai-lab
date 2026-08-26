-- Area 25: Localization/Strings — Busted Test Templates
-- Follows patterns from CorsixTH/Luatest/spec/

require("class_test_base")

-- Mock TH module for LoadStrings
local TH_mock = {
  LoadStrings = function(data) return {} end,
  stringProxy = setmetatable({}, {
    __call = function(_, str, func, ...)
      return setmetatable({}, {
        __index = function(_, k)
          if k == "_unwrap" then return function(s) return s, false end end
          return rawget(TH_mock.stringProxy, k)
        end
      })
    end,
  }),
}
TH_mock.stringProxy._unwrap = function(s) return s, false end

describe("Strings", function()
  local Strings_class

  setup(function()
    _G["TH"] = TH_mock
    Strings_class = _G["Strings"]
  end)

  describe("constructor", function()
    it("should store app reference", function()
      local mock_app = { config = { language = "English" } }
      local s = Strings_class(mock_app)
      assert.is_equal(mock_app, s.app)
    end)
  end)

  describe("getLangCode", function()
    it("should return the language code for a known language", function()
      local mock_app = { config = { language = "English" } }
      local s = Strings_class(mock_app)
      -- After init, language_to_lang_code would be populated.
      -- For this test, manually set it:
      s.language_to_lang_code = { english = "en" }
      assert.equals("en", s:getLangCode("English"))
    end)

    it("should fall back to config.language when no argument", function()
      local mock_app = { config = { language = "English" } }
      local s = Strings_class(mock_app)
      s.language_to_lang_code = { english = "en" }
      assert.equals("en", s:getLangCode())
    end)
  end)

  describe("checkLanguageExists", function()
    it("should return true for a registered language", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      s.language_to_chunk = { english = function() end }
      assert.is_true(s:checkLanguageExists("English"))
    end)

    it("should return false for an unknown language", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      s.language_to_chunk = {}
      assert.is_falsy(s:checkLanguageExists("Klingon"))
    end)
  end)

  describe("isArabicNumerals", function()
    it("should return true when language uses Arabic numerals", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      s.languages_with_arabic_numerals = { arabic = true }
      assert.is_true(s:isArabicNumerals("Arabic"))
    end)

    it("should return nil for languages without Arabic numerals", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      s.languages_with_arabic_numerals = {}
      assert.is_nil(s:isArabicNumerals("English"))
    end)
  end)

  describe("getFont", function()
    it("should return font declaration for a language with one", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      local fake_chunk = function() end
      s.language_to_chunk = { english = fake_chunk }
      s.chunk_to_font = { [fake_chunk] = "GoNotoCJK.ttf" }
      assert.equals("GoNotoCJK.ttf", s:getFont("English"))
    end)

    it("should return nil for language without font", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      s.language_to_chunk = { english = function() end }
      s.chunk_to_font = {}
      assert.is_nil(s:getFont("English"))
    end)
  end)

  describe("getLanguageNames", function()
    it("should return the names array for a known language", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      local fake_chunk = function() end
      s.language_to_chunk = { french = fake_chunk }
      s.chunk_to_names = { [fake_chunk] = { "French", "Francais", "fr" } }
      local names = s:getLanguageNames("French")
      assert.same({ "French", "Francais", "fr" }, names)
    end)
  end)

  describe("getLocalisedText", function()
    it("should return string directly when table is nil", function()
      local mock_app = { config = { language = "english" } }
      local s = Strings_class(mock_app)
      assert.equals("fallback", s:getLocalisedText("fallback", nil))
    end)

    it("should prefer current language over English", function()
      local mock_app = { config = { language = "english" } }
      local s = Strings_class(mock_app)
      s.language_to_lang_code = { english = "en" }
      local texts = { en = "English text", fr = "Texte francais" }
      assert.equals("English text", s:getLocalisedText("default", texts))
    end)
  end)

  describe("setupAdviserMessage", function()
    it("should return a table with text and priority", function()
      local mock_app = { config = {} }
      local s = Strings_class(mock_app)
      local messages = { some_key = "Hello" }
      local msg = s:setupAdviserMessage(messages)
      assert.is_table(msg)
      assert.is_table(msg.text)
      assert.is_number(msg.priority)
    end)
  end)
end)

-- Test string proxy format (from string_extensions.lua)
describe("TH.stringProxy.format", function()
  it("should exist as a function", function()
    assert.is_function(TH_mock.stringProxy.format)
  end)
end)
