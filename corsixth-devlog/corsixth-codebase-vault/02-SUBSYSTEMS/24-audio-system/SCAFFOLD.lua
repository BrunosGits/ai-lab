-- Area 24: Audio System — Busted Test Templates
-- Follows patterns from CorsixTH/Luatest/spec/

require("class_test_base")

-- Mock SDL module
local SDL_mock = {
  audio = {
    init = function(sfont) return true end,
    destroy = function() end,
    playMusic = function(data) return true end,
    stopMusic = function() end,
    pauseMusic = function() return true end,
    resumeMusic = function() return true end,
    setMusicVolume = function(vol) end,
    loadMusicAsync = function(data, cb) cb(data, nil) end,
    transcodeXmiToMid = function(data) return data end,
    findSoundFont = function() return nil end,
  }
}

-- Mock TH module
local TH_mock = {
  soundArchive = function()
    return {
      load = function(self, data) return true end,
      getFilename = function(self, i) return "SOUND_" .. i end,
      getDuration = function(self, i) return 1000 end,
      getFileData = function(self, i) return "" end,
      soundExists = function(self, s) return true end,
      __len = function(self) return 5 end,
    }
  end,
  soundEffects = function()
    return {
      setSoundArchive = function(self, archive) end,
      play = function(self, name, vol, x, y, cb_id, delay, loops) return 1, nil end,
      stop = function(self, handle, cb_id) end,
      togglePause = function(self, handle, cb_id) end,
      isPlaying = function(self, handle) return false end,
      setSoundVolume = function(self, vol) end,
      setSoundEffectsOn = function(self, on) end,
      setCamera = function(self, x, y, r) end,
      reserveChannel = function(self) return 0 end,
      releaseChannel = function(self, ch) end,
    }
  end,
  GetCompileOptions = function() return { midi_device = false } end,
  midiPlayer = function(api, port, sysex) return {} end,
}

-- Stub: Audio class tests
describe("Audio", function()
  local Audio_class, audio_instance

  setup(function()
    _G["TH"] = TH_mock
    _G["SDL"] = SDL_mock
    Audio_class = _G["Audio"]
  end)

  before_each(function()
    local mock_app = {
      config = {
        audio = true,
        play_music = true,
        play_sounds = true,
        sound_volume = 0.5,
        music_volume = 0.5,
        announcement_volume = 0.5,
      },
      fs = {
        listFiles = function(self, ...) return {} end,
        readContents = function(self, ...) return nil, "not found" end,
      },
      video = {
        getRenderSize = function(self) return 800, 600 end,
      },
      findSoundFont = function(self) return nil end,
      ui = {},
    }
    audio_instance = Audio_class(mock_app)
  end)

  describe("constructor", function()
    it("should initialize with has_bg_music false", function()
      assert.is_false(audio_instance.has_bg_music)
    end)

    it("should set not_loaded when audio config is false", function()
      local mock_app_noaudio = {
        config = { audio = false },
      }
      local a = Audio_class(mock_app_noaudio)
      assert.is_true(a.not_loaded)
    end)

    it("should initialize empty callback tables", function()
      assert.same({}, audio_instance.played_sound_callbacks)
      assert.same({}, audio_instance.entities_waiting_for_sound_to_be_enabled)
    end)

    it("should define allowed waveform formats", function()
      assert.is_table(audio_instance.allowed_waveform_formats)
      assert.has_no.errors(function()
        -- Verify OGG, MP3, FLAC are present
        local found = {}
        for _, f in ipairs(audio_instance.allowed_waveform_formats) do
          found[f] = true
        end
        assert.is_true(found["OGG"])
        assert.is_true(found["MP3"])
        assert.is_true(found["FLAC"])
      end)
    end)
  end)

  describe("clearCallbacks", function()
    it("should reset callback state", function()
      audio_instance.unused_played_callback_id = 42
      audio_instance.played_sound_callbacks["42"] = function() end
      audio_instance:clearCallbacks()
      assert.equals(0, audio_instance.unused_played_callback_id)
      assert.same({}, audio_instance.played_sound_callbacks)
    end)
  end)

  describe("playSound", function()
    it("returns nil when sound_fx is not loaded", function()
      audio_instance.sound_fx = nil
      local result = audio_instance:playSound("TEST", nil, false, nil, nil, 1)
      assert.is_nil(result)
    end)

    it("returns a sound table with handle and callback_id", function()
      audio_instance.sound_archive = TH_mock.soundArchive()
      audio_instance.sound_fx = TH_mock.soundEffects()
      audio_instance.sound_fx:setSoundArchive(audio_instance.sound_archive)
      local result = audio_instance:playSound("TEST", nil, false, nil, nil, 1)
      assert.is_table(result)
      assert.is_number(result.handle)
    end)

    it("assigns incrementing callback IDs", function()
      audio_instance.sound_archive = TH_mock.soundArchive()
      audio_instance.sound_fx = TH_mock.soundEffects()
      audio_instance.sound_fx:setSoundArchive(audio_instance.sound_archive)
      local cb = function() end
      audio_instance:playSound("TEST", nil, false, cb, nil, 1)
      assert.equals(1, audio_instance.unused_played_callback_id)
      audio_instance:playSound("TEST2", nil, false, cb, nil, 1)
      assert.equals(2, audio_instance.unused_played_callback_id)
    end)
  end)

  describe("stopSound", function()
    it("does not error when sound_fx is nil", function()
      audio_instance.sound_fx = nil
      assert.has_no.errors(function()
        audio_instance:stopSound({handle = 1})
      end)
    end)
  end)

  describe("isPlaying", function()
    it("returns false when sound_fx is nil", function()
      audio_instance.sound_fx = nil
      assert.is_false(audio_instance:isPlaying({handle = 1}))
    end)
  end)

  describe("setSoundVolume", function()
    it("updates config.sound_volume", function()
      audio_instance.sound_fx = TH_mock.soundEffects()
      audio_instance:setSoundVolume(0.8)
      assert.equals(0.8, audio_instance.app.config.sound_volume)
    end)
  end)

  describe("setBackgroundVolume", function()
    it("updates config.music_volume", function()
      audio_instance:setBackgroundVolume(0.7)
      assert.equals(0.7, audio_instance.app.config.music_volume)
    end)
  end)

  describe("soundExists", function()
    it("returns false when sound_archive is nil", function()
      audio_instance.sound_archive = nil
      assert.is_false(audio_instance:soundExists("TEST"))
    end)

    it("delegates to sound_archive when loaded", function()
      audio_instance.sound_archive = TH_mock.soundArchive()
      assert.is_true(audio_instance:soundExists("TEST"))
    end)
  end)

  describe("initSpeech", function()
    it("does not error when not_loaded is true", function()
      audio_instance.not_loaded = true
      assert.has_no.errors(function()
        audio_instance:initSpeech("Sound-0.dat")
      end)
    end)
  end)

  describe("reserveChannel", function()
    it("returns -1 when sound_fx is nil", function()
      audio_instance.sound_fx = nil
      assert.equals(-1, audio_instance:reserveChannel())
    end)
  end)

  describe("playSoundEffects", function()
    it("updates config.play_sounds", function()
      audio_instance.sound_fx = TH_mock.soundEffects()
      audio_instance:playSoundEffects(false)
      assert.is_false(audio_instance.app.config.play_sounds)
    end)
  end)

  describe("onEndPause", function()
    it("calls tellInterestedEntities when play_sounds is enabled", function()
      audio_instance.app.config.play_sounds = true
      local called = false
      audio_instance.entities_waiting_for_sound_to_be_enabled = {
        [1] = function() called = true end
      }
      audio_instance:onEndPause()
      assert.is_true(called)
    end)
  end)
end)
