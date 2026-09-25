-- 34-movie-player SCAFFOLD (template only, not executed)
local MoviePlayer = {}
MoviePlayer.__index = MoviePlayer

function MoviePlayer:new(app) -- cf. movie_player.lua:156
  return setmetatable({ app = app, playing = false, wait_for_stop = false }, self)
end

function MoviePlayer:playMovie(file, wait_for_stop, cb) -- cf. :289
  if file == nil or not self.backend:getEnabled() or not self.app.config.movies then
    if cb then cb() end -- fail-open gate
    return
  end
  local ok, warn = self.backend:load(file)
  if warn ~= "" then self.app:log(warn) end
  if not ok then if cb then cb() end return end
  self.on_destroy = cb
  self.wait_for_stop, self.wait_for_over = wait_for_stop, true
  self.backend:play()
  self.playing = true
end

function MoviePlayer:refresh() -- cf. :393 + App:drawFrame
  local x, y, w, h = self:letterbox() -- cf. calculateSize :43
  local pts = self.backend:refresh(x, y, w, h)
  if self.overlay then self.overlay(pts) end -- cf. loseMovieOverlay :106
end

function MoviePlayer:onMovieOver() -- cf. :372, via SDL_USEREVENT_MOVIE_OVER
  self.wait_for_over = false
  if not self.wait_for_stop then self:destroy() end
end

function MoviePlayer:stop() -- cf. :383, UI click/Esc
  self.backend:stop()
  self.wait_for_stop = false
  if not self.wait_for_over then self:destroy() end
end

function MoviePlayer:destroy() -- cf. destroyMovie :83
  self.backend:unload()
  self.playing = false
  local cb = self.on_destroy self.on_destroy = nil
  if cb then cb() end
end
return MoviePlayer
