--WINDOW
Window = {}
do
  local pre_fs_size = {}
  local last_win_size = {0, 0}
  local setMode = function(w, h, flags)
    if not (not flags and last_win_size[1] == w and last_win_size[2] == h) then
      love.window.setMode(w, h, flags or Game.options.window_flags)
    end
  end
  Window = {
    width = 1,
    height = 1,
    os = nil,
    aspect_ratio = nil,
    aspect_ratios = {{4, 3}, {5, 4}, {16, 10}, {16, 9}},
    resolutions = {512, 640, 800, 1024, 1280, 1366, 1920},
    aspectRatio = function()
      local w, h = love.window.getDesktopDimensions()
      for _, ratio in ipairs(Window.aspect_ratios) do
        if w * (ratio[2] / ratio[1]) == h then
          Window.aspect_ratio = ratio
          return ratio
        end
      end
    end,
    vsync = function(v)
      if not ge_version(11, 3) then
        return
      end
      if not v then
        return love.window.getVSync()
      else
        love.window.setVSync(v)
      end
    end,
    setSize = function(r, flags)
      local w, h = Window.calculateSize(r)
      setMode(w, h, flags)
    end,
    setExactSize = function(w, h, flags)
      setMode(w, h, flags)
    end,
    calculateSize = function(r)
      r = r or Game.config.window_size
      if not Window.aspect_ratio then
        Window.aspectRatio()
      end
      local w = Window.resolutions[r]
      local h = w / Window.aspect_ratio[1] * Window.aspect_ratio[2]
      return w, h
    end,
    fullscreen = function(v, fs_type)
      local res
      if v == nil then
        res = love.window.getFullscreen()
      else
        if not Window.fullscreen() then
          pre_fs_size = {Game.width, Game.height}
        end
        res = love.window.setFullscreen(v, fs_type)
      end
      Game.updateWinSize(unpack(pre_fs_size))
      return res
    end,
    toggleFullscreen = function()
      local res = Window.fullscreen(not Window.fullscreen())
      if res then
        if not Window.fullscreen() then
          Window.setExactSize(unpack(pre_fs_size))
        end
      end
      return res
    end
  }
end