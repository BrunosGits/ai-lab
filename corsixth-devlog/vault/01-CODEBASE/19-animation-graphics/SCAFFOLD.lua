-- Busted Test Scaffold for CorsixTH Graphics System
-- Place in: spec/graphics_spec.lua or run with: busted spec/graphics_spec.lua

local busted = require("busted")
local describe = busted.describe
local it = busted.it
local before_each = busted.before_each
local after_each = busted.after_each
local setup = busted.setup
local teardown = busted.teardown
local assert = require("luassert")
local spy = require("luassert.spy")
local mock = require("luassert.mock")

-- ============================================================
-- MOCK HELPERS
-- ============================================================

local function createMockApp()
  return {
    config = {
      use_new_graphics = false,
      new_graphics_folder = nil,
      unicode_font = nil,
      ui_scale = 1.0,
      cursor_scale = 1.0,
    },
    video = mock(render_target), -- Will be mocked per-test
    readDataFile = function(self, dir, name)
      -- Return dummy data for testing
      if name:match("%.pal$") or name:match("%.pl8$") then
        return string.rep("\0", 768) -- 256 * 3 bytes
      elseif name:match("%.dat$") then
        return string.rep("\0", 640 * 480)
      elseif name:match("%.tab$") then
        return string.rep("\0", 100 * 6) -- 100 sprites * 6 bytes
      elseif name:match("%.ani$") then
        return string.rep("\0", 200 * 10) -- 200 frames * 10 bytes
      end
      return ""
    end,
    getFullPath = function(self, subdir, is_dir)
      return "/fake/path/" .. (subdir or "") .. (is_dir and "/" or "")
    end,
    saveConfig = function() end,
    strings = {
      isArabicNumerals = function() return false end
    },
  }
end

local function createMockRenderTarget()
  return {
    get_width = function() return 800 end,
    get_height = function() return 600 end,
    get_scaled_width = function() return 800 end,
    get_scaled_height = function() return 600 end,
    draw = function() end,
    fill_rect = function() end,
    create_palettized_texture = function() return mock(SDL_Texture) end,
    create_texture = function() return mock(SDL_Texture) end,
    should_scale_bitmaps = function() return false end,
    draw_scale = function() return 1.0 end,
    push_clip_rect = function() end,
    pop_clip_rect = function() end,
    start_frame = function() return true end,
    end_frame = function() return true end,
  }
end

local function createMockSpriteSheet()
  return {
    get_sprite_count = function() return 100 end,
    get_sprite_size = function(self, idx, w, h) w[0] = 32; h[0] = 32; return true end,
    get_sprite_size_unchecked = function(self, idx, w, h) w[0] = 32; h[0] = 32 end,
    draw_sprite = function() end,
    set_palette = function() end,
    set_sprite_count = function() return true end,
    load_from_th_file = function() return true end,
    set_sprite_data = function() return true end,
    set_sprite_alt_palette_map = function() end,
    is_sprite_visible = function() return true end,
    wx_draw_sprite = function() end,
  }
end

local function createMockAnimationManager()
  return {
    set_sprite_sheet = function() end,
    load_from_th_file = function() return true end,
    set_canvas = function() end,
    load_custom_animations = function() return true end,
    get_animation_count = function() return 50 end,
    get_frame_count = function() return 200 end,
    get_first_frame = function(self, anim) return anim * 4 end,
    get_next_frame = function(self, frame) return frame + 1 end,
    set_animation_alt_palette_map = function() end,
    draw_frame = function() end,
    get_frame_extent = function() end,
    get_frame_sound = function() return 0 end,
    hit_test = function() return false end,
    set_frame_primary_marker = function() return true end,
    set_frame_secondary_marker = function() return true end,
    get_frame_primary_marker = function() return true end,
    get_frame_secondary_marker = function() return true end,
    get_named_animations = function() return {north=-1,east=-1,south=-1,west=-1} end,
    tick = function() end,
  }
end

local function createMockPalette()
  return {
    get_argb_data = function() 
      local t = {}
      for i=0,255 do t[i] = 0xFFFFFFFF end
      return t
    end,
    set_entry = function() return true end,
    set_argb = function() end,
  }
end

-- ============================================================
-- TEST SUITE: Graphics Class (Lua)
-- ============================================================

describe("Graphics Class", function()
  local Graphics, app, mock_video
  
  before_each(function()
    app = createMockApp()
    mock_video = createMockRenderTarget()
    app.video = mock_video
    
    -- Load the Graphics class (adjust path as needed)
    package.path = package.path .. ";../../Lua/?.lua"
    local TH = { GetBuiltinFont = function() return "", "", "" end, GetCompileOptions = function() return {font=nil} end }
    _G.TH = TH
    _G.TheApp = app
    
    -- Mock lfs
    package.loaded.lfs = {
      attributes = function(path, mode) return mode == "file" and "file" or nil end
    }
    
    -- Mock rnc
    package.loaded.rnc = { decompress = function(x) return x end }
    
    Graphics = require("graphics")
    Graphics:Graphics(app, "base", "cp437")
  end)
  
  after_each(function()
    package.loaded.graphics = nil
    package.loaded.lfs = nil
    package.loaded.rnc = nil
  end)
  
  describe("Palette Loading", function()
    it("should load base palettes on init", function()
      assert.is_not_nil(Graphics.cache.palette["bootstrap_font.pal"])
      assert.is_not_nil(Graphics.cache.palette["mainmenu1080.pal"])
    end)
    
    it("should load demo palettes for demo gfx_set", function()
      local gfx2 = Graphics:new()
      gfx2:Graphics(app, "demo", "cp437")
      assert.is_not_nil(gfx2.cache.palette["MPalette.dat"])
      assert.is_not_nil(gfx2.cache.palette["Area01V.pal"])
    end)
    
    it("should load full palettes for base gfx_set", function()
      local gfx2 = Graphics:new()
      gfx2:Graphics(app, "full", "cp437")
      assert.is_not_nil(gfx2.cache.palette["Bank01V.pal"])
      assert.is_not_nil(gfx2.cache.palette["Staff01V.pal"])
    end)
    
    it("should create greyscale ghost for each palette", function()
      local pal, ghost = Graphics:getPalette("bootstrap_font.pal")
      assert.is_string(ghost)
      assert.equal(256, #ghost)
    end)
    
    it("should cache palettes and return same instance", function()
      local pal1 = Graphics:getPalette("bootstrap_font.pal")
      local pal2 = Graphics:getPalette("bootstrap_font.pal")
      assert.equal(pal1, pal2)
    end)
    
    it("should error on missing palette", function()
      assert.has_error(function() Graphics:getPalette("nonexistent.pal") end)
    end)
  end)
  
  describe("Ghost Loading", function()
    it("should extract 256-byte ghost remap from ghost file", function()
      local ghost_data = string.rep("A", 512) -- 2 frames * 256
      app.readDataFile = function(self, dir, name) return ghost_data end
      
      local remap = Graphics:loadGhost("Data", "ghostfile", 1)
      assert.equal(256, #remap)
      assert.equal(string.rep("A", 256), remap)
    end)
  end)
  
  describe("Raw Bitmap Loading", function()
    it("should load and cache raw bitmap", function()
      local bitmap = Graphics:loadRaw("test_image", 640, 480, "QData", nil, "test.pal", false, {})
      assert.is_not_nil(bitmap)
      assert.equal(bitmap, Graphics.cache.raw["test_image"])
    end)
    
    it("should use default width/height/palette/dir", function()
      local bitmap = Graphics:loadRaw("default_test")
      assert.is_not_nil(bitmap)
    end)
    
    it("should register reload function", function()
      assert.is_not_nil(Graphics.reload_functions[bitmap])
    end)
  end)
  
  describe("Font System", function()
    it("should load builtin font", function()
      local font = Graphics:loadBuiltinFont()
      assert.is_not_nil(font)
      assert.is_true(font:isBitmap())
    end)
    
    it("should cache builtin font", function()
      local f1 = Graphics:loadBuiltinFont()
      local f2 = Graphics:loadBuiltinFont()
      assert.equal(f1, f2)
    end)
    
    it("should load bitmap font for supported charset", function()
      local sheet = createMockSpriteSheet()
      local font = Graphics:loadFont(sheet, { force_bitmap = true })
      assert.is_true(font:isBitmap())
    end)
    
    it("should create font proxy for hot-swapping", function()
      local sheet = createMockSpriteSheet()
      local font = Graphics:loadFont(sheet, {})
      assert.is_table(font)
      assert.is_function(font.sizeOf)
      assert.is_function(font.draw)
      assert.is_not_nil(font._proxy)
    end)
    
    it("should handle UI scale changes", function()
      local sheet = createMockSpriteSheet()
      local font = Graphics:loadFont(sheet, { apply_ui_scale = true })
      assert.is_not_nil(font._proxy.setScaleFactor)
    end)
    
    it("should load TrueType font when unicode needed", function()
      Graphics.ttf_font_data = "fake_ttf_data"
      Graphics.th_charset = 1
      local sheet = createMockSpriteSheet()
      sheet.isVisible = function(self, c) return c ~= 46 end -- Force TTF
      
      local font = Graphics:loadFont(sheet, { force_bitmap = false })
      -- Would be freetype_font but proxy-wrapped
      assert.is_table(font)
    end)
    
    it("should cache TTF fonts by composite key", function()
      Graphics.ttf_font_data = "fake_ttf_data"
      local sheet = createMockSpriteSheet()
      sheet.isVisible = function(self, c) return c ~= 46 end
      
      local f1 = Graphics:loadFont(sheet, { x_sep = 1, ttf_color = {red=255} })
      local f2 = Graphics:loadFont(sheet, { x_sep = 1, ttf_color = {red=255} })
      assert.equal(f1._proxy, f2._proxy)
    end)
    
    it("should differentiate cache by shadow options", function()
      Graphics.ttf_font_data = "fake_ttf_data"
      local sheet = createMockSpriteSheet()
      sheet.isVisible = function(self, c) return c ~= 46 end
      
      local f1 = Graphics:loadFont(sheet, { ttf_shadow = true })
      local f2 = Graphics:loadFont(sheet, { ttf_shadow = false })
      assert.not_equal(f1._proxy, f2._proxy)
    end)
  end)
  
  describe("Cursor Loading", function()
    it("should load standard cursor from MPointer", function()
      local sheet = createMockSpriteSheet()
      Graphics.loadSpriteTable = function(self, dir, name) return sheet end
      
      local cursor = Graphics:loadMainCursor("default")
      assert.is_not_nil(cursor)
      assert.is_function(cursor.draw)
    end)
    
    it("should load SPointer cursor with palette for id > 20", function()
      local sheet = createMockSpriteSheet()
      local pal = createMockPalette()
      Graphics.loadSpriteTable = function(self, dir, name, complex, palette) 
        assert.equal("QData", dir)
        assert.equal("SPointer", name)
        return sheet 
      end
      Graphics.getPalette = function(self, name) 
        assert.equal("Bank01V.pal", name)
        return pal 
      end
      
      local cursor = Graphics:loadMainCursor("bank")
      assert.is_not_nil(cursor)
    end)
    
    it("should cache cursors per sheet per index", function()
      local sheet = createMockSpriteSheet()
      Graphics.loadSpriteTable = function(self, dir, name) return sheet end
      
      local c1 = Graphics:loadCursor(sheet, 1, 0, 0)
      local c2 = Graphics:loadCursor(sheet, 1, 0, 0)
      assert.equal(c1, c2)
    end)
  end)
  
  describe("Sprite Table Loading", function()
    it("should load and cache sprite table", function()
      local sheet = createMockSpriteSheet()
      local TH_sheet = function() return sheet end
      _G.TH = { sheet = TH_sheet }
      
      local result = Graphics:loadSpriteTable("Data", "TestSheet", false, "MPalette.dat")
      assert.equal(sheet, result)
      assert.equal(sheet, Graphics.cache.tabled["TestSheet"])
    end)
    
    it("should not cache SPointer sheet", function()
      local sheet = createMockSpriteSheet()
      local TH_sheet = function() return sheet end
      _G.TH = { sheet = TH_sheet }
      
      Graphics:loadSpriteTable("Data", "SPointer", false, "MPalette.dat")
      assert.is_nil(Graphics.cache.tabled["SPointer"])
    end)
    
    it("should register reload function", function()
      local sheet = createMockSpriteSheet()
      local TH_sheet = function() return sheet end
      _G.TH = { sheet = TH_sheet }
      
      Graphics:loadSpriteTable("Data", "TestSheet", false, "MPalette.dat")
      assert.is_not_nil(Graphics.reload_functions[sheet])
    end)
  end)
  
  describe("Animation Loading", function()
    it("should load animations from 4 .ani files", function()
      local sheet = createMockSpriteSheet()
      local anims = createMockAnimationManager()
      local TH_sheet = function() return sheet end
      local TH_anims = function() return anims end
      _G.TH = { sheet = TH_sheet, anims = TH_anims }
      
      Graphics.loadSpriteTable = function(self, dir, name) return sheet end
      app.readDataFile = function(self, dir, name) return string.rep("\0", 1000) end
      
      local result = Graphics:loadAnimations("Data", "VEnd")
      assert.equal(anims, result)
      assert.equal(anims, Graphics.cache.anims["VEnd"])
    end)
    
    it("should load custom animations if file_mapping exists", function()
      Graphics.custom_graphics = { file_mapping = { "custom.cthg" } }
      Graphics.custom_graphics_folder = "/custom/"
      
      local sheet = createMockSpriteSheet()
      local anims = createMockAnimationManager()
      anims.load_custom_animations = function(self, data) return true end
      anims.set_canvas = function() end
      
      local TH_sheet = function() return sheet end
      local TH_anims = function() return anims end
      _G.TH = { sheet = TH_sheet, anims = TH_anims }
      
      Graphics.loadSpriteTable = function(self, dir, name) return sheet end
      app.readDataFile = function(self, dir, name) return string.rep("\0", 1000) end
      
      local result = Graphics:loadAnimations("Data", "VEnd")
      assert.equal(anims, result)
    end)
  end)
  
  describe("Video Target Update", function()
    it("should call all reload functions on target change", function()
      local new_target = createMockRenderTarget()
      local called = {}
      
      Graphics.reload_functions = {
        [1] = function() table.insert(called, "early") end,
      }
      Graphics.reload_functions_last = {
        [2] = function() table.insert(called, "late") end,
      }
      
      Graphics:updateTarget(new_target)
      assert.equal("early", called[1])
      assert.equal("late", called[2])
      assert.equal(new_target, Graphics.target)
    end)
  end)
end)

-- ============================================================
-- TEST SUITE: AnimationManager (Lua)
-- ============================================================

describe("AnimationManager Class", function()
  local AnimationManager, mock_anims
  
  before_each(function()
    mock_anims = createMockAnimationManager()
    AnimationManager = require("graphics").AnimationManager
    AnimationManager = AnimationManager(mock_anims)
  end)
  
  describe("Animation Length Caching", function()
    it("should cache animation length on first call", function()
      mock_anims.get_first_frame = function(self, anim) return anim * 10 end
      mock_anims.get_next_frame = function(self, frame) 
        if frame < (anim * 10 + 5) then return frame + 1 else return anim * 10 end
      end
      
      local length = AnimationManager:getAnimLength(42)
      assert.equal(5, length)
      assert.equal(5, AnimationManager.anim_length_cache[42])
    end)
    
    it("should return cached length on subsequent calls", function()
      AnimationManager.anim_length_cache[42] = 10
      local length = AnimationManager:getAnimLength(42)
      assert.equal(10, length)
    end)
    
    it("should detect loops correctly", function()
      mock_anims.get_first_frame = function(self, anim) return 100 end
      mock_anims.get_next_frame = function(self, frame) 
        if frame < 105 then return frame + 1 else return 100 end
      end
      
      local length = AnimationManager:getAnimLength(1)
      assert.equal(5, length)
    end)
  end)
  
  describe("Marker Setting", function()
    it("should set patient marker for single position", function()
      AnimationManager:setPatientMarker(42, {10, 20})
      -- Verify internal call to setMarkerRaw
    end)
    
    it("should set staff marker with per-frame positions", function()
      AnimationManager:setStaffMarker(42, {{0,0}, {1,1}, {2,2}})
    end)
    
    it("should interpolate between start/end positions", function()
      AnimationManager:setPatientMarker(42, {0,0}, {10,10})
    end)
    
    it("should handle keyframe interpolation", function()
      AnimationManager:setPatientMarker(42, 0, {0,0}, 3, {10,10}, 5, {20,20})
    end)
    
    it("should convert tile positions to screen coordinates", function()
      -- Uses Map:WorldToScreen internally
    end)
    
    it("should accept pixel positions directly", function()
      AnimationManager:setPatientMarker(42, {100, 200, "px"})
    end)
  end)
  
  describe("Multiple Animation Handling", function()
    it("should unfold table of animation numbers", function()
      AnimationManager:setPatientMarker({42, 43, 44}, {0,0})
    end)
    
    it("should handle nested tables", function()
      AnimationManager:setPatientMarker({{42, 43}, 44}, {0,0})
    end)
  end)
end)

-- ============================================================
-- TEST SUITE: C++ Binding Mocks (Integration)
-- ============================================================

describe("C++ Graphics Bindings", function()
  local TH
  
  before_each(function()
    TH = require("TH") -- Would be the actual C++ binding
  end)
  
  describe("palette", function()
    it("should create palette from 6-bit data", function()
      local data = string.rep("\0", 768)
      local pal = TH.palette(data, false)
      assert.is_not_nil(pal)
    end)
    
    it("should create palette from 8-bit data", function()
      local data = string.rep("\0", 1024)
      local pal = TH.palette(data, true)
      assert.is_not_nil(pal)
    end)
    
    it("should set entry and remap magenta to transparent", function()
      local pal = TH.palette(string.rep("\0", 768), false)
      pal:setEntry(255, 0xFF, 0x00, 0xFF) -- Magenta
      -- Verify transparent mapping
    end)
  end)
  
  describe("sprite_sheet", function()
    it("should load from TH .tab/.dat files", function()
      local sheet = TH.sheet()
      local pal = TH.palette(string.rep("\0", 768), false)
      sheet:setPalette(pal)
      -- Would need actual test data files
    end)
    
    it("should decode complex and simple chunks", function()
      -- Test chunk_renderer via sheet loading
    end)
    
    it("should create alt texture for palette remapping", function()
      local sheet = TH.sheet()
      sheet:set_sprite_alt_palette_map(0, remap_data, thdf_alt32_grey_scale)
    end)
  end)
  
  describe("animation_manager", function()
    it("should load from 4 TH animation files", function()
      local anims = TH.anims()
      local sheet = TH.sheet()
      anims:set_sprite_sheet(sheet)
      -- Load VStart, VFra, VList, VEle
    end)
    
    it("should load custom animations from CTHG format", function()
      local anims = TH.anims()
      anims:loadCustom(data)
    end)
    
    it("should draw frame with layers and effects", function()
      local anims = TH.anims()
      anims:draw_frame(canvas, frame, layers, x, y, flags, effect, offset, scale)
    end)
    
    it("should hit test with bounding box and pixel-perfect", function()
      local anims = TH.anims()
      local hit = anims:hit_test(frame, layers, x, y, flags, test_x, test_y)
    end)
    
    it("should set/get frame markers", function()
      local anims = TH.anims()
      anims:setFramePrimaryMarker(frame, x, y)
      local x, y = anims:getFramePrimaryMarker(frame)
    end)
  end)
  
  describe("animation", function()
    it("should advance frame and position on tick", function()
      local anim = TH.animation()
      anim:set_animation(anims, 42)
      anim:set_speed(10, 5)
      anim:tick()
      assert.equal(anim:get_frame(), anims:get_next_frame(anims:get_first_frame(42)))
    end)
    
    it("should support child animations on primary/secondary markers", function()
      local parent = TH.animation()
      local child = TH.animation()
      child:set_parent(parent, true) -- primary
      child:set_parent(parent, false) -- secondary
    end)
    
    it("should support morph animations", function()
      local a1 = TH.animation()
      local a2 = TH.animation()
      a1:set_morph_target(a2, 30)
    end)
    
    it("should persist and depersist correctly", function()
      local anim = TH.animation()
      -- Test writer/reader round-trip
    end)
    
    it("should handle crop_column for multi-tile objects", function()
      local anim = TH.animation()
      anim:set_flags(thdf_crop)
      anim:set_crop_column(2)
    end)
  end)
  
  describe("sprite_render_list", function()
    it("should append sprites and animate", function()
      local srl = TH.spriteList()
      srl:set_sheet(sheet)
      srl:append_sprite(5, 0, 0)
      srl:set_speed(10, -5)
      srl:set_lifetime(60)
      srl:tick()
    end)
    
    it("should use intermediate buffer for text scaling", function()
      local srl = TH.spriteList()
      srl:set_use_intermediate_buffer()
    end)
  end)
  
  describe("bitmap_font", function()
    it("should set sheet and charset", function()
      local font = TH.bitmap_font()
      font:setSheet(sheet, 1) -- cp437
      font:setSeparation(1, 0)
      font:setScaleFactor(2.0)
    end)
    
    it("should measure and draw text", function()
      local font = TH.bitmap_font()
      local w, h = font:sizeOf("Test")
      font:draw(canvas, x, y, "Test")
    end)
  end)
  
  describe("freetype_font", function()
    it("should load TTF face and set options", function()
      local font = TH.freetype_font()
      font:setFace(ttf_data)
      font:setFontOptions(sprite_table, options)
    end)
    
    it("should cache glyphs and support shadows", function()
      local font = TH.freetype_font()
      font:draw(canvas, x, y, "Test")
      font:clearCache()
    end)
  end)
end)

-- ============================================================
-- TEST SUITE: Split Animations (Multi-Tile Objects)
-- ============================================================

describe("Split Animations for Multi-Tile Objects", function()
  it("should crop animation to column for each tile", function()
    -- Large object (2x2 tiles) uses single animation
    -- Each tile draws with thdf_crop + crop_column (1-4)
    -- crop_column selects 64-pixel wide column
  end)
  
  it("should set correct clip rect in animation::draw", function()
    -- clip_rect.x = x + (crop_column - 1) * 32 * scale
    -- clip_rect.w = 64 * scale
  end)
  
  it("should handle scale_factor in crop calculations", function()
    -- Clip rect scales with scale_factor
  end)
end)

-- ============================================================
-- TEST SUITE: Palette Remapping & Effects
-- ============================================================

describe("Palette Remapping and Animation Effects", function()
  it("should apply greyscale ghost remap", function()
    local ghost = makeGreyscaleGhost(palette_data)
    anims:set_animation_alt_palette_map(anim, ghost, thdf_alt32_grey_scale)
    -- Draw with thdf_alt_palette flag
  end)
  
  it("should apply glowing effect (pulsing green)", function()
    -- effect_ticks % 15 drives sine wave 155-255
  end)
  
  it("should apply jelly effect (sine wave distortion)", function()
    -- effect_ticks % 540 < 90 activates
    -- Per-scanline horizontal offset
  end)
  
  it("should swap red/blue channels for alt32", function()
    -- thdf_alt32_blue_red_swap with compensation
  end)
end)

-- ============================================================
-- RUNNER
-- ============================================================

-- Run with: busted SCAFFOLD.lua
-- Or: lua SCAFFOLD.lua (if using busted as library)

print("Test scaffold loaded. Run with: busted " .. arg[0])
