-- Busted Test Scaffold for CorsixTH Graphics System
-- Run with: busted SCAFFOLD.lua

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

-- ============================================================================
-- MOCK HELPERS
-- ============================================================================

local function createMockApp()
    local app = {
        config = {
            use_new_graphics = false,
            new_graphics_folder = nil,
            unicode_font = nil,
            ui_scale = 1,
            cursor_scale = 1,
            debug = false,
        },
        video = nil,  -- render_target mock
        strings = {
            isArabicNumerals = function() return false end
        },
        getFullPath = function(self, subdir, create)
            return "/mock/path/" .. (subdir or "") .. "/"
        end,
        readDataFile = function(self, dir, name)
            -- Return mock data based on file type
            if name:match("%.pal$") or name:match("%.pl8$") then
                return string.rep("\0", 768)  -- 256 * 3 bytes
            elseif name:match("%.dat$") then
                return string.rep("\0", 640 * 480)
            elseif name:match("%.tab$") then
                return string.rep("\0", 100 * 6)
            elseif name:match("%.ani$") then
                return string.rep("\0", 1000)
            end
            return ""
        end,
        saveConfig = function() end,
    }
    return app
end

local function createMockRenderTarget()
    local rt = {
        renderer = mock(SDL_Renderer),
        window = mock(SDL_Window),
        current_target = nil,
        intermediate_textures = {},
        global_scale_factor = 1.0,
        scale_bitmaps = false,
        bitmap_scale_factor = 1.0,
        supports_target_textures = true,
        blue_filter_active = false,
        game_cursor = nil,
        cursor_x = 0,
        cursor_y = 0,
        draw_scale = function(self)
            if self.current_target then return self.current_target:scale_factor() end
            return self.global_scale_factor
        end,
        should_scale_bitmaps = function(self, factor)
            if self.scale_bitmaps then
                if factor then factor[1] = self.bitmap_scale_factor end
                return true
            end
            return false
        end,
        create_palettized_texture = function(self, w, h, pixels, palette, flags)
            return mock(SDL_Texture)
        end,
        create_texture = function(self, w, h, pixels, flags)
            return mock(SDL_Texture)
        end,
        draw = function(self, texture, src, dst, flags) end,
        push_clip_rect = function(self, rect) end,
        pop_clip_rect = function(self) end,
        get_width = function(self) return 1024 end,
        get_height = function(self) return 768 end,
        get_scaled_width = function(self) return 1024 end,
        get_scaled_height = function(self) return 768 end,
        destroy_intermediate_textures = function(self) end,
    }
    return rt
end

local function createMockPalette()
    local pal = {
        colour_index_to_argb_map = {},
        set_entry = function(self, idx, r, g, b) return true end,
        get_argb_data = function(self) return self.colour_index_to_argb_map end,
    }
    for i = 0, 255 do
        pal.colour_index_to_argb_map[i] = 0xFF000000 + i * 0x010101
    end
    pal.colour_index_to_argb_map[255] = 0x00000000  -- Transparent
    return pal
end

local function createMockSpriteSheet()
    local sheet = {
        sprite_count = 100,
        sprites = {},
        palette = createMockPalette(),
        target = createMockRenderTarget(),
        set_sprite_count = function(self, count, canvas)
            self.sprite_count = count
            self.sprites = {}
            for i = 1, count do
                self.sprites[i] = {
                    texture = nil,
                    alt_texture = nil,
                    data = string.rep("\0", 32 * 32),
                    alt_palette_map = nil,
                    sprite_flags = 0,
                    width = 32,
                    height = 32,
                }
            end
            return true
        end,
        load_from_th_file = function(self, tab, tab_len, chunk, chunk_len, complex, canvas) return true end,
        set_sprite_data = function(self, idx, data, take, len, w, h) return true end,
        set_sprite_alt_palette_map = function(self, idx, map, alt32) end,
        get_sprite_count = function(self) return self.sprite_count end,
        get_sprite_size = function(self, idx, w, h)
            if idx < self.sprite_count then
                if w then w[1] = self.sprites[idx+1].width end
                if h then h[1] = self.sprites[idx+1].height end
                return true
            end
            return false
        end,
        get_sprite_size_unchecked = function(self, idx, w, h)
            w[1] = self.sprites[idx+1].width
            h[1] = self.sprites[idx+1].height
        end,
        is_sprite_visible = function(self, idx) return true end,
        get_sprite_average_colour = function(self, idx, colour)
            colour[1] = 0xFFFFFFFF
            return true
        end,
        draw_sprite = function(self, canvas, idx, x, y, flags, ticks, effect, scale) end,
        hit_test_sprite = function(self, idx, x, y, flags) return true end,
    }
    return sheet
end

local function createMockAnimationManager()
    local mgr = {
        sheet = createMockSpriteSheet(),
        canvas = createMockRenderTarget(),
        animation_count = 10,
        frame_count = 100,
        frames = {},
        elements = {},
        element_list = {},
        first_frames = {},
        game_ticks = 0,
        named_animations = {},
        set_sprite_sheet = function(self, sheet) self.sheet = sheet end,
        set_canvas = function(self, canvas) self.canvas = canvas end,
        load_from_th_file = function(self, start, fra, list, ele) return true end,
        load_custom_animations = function(self, data, len) return true end,
        get_animation_count = function(self) return self.animation_count end,
        get_frame_count = function(self) return self.frame_count end,
        get_first_frame = function(self, anim) return anim * 10 end,
        get_next_frame = function(self, frame) return frame + 1 end,
        set_animation_alt_palette_map = function(self, anim, map, alt32) end,
        draw_frame = function(self, canvas, frame, layers, x, y, flags, effect, offset, scale) end,
        get_frame_extent = function(self, frame, layers, minx, maxx, miny, maxy, flags) end,
        get_frame_sound = function(self, frame) return 0 end,
        hit_test = function(self, frame, layers, x, y, flags, tx, ty) return true end,
        set_frame_primary_marker = function(self, frame, x, y) return true end,
        set_frame_secondary_marker = function(self, frame, x, y) return true end,
        get_frame_primary_marker = function(self, frame, x, y)
            x[1] = 0; y[1] = 0; return true
        end,
        get_frame_secondary_marker = function(self, frame, x, y)
            x[1] = 0; y[1] = 0; return true
        end,
        get_named_animations = function(self, name, tilesize)
            return {north=-1, east=-1, south=-1, west=-1}
        end,
        tick = function(self) self.game_ticks = self.game_ticks + 1 end,
    }
    -- Initialize frames
    for i = 1, mgr.frame_count do
        mgr.frames[i] = {
            list_index = 0,
            next_frame = (i % 10) + 1,
            sound = 0,
            flags = 0,
            bounding_left = -16, bounding_right = 16,
            bounding_top = -32, bounding_bottom = 0,
            primary_marker_x = 0, primary_marker_y = 0,
            secondary_marker_x = 0, secondary_marker_y = 0,
        }
    end
    for i = 1, mgr.animation_count do
        mgr.first_frames[i] = (i-1) * 10
    end
    return mgr
end

local function createMockAnimation()
    local anim = {
        manager = createMockAnimationManager(),
        animation_index = 0,
        frame_index = 0,
        pixel_offset = {x = 0, y = 0},
        speed = {x = 0, y = 0},
        flags = 0,
        anim_kind = "normal",
        patient_effect = "none",
        patient_effect_offset = 0,
        crop_column = 0,
        morph_target = nil,
        parent = nil,
        sound_to_play = 0,
        layers = {layer_contents = {}},
        set_animation = function(self, mgr, anim)
            self.manager = mgr
            self.animation_index = anim
            self.frame_index = mgr:get_first_frame(anim)
        end,
        set_frame = function(self, frame) self.frame_index = frame end,
        set_speed = function(self, x, y) self.speed.x = x; self.speed.y = y end,
        set_crop_column = function(self, col) self.crop_column = col end,
        set_morph_target = function(self, target, duration) self.morph_target = target end,
        set_parent = function(self, parent, use_primary) self.parent = parent end,
        set_patient_effect = function(self, effect) self.patient_effect = effect end,
        set_animation_kind = function(self, kind) self.anim_kind = kind end,
        get_animation = function(self) return self.animation_index end,
        get_frame = function(self) return self.frame_index end,
        get_crop_column = function(self) return self.crop_column end,
        get_primary_marker = function(self, x, y)
            x[1] = 0; y[1] = 0; return true
        end,
        get_secondary_marker = function(self, x, y)
            x[1] = 0; y[1] = 0; return true
        end,
        tick = function(self)
            self.frame_index = self.manager:get_next_frame(self.frame_index)
            self.pixel_offset.x = self.pixel_offset.x + self.speed.x
            self.pixel_offset.y = self.pixel_offset.y + self.speed.y
        end,
        draw = function(self, canvas, pos) end,
        hit_test = function(self, draw_pos, obj_pos) return true end,
    }
    return anim
end

local function createMockBitmapFont()
    local font = {
        sheet = createMockSpriteSheet(),
        letter_spacing = 0,
        line_spacing = 0,
        scale_factor = 1,
        character_set = "cp437",
        set_sprite_sheet = function(self, sheet, charset) self.sheet = sheet; self.character_set = charset end,
        set_separation = function(self, char, line) self.letter_spacing = char; self.line_spacing = line end,
        set_scale_factor = function(self, factor) self.scale_factor = factor end,
        get_text_dimensions = function(self, msg, len, maxw)
            return {row_count=1, start_x=0, end_x=len*8, start_y=0, end_y=16, width=len*8}
        end,
        draw_text = function(self, canvas, msg, len, x, y) end,
        draw_text_wrapped = function(self, canvas, msg, len, x, y, w, maxr, skip, align)
            return {row_count=1, start_x=x, end_x=x+w, start_y=y, end_y=y+16, width=w}
        end,
    }
    return font
end

local function createMockFreeTypeFont()
    local font = {
        font_face = nil,
        font_color = 0xFFFFFFFF,
        shadow_opts = {enabled=false, offset_x=1, offset_y=1, color=0xFF000000},
        cache = {},
        cache_size_log2 = 7,
        set_face = function(self, data, len) return 0 end,
        match_bitmap_font = function(self, sheet, color, w, h)
            w[1] = 8; h[1] = 16; color[1] = 0xFFFFFFFF; return 0
        end,
        set_ideal_character_size = function(self, w, h) return 0 end,
        set_font_color = function(self, color) self.font_color = color end,
        set_shadow_options = function(self, opts) self.shadow_opts = opts end,
        clear_cache = function(self) end,
        get_text_dimensions = function(self, msg, len, maxw)
            return {row_count=1, start_x=0, end_x=len*8, start_y=0, end_y=16, width=len*8}
        end,
        draw_text = function(self, canvas, msg, len, x, y) end,
        draw_text_wrapped = function(self, canvas, msg, len, x, y, w, maxr, skip, align)
            return {row_count=1, start_x=x, end_x=x+w, start_y=y, end_y=y+16, width=w}
        end,
    }
    return font
end

-- ============================================================================
-- TEST SUITES
-- ============================================================================

describe("Graphics Class - Palette Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        -- Need to load the actual Graphics class
        -- This is a template - replace with actual module loading
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should load base palettes on initialization", function()
        -- pending("Implement Graphics class loading")
        -- assert.is_not_nil(graphics.cache.palette["MPalette.dat"])
        -- assert.is_not_nil(graphics.cache.palette["bootstrap_font.pal"])
    end)
    
    it("should cache palettes and return same instance", function()
        -- local pal1 = graphics:getPalette("MPalette.dat")
        -- local pal2 = graphics:getPalette("MPalette.dat")
        -- assert.are_same(pal1, pal2)
    end)
    
    it("should create greyscale ghost remap for each palette", function()
        -- local _, ghost = graphics:getPalette("MPalette.dat")
        -- assert.is_string(ghost)
        -- assert.equals(256, #ghost)
    end)
    
    it("should load ghost palette data", function()
        -- local ghost = graphics:loadGhost("Data", "Test.dat", 0)
        -- assert.is_string(ghost)
        -- assert.equals(256, #ghost)
    end)
end)

describe("Graphics Class - Raw Bitmap Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should load raw bitmap from .dat + .pal", function()
        -- local bmp = graphics:loadRaw("TestImage", 640, 480, "QData", nil, "TestImage.pal")
        -- assert.is_userdata(bmp)
        -- assert.is_function(bmp.draw)
    end)
    
    it("should cache raw bitmaps by name", function()
        -- local bmp1 = graphics:loadRaw("TestImage", 640, 480, "QData", nil, "TestImage.pal")
        -- local bmp2 = graphics:loadRaw("TestImage", 640, 480, "QData", nil, "TestImage.pal")
        -- assert.are_same(bmp1, bmp2)
    end)
    
    it("should support custom flags for loading", function()
        -- local bmp = graphics:loadRaw("TestImage", 640, 480, "QData", nil, "TestImage.pal", false, {custom_flag=true})
        -- assert.is_userdata(bmp)
    end)
end)

describe("Graphics Class - Sprite Sheet Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should load sprite sheet from .tab + .dat", function()
        -- local sheet = graphics:loadSpriteTable("QData", "VObjects", false, "MPalette.dat")
        -- assert.is_userdata(sheet)
        -- assert.is_function(sheet.draw_sprite)
    end)
    
    it("should handle complex (RLE) sprite sheets", function()
        -- local sheet = graphics:loadSpriteTable("Data", "ComplexSheet", true, "MPalette.dat")
        -- assert.is_userdata(sheet)
    end)
    
    it("should cache sprite sheets by name", function()
        -- local s1 = graphics:loadSpriteTable("QData", "VObjects", false, "MPalette.dat")
        -- local s2 = graphics:loadSpriteTable("QData", "VObjects", false, "MPalette.dat")
        -- assert.are_same(s1, s2)
    end)
    
    it("should register reload function for video target changes", function()
        -- local sheet = graphics:loadSpriteTable("QData", "VObjects", false, "MPalette.dat")
        -- assert.is_not_nil(graphics.reload_functions[sheet])
    end)
end)

describe("Graphics Class - Animation Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "full", "cp437")
    end)
    
    it("should load animation set from Start/Fra/List/Ele files", function()
        -- local anims = graphics:loadAnimations("Data", "V")
        -- assert.is_userdata(anims)
        -- assert.is_function(anims.draw_frame)
    end)
    
    it("should load custom animations from .ca files", function()
        -- app.config.use_new_graphics = true
        -- app.config.new_graphics_folder = "/custom/"
        -- local anims = graphics:loadAnimations("Data", "V")
        -- -- Custom animations merged into anims
    end)
    
    it("should cache animation managers by prefix", function()
        -- local a1 = graphics:loadAnimations("Data", "V")
        -- local a2 = graphics:loadAnimations("Data", "V")
        -- assert.are_same(a1, a2)
    end)
end)

describe("Graphics Class - Font Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should load builtin CP437 font", function()
        -- local font = graphics:loadBuiltinFont()
        -- assert.is_userdata(font)
        -- assert.is_function(font.draw_text)
    end)
    
    it("should load bitmap font from sprite sheet", function()
        -- local sheet = graphics:loadSpriteTable("QData", "Font01V", false, "MPalette.dat")
        -- local font = graphics:loadFont(sheet, {x_sep=1, y_sep=0, apply_ui_scale=true})
        -- assert.is_userdata(font)
    end)
    
    it("should load FreeType font for non-CP437 languages", function()
        -- app.config.language = "japanese"
        -- local sheet = graphics:loadSpriteTable("QData", "Font01V", false, "MPalette.dat")
        -- local font = graphics:loadLanguageFont("unicode", sheet, {
        --     ttf_color = {red=255, green=255, blue=255},
        --     apply_ui_scale = true,
        -- })
        -- assert.is_userdata(font)
    end)
    
    it("should wrap fonts in proxy for hot-swapping", function()
        -- local font = graphics:loadLanguageFont("unicode", sheet, {apply_ui_scale=true})
        -- assert.is_table(font)
        -- assert.is_function(font.draw)
        -- assert.is_userdata(font._proxy)
    end)
    
    it("should cache fonts by options key", function()
        -- local sheet = graphics:loadSpriteTable("QData", "Font01V", false, "MPalette.dat")
        -- local f1 = graphics:loadFont(sheet, {x_sep=1, apply_ui_scale=true})
        -- local f2 = graphics:loadFont(sheet, {x_sep=1, apply_ui_scale=true})
        -- assert.are_same(f1._proxy, f2._proxy)
    end)
    
    it("should handle font options: shadow, color, scale", function()
        -- local sheet = graphics:loadSpriteTable("QData", "Font01V", false, "MPalette.dat")
        -- local font = graphics:loadFont(sheet, {
        --     x_sep = 1, y_sep = 2,
        --     ttf_color = {red=255, green=0, blue=0, alpha=200},
        --     ttf_shadow = {offset_x=2, offset_y=2, color={red=0, green=0, blue=0, alpha=128}},
        --     apply_ui_scale = true,
        --     force_bitmap = false,
        -- })
        -- assert.is_userdata(font)
    end)
end)

describe("Graphics Class - Cursor Loading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should load standard cursors from MPointer", function()
        -- local cursor = graphics:loadMainCursor("default")
        -- assert.is_userdata(cursor)
        -- assert.is_function(cursor.draw)
    end)
    
    it("should load SPointer cursors with specific palettes", function()
        -- local cursor = graphics:loadMainCursor("bank")
        -- assert.is_userdata(cursor)
    end)
    
    it("should cache cursors per sprite sheet", function()
        -- local c1 = graphics:loadCursor(sheet, 1, 0, 0)
        -- local c2 = graphics:loadCursor(sheet, 1, 0, 0)
        -- assert.are_same(c1, c2)
    end)
end)

describe("AnimationManager - Core Functionality", function()
    local mgr, sheet
    
    before_each(function()
        sheet = createMockSpriteSheet()
        mgr = createMockAnimationManager()
        mgr:set_sprite_sheet(sheet)
        mgr:set_canvas(createMockRenderTarget())
    end)
    
    it("should load original animation files", function()
        -- local start = string.rep("\0", 40)
        -- local fra = string.rep("\0", 1000)
        -- local list = string.rep("\0", 200)
        -- local ele = string.rep("\0", 600)
        -- assert.is_true(mgr:load_from_th_file(start, fra, list, ele))
    end)
    
    it("should track animation and frame counts", function()
        -- assert.equals(10, mgr:get_animation_count())
        -- assert.equals(100, mgr:get_frame_count())
    end)
    
    it("should iterate frames in animation loop", function()
        -- local first = mgr:get_first_frame(0)
        -- local next = mgr:get_next_frame(first)
        -- assert.not_equals(first, next)
        -- -- Loop back to start
        -- local frame = first
        -- repeat
        --     frame = mgr:get_next_frame(frame)
        -- until frame == first
    end)
    
    it("should set and get frame markers", function()
        -- local x, y = {}, {}
        -- mgr:set_frame_primary_marker(0, 10, 20)
        -- assert.is_true(mgr:get_frame_primary_marker(0, x, y))
        -- assert.equals(10, x[1])
        -- assert.equals(20, y[1])
    end)
    
    it("should draw animation frame with layers", function()
        -- local layers = {layer_contents = {[0]=0, [1]=1, [5]=2}}
        -- mgr:draw_frame(canvas, 0, layers, 100, 100, 0, "none", 0, 1)
        -- -- Verify draw calls
    end)
    
    it("should hit test animation frames", function()
        -- local layers = {layer_contents = {}}
        -- local hit = mgr:hit_test(0, layers, 100, 100, 0, 110, 110)
        -- assert.is_boolean(hit)
    end)
    
    it("should apply alt palette map to animation", function()
        -- local map = string.rep("\0", 256)
        -- mgr:set_animation_alt_palette_map(0, map, 1<<5)  -- greyscale
        -- -- Verify sprites updated
    end)
    
    it("should load custom animations with named groups", function()
        -- local data = "CTHG\1\2" .. -- header
        --     "CA" .. string.pack("<I2I4", 32, 5) .. "TestAnim\0" .. string.rep("\0", 16)
        -- assert.is_true(mgr:load_custom_animations(data, #data))
        -- local frames = mgr:get_named_animations("TestAnim", 32)
        -- assert.is_table(frames)
    end)
end)

describe("Animation Instance - Runtime Behavior", function()
    local anim, mgr
    
    before_each(function()
        mgr = createMockAnimationManager()
        anim = createMockAnimation()
        anim:set_animation(mgr, 0)
    end)
    
    it("should advance frame on tick", function()
        -- local f1 = anim:get_frame()
        -- anim:tick()
        -- local f2 = anim:get_frame()
        -- assert.not_equals(f1, f2)
    end)
    
    it("should update pixel offset by speed", function()
        -- anim:set_speed(2, 3)
        -- anim:tick()
        -- assert.equals(2, anim.pixel_offset.x)
        -- assert.equals(3, anim.pixel_offset.y)
    end)
    
    it("should support child animations (primary/secondary)", function()
        -- local parent = createMockAnimation()
        -- parent:set_animation(mgr, 0)
        -- local child = createMockAnimation()
        -- child:set_animation(mgr, 1)
        -- child:set_parent(parent, true)  -- primary
        -- assert.equals("primary_child", child.anim_kind)
    end)
    
    it("should support morph animations", function()
        -- local target = createMockAnimation()
        -- target:set_animation(mgr, 2)
        -- anim:set_morph_target(target, 2)
        -- assert.equals("morph", anim.anim_kind)
        -- assert.is_not_nil(anim.morph_target)
    end)
    
    it("should apply crop column for split animations", function()
        -- anim:set_crop_column(2)
        -- anim:set_flags(1<<13)  -- thdf_crop
        -- assert.equals(2, anim:get_crop_column())
    end)
    
    it("should persist and depersist correctly", function()
        -- local writer = mock(lua_persist_writer)
        -- local reader = mock(lua_persist_reader)
        -- anim:persist(writer)
        -- anim:depersist(reader)
        -- -- Verify state restored
    end)
end)

describe("Sprite Render List - Particle Effects", function()
    local srl, sheet
    
    before_each(function()
        sheet = createMockSpriteSheet()
        srl = {
            sheet = sheet,
            sprites = {},
            dx_per_tick = 0,
            dy_per_tick = 0,
            lifetime = -1,
            use_intermediate_buffer = false,
            set_sheet = function(self, s) self.sheet = s end,
            set_speed = function(self, x, y) self.dx_per_tick = x; self.dy_per_tick = y end,
            set_lifetime = function(self, t) self.lifetime = t end,
            set_use_intermediate_buffer = function(self) self.use_intermediate_buffer = true end,
            append_sprite = function(self, idx, x, y)
                table.insert(self.sprites, {index=idx, x=x, y=y})
            end,
            is_dead = function(self) return self.lifetime == 0 end,
            tick = function(self)
                if self.lifetime > 0 then self.lifetime = self.lifetime - 1 end
            end,
            draw = function(self, canvas, pos) end,
            hit_test = function(self, draw_pos, obj_pos) return false end,
        }
    end)
    
    it("should create and configure sprite render list", function()
        -- srl:set_sheet(sheet)
        -- srl:set_speed(1, -1)
        -- srl:set_lifetime(60)
        -- srl:append_sprite(5, 0, 0)
        -- srl:append_sprite(6, 10, 10)
        -- assert.equals(2, #srl.sprites)
    end)
    
    it("should expire after lifetime ticks", function()
        -- srl:set_lifetime(2)
        -- srl:tick()
        -- assert.is_false(srl:is_dead())
        -- srl:tick()
        -- assert.is_true(srl:is_dead())
    end)
end)

describe("Bitmap Font - Text Rendering", function()
    local font, sheet
    
    before_each(function()
        sheet = createMockSpriteSheet()
        font = createMockBitmapFont()
        font:set_sprite_sheet(sheet, "cp437")
    end)
    
    it("should measure text dimensions", function()
        -- local layout = font:get_text_dimensions("Hello", 5, INT_MAX)
        -- assert.equals(1, layout.row_count)
        -- assert.is_number(layout.width)
    end)
    
    it("should draw single line of text", function()
        -- local canvas = createMockRenderTarget()
        -- font:draw_text(canvas, "Hello", 5, 100, 100)
        -- -- Verify sprite draws
    end)
    
    it("should wrap text at word boundaries", function()
        -- local canvas = createMockRenderTarget()
        -- local layout = font:draw_text_wrapped(canvas, "Hello world test", 16, 100, 100, 50, 10, 0, "left")
        -- assert.is_number(layout.row_count)
        -- assert.is_number(layout.width)
    end)
    
    it("should support alignment (left/center/right)", function()
        -- local canvas = createMockRenderTarget()
        -- local l1 = font:draw_text_wrapped(canvas, "Hi", 2, 100, 100, 100, 10, 0, "left")
        -- local l2 = font:draw_text_wrapped(canvas, "Hi", 2, 100, 100, 100, 10, 0, "center")
        -- local l3 = font:draw_text_wrapped(canvas, "Hi", 2, 100, 100, 100, 10, 0, "right")
        -- -- Center/right should have different start_x
    end)
    
    it("should handle double newline as paragraph break", function()
        -- local canvas = createMockRenderTarget()
        -- local layout = font:draw_text_wrapped(canvas, "Para1\n\nPara2", 12, 100, 100, 100, 10, 0, "left")
        -- assert.equals(3, layout.row_count)  -- Para1, blank, Para2
    end)
    
    it("should scale with UI scale factor", function()
        -- font:set_scale_factor(2)
        -- local layout = font:get_text_dimensions("Hi", 2, INT_MAX)
        -- assert.equals(2 * 16, layout.width)  -- Scaled width
    end)
end)

describe("FreeType Font - Advanced Text Rendering", function()
    local font
    
    before_each(function()
        font = createMockFreeTypeFont()
        font:set_face("mock_font_data", 1000)
    end)
    
    it("should initialize FreeType library", function()
        -- local err = font:initialise()
        -- assert.equals(0, err)
    end)
    
    it("should load font face from memory", function()
        -- local data = "TTF_DATA"
        -- local err = font:set_face(data, #data)
        -- assert.equals(0, err)
    end)
    
    it("should match bitmap font metrics", function()
        -- local sheet = createMockSpriteSheet()
        -- local color, w, h = {}, {}, {}
        -- local err = font:match_bitmap_font(sheet, color, w, h)
        -- assert.equals(0, err)
        -- assert.is_number(w[1])
        -- assert.is_number(h[1])
    end)
    
    it("should set ideal character size", function()
        -- local err = font:set_ideal_character_size(8, 16)
        -- assert.equals(0, err)
    end)
    
    it("should configure shadow options", function()
        -- font:set_shadow_options({
        --     enabled = true,
        --     offset_x = 2,
        --     offset_y = 2,
        --     color = 0x80000000,
        -- })
        -- assert.is_true(font.shadow_opts.enabled)
    end)
    
    it("should cache rendered text", function()
        -- local canvas = createMockRenderTarget()
        -- font:draw_text_wrapped(canvas, "Cached text", 11, 100, 100, 200, 10, 0, "left")
        -- font:draw_text_wrapped(canvas, "Cached text", 11, 100, 100, 200, 10, 0, "left")
        -- -- Second call should use cache
    end)
    
    it("should clear cache on graphics context change", function()
        -- font:clear_cache()
        -- -- All cache entries invalidated
    end)
    
    it("should handle CJK line breaking", function()
        -- local canvas = createMockRenderTarget()
        -- local layout = font:draw_text_wrapped(canvas, "你好世界", 12, 100, 100, 50, 10, 0, "left")
        -- assert.is_number(layout.row_count)
    end)
end)

describe("Split Animations - Multi-tile Objects", function()
    local graphics, app, object_type
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "full", "cp437")
        
        object_type = {
            idle_animations = {north=1, east=2, south=3, west=4},
            orientations = {
                north = {
                    footprint = {{0,0}, {1,0}},
                    render_attach_position = {{0,0,1}, {1,0,2}},
                    animation_offset = {0, 0},
                }
            }
        }
    end)
    
    it("should create split animations for multi-tile render_attach_position", function()
        -- local obj = Object(hospital, object_type, 10, 10, "north")
        -- assert.is_table(obj.split_anims)
        -- assert.equals(2, #obj.split_anims)
    end)
    
    it("should set crop column on each split animation", function()
        -- local obj = Object(hospital, object_type, 10, 10, "north")
        -- assert.equals(1, obj.split_anims[1]:get_crop_column())
        -- assert.equals(2, obj.split_anims[2]:get_crop_column())
    end)
    
    it("should position split animations relative to primary", function()
        -- local obj = Object(hospital, object_type, 10, 10, "north")
        -- obj:setPosition(100, 100)
        -- -- Second anim should be offset by tile width
    end)
    
    it("should apply DrawFlags.Crop when setting animation", function()
        -- local obj = Object(hospital, object_type, 10, 10, "north")
        -- obj:setAnimation(5, 0)
        -- assert.is_true(bit.band(obj.animation_flags, DrawFlags.Crop) ~= 0)
    end)
    
    it("should tick all split animations in sync", function()
        -- local obj = Object(hospital, object_type, 10, 10, "north")
        -- obj.num_animation_ticks = 2
        -- obj:tick()
        -- -- Both animations advanced 2 frames
    end)
end)

describe("Animation Manager - Marker Positions", function()
    local anim_mgr, mgr
    
    before_each(function()
        mgr = createMockAnimationManager()
        anim_mgr = {
            anims = mgr,
            anim_length_cache = {},
            setPatientMarker = function(self, anim, ...) end,
            setStaffMarker = function(self, anim, ...) end,
            getAnimLength = function(self, anim) return 10 end,
            _unfoldAnims = function(self, anim, fn, ...) end,
            setMarkerRaw = function(self, anim, fn, ...) end,
        }
    end)
    
    it("should set static marker for all frames", function()
        -- anim_mgr:setPatientMarker(100, {1.5, 2.0})
        -- -- Verify all 10 frames have marker (1.5, 2.0) in tile coords
    end)
    
    it("should set per-frame markers from array", function()
        -- anim_mgr:setPatientMarker(100, {{0,0}, {1,0}, nil, {3,0}})
        -- -- Frame 0: (0,0), Frame 1: (1,0), Frame 2: (1,0), Frame 3: (3,0)
    end)
    
    it("should interpolate between start and end positions", function()
        -- anim_mgr:setPatientMarker(100, {0,0}, {10,5})
        -- -- Frame 0: (0,0), Frame 9: (10,5), linear interpolation
    end)
    
    it("should interpolate between keyframes", function()
        -- anim_mgr:setPatientMarker(100, 0, {0,0}, 5, {10,5}, 9, {20,0})
        -- -- Frames 0-5: interpolate (0,0)→(10,5)
        -- -- Frames 5-9: interpolate (10,5)→(20,0)
    end)
    
    it("should handle multiple animation numbers", function()
        -- anim_mgr:setPatientMarker({100, 101, 102}, {0,0})
        -- -- All three animations get marker
    end)
    
    it("should convert tile positions to screen pixels", function()
        -- local Map = {WorldToScreen = function(x, y) return x*32, y*32 end}
        -- local pos = {1.5, 2.0}  -- Tile coords
        -- local x, y = Map:WorldToScreen(pos[1]+1, pos[2]+1)
        -- assert.equals(80, x)  -- (1.5+1)*32 = 80
        -- assert.equals(96, y)  -- (2.0+1)*32 = 96
    end)
end)

describe("Draw Flags and Rendering Options", function()
    local DrawFlags = {
        FlipHorizontal = 1,
        FlipVertical = 2,
        Alpha50 = 4,
        Alpha75 = 8,
        AltPalette = 16,
        EarlyList = 1024,
        BoundBoxHitTest = 4096,
        Crop = 8192,
        Nearest = 16384,
    }
    
    it("should combine flags correctly", function()
        -- local flags = DrawFlags.FlipHorizontal + DrawFlags.Alpha50
        -- assert.equals(5, flags)
    end)
    
    it("should handle alpha 50+75 = invisible", function()
        -- local flags = DrawFlags.Alpha50 + DrawFlags.Alpha75
        -- -- In draw_sprite: if both set, skip drawing
    end)
    
    it("should apply alt32 modes for 32bpp effects", function()
        -- local GreyScale = 1<<5  -- 32
        -- local BlueRedSwap = 2<<5  -- 64
        -- -- Used with thdf_alt_palette flag
    end)
end)

describe("Palette Remapping and Ghost Palettes", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should create greyscale remap for palette", function()
        -- local pal_data = string.rep("\0", 768)
        -- local palette = TH.palette(pal_data, false)
        -- local ghost = makeGreyscaleGhost(pal_data)
        -- assert.is_string(ghost)
        -- assert.equals(256, #ghost)
        -- -- Each byte is index of closest grey match
    end)
    
    it("should apply transparent_255 flag", function()
        -- local pal = graphics:_loadPalette("Bitmap", "test.pal", true, false)
        -- -- Entry 255 should be magenta (0xFF00FF) → transparent
    end)
    
    it("should load 8-bit palettes (.pl8)", function()
        -- local pal = graphics:_loadPalette("Bitmap", "test.pl8", false, true)
        -- assert.is_userdata(pal)
    end)
end)

describe("Video Target Updates and Reloading", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "base", "cp437")
    end)
    
    it("should reload all resources on target change", function()
        -- local new_target = createMockRenderTarget()
        -- graphics:updateTarget(new_target)
        -- -- All reload_functions and reload_functions_last called
    end)
    
    it("should reload cursors and fonts after sprite sheets", function()
        -- local sheet_reloads = 0
        -- local cursor_reloads = 0
        -- for res, fn in pairs(graphics.reload_functions) do sheet_reloads = sheet_reloads + 1 end
        -- for res, fn in pairs(graphics.reload_functions_last) do cursor_reloads = cursor_reloads + 1 end
        -- -- Order: sheets first, then cursors/fonts
    end)
end)

describe("Custom Graphics System", function()
    local graphics, app
    
    before_each(function()
        app = createMockApp()
        app.config.use_new_graphics = true
        app.config.new_graphics_folder = "/custom/"
        app.video = createMockRenderTarget()
        graphics = nil  -- Graphics(app, "full", "cp437")
    end)
    
    it("should load file_mapping.txt from custom folder", function()
        -- assert.is_table(graphics.custom_graphics)
        -- assert.is_table(graphics.custom_graphics.file_mapping)
    end)
    
    it("should merge custom animations", function()
        -- local anims = graphics:loadAnimations("Data", "V")
        -- -- Custom .ca files loaded and merged
    end)
    
    it("should handle missing custom graphics gracefully", function()
        -- app.config.new_graphics_folder = "/nonexistent/"
        -- graphics = Graphics(app, "full", "cp437")
        -- -- Should warn but not crash
    end)
end)

-- ============================================================================
-- INTEGRATION TESTS (require full CorsixTH environment)
-- ============================================================================

describe("Integration - Full Graphics Pipeline", function()
    it("should load graphics, create animations, and render frame", function()
        -- pending("Requires full CorsixTH environment")
        -- local app = createMockApp()
        -- local graphics = Graphics(app, "full", "cp437")
        -- local anims = graphics:loadAnimations("Data", "V")
        -- local anim = TH.animation()
        -- anim:setAnimation(anims, 0)
        -- anim:setTile(map, 10, 10, 0)
        -- anim:setPosition(0, 0)
        -- local canvas = createMockRenderTarget()
        -- anim:draw(canvas, {x=320, y=240})
    end)
    
    it("should handle language change with font proxy", function()
        -- pending("Requires full CorsixTH environment")
        -- graphics:onChangeLanguage()
        -- -- Font proxies updated to new bitmap/FreeType instances
    end)
    
    it("should handle UI scale change", function()
        -- pending("Requires full CorsixTH environment")
        -- app.config.ui_scale = 2
        -- graphics:onChangeUIScale()
        -- -- Builtin font and language fonts scaled
    end)
end)

-- ============================================================================
-- HELPER ASSERTIONS
-- ============================================================================

local function assert_userdata(val, typename)
    assert.is_userdata(val)
    -- Could check metatable name if available
end

local function assert_table_contains(t, key, value)
    assert.is_table(t)
    assert.is_not_nil(t[key])
    if value ~= nil then assert.equals(value, t[key]) end
end

-- ============================================================================
-- RUN TESTS
-- ============================================================================

-- busted.run()  -- Called automatically by busted CLI
