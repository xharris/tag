--[[SPATIALHASH
SpatialHash = nil
do
  function get_keys(x,y,w,h,size)
  local key_added = {}
  local keys = {}

  -- generate keys for the four corners
  for mx = 0, 1 do 
    for my = 0, 1 do 
    local key = Math.floor(((x + (w*mx)) / size) + 0.5) * size .. ',' .. Math.floor(((y + (h*my)) / size) + 0.5) * size
    if not key_added[key] then 
      key_added[key] = true 
      table.insert(keys, key)
    end
    end 
  end 

  return keys
  end 

  SpatialHash = class {
  SIZE = 60,
  init = function(self, size)
    self.size = size or SpatialHash.SIZE
    self.hash = {}
  end,
  add = function(self, obj) 
    local keys = get_keys(obj.pos[1], obj.pos[2], obj.size[1], obj.size[2], self.size)
    for _, key in ipairs(keys) do 
    if not self.hash[key] then self.hash[key] = {} end 
    table.insert(self.hash[key], obj)
    end 
  end,
  getNearby = function(self, obj)
    local keys = get_keys(obj.pos[1], obj.pos[2], obj.size[1], obj.size[2], self.size)
    local objects = {}
    for _, key in ipairs(keys) do 
    local hash_list = self.hash[key]
    for _, obj2 in ipairs(hash_list) do 
      table.insert(objects, obj2)
    end 
    end 
    return objects
  end 
  }
end
]] --

local changed_cache = {}
local last_value_cache = {}
function changed(t, k)
  local last_val
  local key = tostring(t) .. tostring(k)
  if changed_cache[key] then
    return changed_cache[key]
  end
  if last_value_cache[key] ~= t[k] then
    last_val = last_value_cache[ke]
    last_value_cache[key] = t[k]
    changed_cache[key] = true
  end
  return changed_cache[key], last_val
end

function reset(t, k)
  local key = tostring(t) .. tostring(k)
  last_value_cache[key] = t[k]
  changed_cache[key] = false
end

--INPUT
Input = nil
mouse_x, mouse_y = 0, 0
do
  local name_to_input = {} -- name -> { key1: t/f, mouse1: t/f }
  local input_to_name = {} -- key -> { name1, name2, ... }
  local options = {
    no_repeat = {},
    combo = {}
  }
  local groups = {}
  local pressed = {}
  local released = {}
  local store = {}
  local key_assoc = {
    lalt = "alt",
    ralt = "alt",
    ["return"] = "enter",
    kpenter = "enter",
    lgui = "gui",
    rgui = "gui"
  }

  local joycheck = function(info)
    if not info or not info.joystick then
      return info
    end
    if Joystick.using == 0 then
      return info
    end
    if Joystick.get(Joystick.using):getID() == info.joystick:getID() then
      return info
    end
  end

  local isPressed = function(name)
    if Input.group then
      name = Input.group .. "." .. name
    end
    if
      not (table.hasValue(options.no_repeat, name) and pressed[name] and pressed[name].count > 1) and
        joycheck(pressed[name])
     then
      return pressed[name]
    end
  end

  local isReleased = function(name)
    if Input.group then
      name = Input.group .. "." .. name
    end
    if joycheck(released[name]) then
      return released[name]
    end
  end

  Input =
    callable {
    __call = function(self, name)
      return store[name] or pressed[name] or released[name]
    end,
    group = nil,
    store = function(name, value)
      store[name] = value
    end,
    set = function(inputs, _options)
      _options = _options or {}
      for name, inputs in pairs(inputs) do
        Input.setInput(name, inputs, _options.group)
      end

      if _options.combo then
        table.append(options.combo, _options.combo or {})
      end
      if _options.no_repeat then
        table.append(options.no_repeat, _options.no_repeat or {})
      end

      return nil
    end,
    setInput = function(name, inputs, group)
      if group then
        name = group .. "." .. name
      end
      local input_group_str = name
      name_to_input[name] = {}
      for _, i in ipairs(inputs) do
        name_to_input[name][i] = false
      end
      for _, i in ipairs(inputs) do
        if not input_to_name[i] then
          input_to_name[i] = {}
        end
        if not table.hasValue(input_to_name[i], name) then
          table.insert(input_to_name[i], name)
        end
      end
    end,
    pressed = function(...)
      local ret = {}
      local args = {...}
      local val
      for _, name in ipairs(args) do
        val = isPressed(name)
        if val then
          table.insert(ret, val)
        end
      end
      if #ret > 0 then
        return ret
      end
    end,
    released = function(...)
      local ret = {}
      local args = {...}
      local val
      for _, name in ipairs(args) do
        val = isReleased(name)
        if val then
          table.insert(ret, val)
        end
      end
      if #ret > 0 then
        return ret
      end
    end,
    press = function(key, extra)
      if key_assoc[key] then
        Input.press(key_assoc[key], extra)
      end
      if input_to_name[key] then
        for _, name in ipairs(input_to_name[key]) do
          local n2i = name_to_input[name]
          if not n2i then
            name_to_input[name] = {}
          end
          n2i = name_to_input[name]
          n2i[key] = true
          -- is input pressed now?
          combo = table.hasValue(options.combo, name)
          if (combo and table.every(n2i)) or (not combo and table.some(n2i)) then
            pressed[name] = extra
            pressed[name].count = 1
          end
        end
      end
    end,
    release = function(key, extra)
      if key_assoc[key] then
        Input.release(key_assoc[key], extra)
      end
      if input_to_name[key] then
        for _, name in ipairs(input_to_name[key]) do
          local n2i = name_to_input[name]
          if not n2i then
            name_to_input[name] = {}
          end
          n2i = name_to_input[name]
          n2i[key] = false
          -- is input released now?
          combo = table.hasValue(options.combo, name)
          if pressed[name] and (combo or not table.some(n2i)) then
            pressed[name] = nil
            released[name] = extra
          end
        end
      end
    end,
    keyCheck = function()
      for name, info in pairs(pressed) do
        info.count = info.count + 1
      end
      released = {}
      store["wheel"] = nil
    end

    -- mousePos = function() return love.mouse.getPosition() end;
  }
end

--JOYSTICK
Joystick = nil
local refreshJoystickList
do
  local joysticks = {}
  refreshJoystickList = function()
    joysticks = love.joystick.getJoysticks()
  end

  Joystick = {
    using = 0,
    get = function(i)
      if i > 0 and i < #joysticks then
        return joysticks[i]
      end
    end,
    -- affects all future Input() gamepad checks
    use = function(i)
      Joystick.using = i or 0
    end
  }
end



--AUDIO
Audio = nil
Source = nil
do
  local default_opt = {
    type = "static"
  }
  local defaults = {}
  local sources = {}
  local play_queue = {}
  local first_update = true

  local opt = function(name, overrides)
    if not defaults[name] then
      Audio(name, {})
    end
    return defaults[name]
  end
  Source =
    class {
    init = function(self, name, options)
      self.name = name
      local o = opt(name)
      if options then
        o = table.update(o, options)
      end

      if Window.os == "web" then
        o.type = "static"
      end

      self.src =
        Cache.get(
        "Audio.source",
        name,
        function(key)
          return love.audio.newSource(Game.res("audio", o.file), o.type)
        end
      ):clone()

      if not sources[name] then
        sources[name] = {}
      end

      if o then
        table.insert(sources[name], self)
        local props = {
          "position",
          "looping",
          "volume",
          "airAbsorption",
          "pitch",
          "relative",
          "rolloff",
          "effect",
          "filter"
        }
        local t_props = {"attenuationDistances", "cone", "direction", "velocity", "volumeLimits"}
        for _, n in ipairs(props) do
          local fn_name = n:capitalize()
          -- setter
          if not self["set" .. fn_name] then
            self["set" .. fn_name] = function(self, ...)
              return self.src["set" .. fn_name](self.src, ...)
            end
          end
          -- getter
          if not self["get" .. fn_name] then
            self["get" .. fn_name] = function(self, ...)
              return self.src["get" .. fn_name](self.src, ...)
            end
          end

          if o[n] then
            self["set" .. fn_name](self, o[n])
          end
        end
        for _, n in ipairs(t_props) do
          local fn_name = n:capitalize()
          -- setter
          if not self["set" .. fn_name] then
            self["set" .. fn_name] = function(self, ...)
              local args = {...}

              if fn == "position" then
                for i, v in ipairs(args) do
                  args[i] = v / Audio.hearing
                end
              end

              return self.src["set" .. fn_name](self.src, unpack(args))
            end
          end
          -- getter
          if not self["get" .. fn_name] then
            self["get" .. fn_name] = function(self, ...)
              return self.src["get" .. fn_name](self.src, ...)
            end
          end

          if o[n] then
            self["set" .. fn_name](self, unpack(o[n]))
          end
        end
      end
    end,
    setPosition = function(self, opt)
      self.position = opt or self.position
      if opt then
        self.src:setPosition(
          (opt.x or 0) / Audio._hearing,
          (opt.y or 0) / Audio._hearing,
          (opt.z or 0) / Audio._hearing
        )
      end
    end,
    play = function(self)
      love.audio.play(self.src)
    end,
    stop = function(self)
      love.audio.stop(self.src)
    end,
    isPlaying = function(self)
      return self.src:isPlaying()
    end
  }
  Audio =
    callable {
    __call = function(self, file, ...)
      option_list = {...}
      for _, options in ipairs(option_list) do
        store_name = options.name or file
        options.file = file
        if not defaults[store_name] then
          defaults[store_name] = {}
        end
        new_tbl = copy(default_opt)
        table.update(new_tbl, options)
        table.update(defaults[store_name], new_tbl)

        Audio.source(store_name)
      end
    end,
    _hearing = 6,
    hearing = function(h)
      Audio._hearing = h or Audio._hearing
      for name, src_list in pairs(sources) do
        for _, src in ipairs(src_list) do
          src:setPosition()
        end
      end
    end,
    update = function(dt)
      if #play_queue > 0 then
        for _, src in ipairs(play_queue) do
          src:play()
        end
        play_queue = {}
      end
    end,
    source = function(name, options)
      return Source(name, options)
    end,
    play = function(name, options)
      local new_src = Audio.source(name, options)
      table.insert(play_queue, new_src)
      return new_src
    end,
    stop = function(...)
      names = {...}
      if #names == 0 then
        love.audio.stop()
      else
        for _, n in ipairs(names) do
          if sources[n] then
            for _, src in ipairs(sources[n]) do
              src:stop()
            end
          end
        end
      end
    end,
    isPlaying = function(name)
      if sources[name] then
        local t = {}
        for _, src in ipairs(sources[name]) do
          if src:isPlaying() then
            return true
          end
        end
      end
      return false
    end
  }

  local audio_fns = {"volume", "velocity", "position", "orientation", "effect", "dopplerScale"}
  for _, fn in ipairs(audio_fns) do
    local fn_capital = fn:capitalize()
    Audio[fn] = function(...)
      local args = {...}

      if fn == "position" then
        local pos = args[1]

        args = {
          (pos.x or 0) / Audio._hearing,
          (pos.y or 0) / Audio._hearing,
          (pos.z or 0) / Audio._hearing
        }
      end

      if #args > 0 then
        love.audio["set" .. fn_capital](unpack(args))
      else
        return love.audio["get" .. fn_capital]()
      end
    end
  end
end

--CAMERA
Camera = nil
do
  local dist, sqrt = Math.distance, math.sqrt

  local default_opt = {
    pos = {0, 0},
    offsetx = 0,
    offsety = 0,
    viewx = 0,
    viewy = 0,
    z = 0,
    dx = 0,
    dy = 0,
    angle = 0,
    zoom = nil,
    scalex = 1,
    scaley = nil,
    top = 0,
    left = 0,
    width = nil,
    height = nil,
    follow = nil,
    enabled = true,
    auto_use = true,

    _half_w = 0,
    _half_h = 0
  }
  local attach_count = 0
  local options = {}
  local cam_stack = {}

  Camera = callable {
    transform = nil,
    __call = function(self, name, opt)
      if not options[name] then 
        default_opt.width = Game.width
        default_opt.height = Game.height
        options[name] = copy(default_opt)

        local o = options[name]
        o.transform = love.math.newTransform()
        o.name = name
        o.mouse = function()
          return mouse_x + o.pos[1] - o.viewx - o._half_w, --,
                 mouse_y + o.pos[2] - o.viewy - o._half_h -- 
        end
      end

      if opt then 
        table.update(options[name], opt)
      end
      if changed(options[name], 'z') then
        sort(options, "z", 0)
      end
      return options[name]
    end,
    get = function(name)
      return assert(options[name], "Camera :'" .. name .. "' not found")
    end,
    coords = function(name, x, y)
      local o = Camera.get(name)
      if o then
        return x + (o.offsetx or 0), y + (o.offsety or 0)
      end
      return x, y
    end,
    attach = function(name)
      local o = Camera.get(name)
      Draw.push()
      if o.enabled == false then
        return
      end
      if o then
        local w, h = o.width or Game.width, o.height or Game.height
        local pos = o.pos
        if o.follow then
          pos[1] = o.follow.pos[1] or o.pos[1]
          pos[2] = o.follow.pos[2] or o.pos[2]
        end
        local half_w, half_h = floor(w / 2), floor(h / 2)
        o._half_w, o._half_h = half_w, half_h

        if o.crop then
          Draw.crop(o.viewx, o.viewy, w, h)
        end
        o.transform:reset()
        o.transform:translate(half_w + o.viewx, half_h + o.viewy)
        o.transform:scale(o.zoom or o.scalex, o.zoom or o.scaley or o.scalex)
        o.transform:rotate(o.angle)
        o.transform:translate(-floor(pos[1] - o.left + o.dx), -floor(pos[2] - o.top + o.dy))

        o.offsetx = -(floor(half_w) - floor(pos[1] - o.left + o.dx))
        o.offsety = -(floor(half_h) - floor(pos[2] - o.top + o.dy))

        Camera.transform = o.transform
        love.graphics.replaceTransform(o.transform)

        table.insert(cam_stack, name)
      end
    end,
    detach = function()
      Draw.pop()
      Camera.transform = nil
      table.remove(cam_stack)
    end,
    use = function(name, fn)
      Camera.attach(name)
      fn()
      Camera.detach()
    end,
    count = function()
      return table.len(options)
    end,
    useAll = function(fn)
      for name, opt in pairs(options) do
        if opt.auto_use then
          Camera.use(name, fn)
        else
          fn()
        end
      end
    end,
    visible = function(x,y,w,h)
      if x and not y and x.pos and x.scaled_size then 
        if x.classname == "Blanke.SpriteBatch" then return true end
        x, y, w, h = x.pos[1], x.pos[2], x.scaled_size[1], x.scaled_size[2]
      end
      local o, cam_diag, obj_dist
      for _, name in ipairs(cam_stack) do
        o = options[name]
        if true or o.crop then -- TODO remove true
          if changed(o, 'width') or changed(o, 'height') then 
            o.diag = sqrt((o.width^2) + (o.height^2)) / 2
          end
          obj_dist = dist(x, y, o.pos[1], o.pos[2])
          if o.diag >= obj_dist then 
            return true
          end 
        end
      end
      return false
    end
  }
end

System(
  All("camera"),
  {
    added = function(ent)
      local cam = Camera(ent.camera)
      cam.follow = ent
    end
  }
)

--FEATURE
Feature = {}
do
  local enabled = {}
  Feature =
    callable {
    -- returns true if feature is enabled
    __call = function(self, name)
      return enabled[name] ~= false
    end,
    disable = function(...)
      local flist = {...}
      for _, f in ipairs(flist) do
        enabled[f] = false
      end
    end,
    enable = function(...)
      local flist = {...}
      for _, f in ipairs(flist) do
        enabled[f] = true
      end
    end
  }
end

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

--GAME
Game = nil
do
  Game =
    callable {
    options = {
      res = "assets",
      scripts = {},
      filter = "linear",
      vsync = "on",
      auto_require = true,
      background_color = "black",
      window_flags = {},
      fps = 60,
      round_pixels = false,
      auto_system = true, -- if an Entity has update/draw props, automatically make a system?
      auto_draw = true,
      scale = true,
      effect = nil,
      load = function()
      end,
      draw = nil,
      postdraw = nil,
      update = function(dt)
      end
    },
    config = {},
    restarting = false,
    width = 0,
    height = 0,
    time = 0,
    love_version = {0, 0, 0},
    loaded = {
      all = false,
      settings = false,
      scripts = false,
      assets = false
    },
    __call = function(_, args)
      table.update(Game.options, args)
      return Game
    end,
    updateWinSize = function(w, h)
      Window.width, Window.height, flags = love.window.getMode()
      if w and h then
        Window.width, Window.height = w, h
      end
      if not Window.width then
        Window.width = Game.width
      end
      if not Window.height then
        Window.height = Game.height
      end

      if Window.os == "web" then
        Game.width, Game.height = Window.width, Window.height
      end
      -- if not Game.options.scale then
      --   Game.width, Game.height = Window.width, Window.height
      --   if Blanke.game_canvas then
      --     Blanke.game_canvas.size = {Game.width, Game.height}
      --     Blanke.game_canvas:resize()
      --   end

      --   local canv
      --   for c = 1, #CanvasStack.stack do
      --     canv = CanvasStack.stack[c].value
      --     canv.size = {Window.width, Window.height}
      --     canv:resize()
      --   end
      -- end
      -- if Blanke.game_canvas then
      -- --Blanke.game_canvas.align = {Game.width/2, Game.height/2}
      -- end
    end,
    load = function(which)
      if Game.restarting then
        Signal.emit("Game.restart")
      end

      if not Game.loaded.settings and which == "settings" or not which then
        Game.time = 0
        Game.love_version = {love.getVersion()}
        love.joystick.loadGamepadMappings("gamecontrollerdb.txt")

        -- load config.json
        local f_config = FS.open("config.json")
        config_data = love.filesystem.read("config.json")
        if config_data then
          Game.config = json.decode(config_data)
        end
        table.update(Game.options, Game.config.export)

        -- get current os
        if not Window.os then
          Window.os =
            ({
            ["OS X"] = "mac",
            ["Windows"] = "win",
            ["Linux"] = "linux",
            ["Android"] = "android",
            ["iOS"] = "ios"
          })[love.system.getOS()]
           -- Game.options.os or 'ide'
          Window.full_os = love.system.getOS()
        end
        -- load settings
        if Window.os ~= "web" then
          Game.width, Game.height = Window.calculateSize(Game.config.game_size) -- game size
        end
        -- disable effects for web (SharedArrayBuffer or whatever)
        if Window.os == "web" then
          Feature.disable("effect")
        end
        if not Game.loaded.settings then
          if not Game.restarting then
            -- window size and flags
            Game.options.window_flags =
              table.update(
              {
                borderless = Game.options.frameless,
                resizable = Game.options.resizable
              },
              Game.options.window_flags or {}
            )

            if Window.os ~= "web" then
              Window.setSize(Game.config.window_size)
            end
            Game.updateWinSize()
          end
          -- vsync
          switch(
            Game.options.vsync,
            {
              on = function()
                Window.vsync(1)
              end,
              off = function()
                Window.vsync(0)
              end,
              adaptive = function()
                Window.vsync(-1)
              end
            }
          )

          if type(Game.options.filter) == "table" then
            love.graphics.setDefaultFilter(unpack(Game.options.filter))
          else
            love.graphics.setDefaultFilter(Game.options.filter, Game.options.filter)
          end
        end

        Save.load()
      end

      if not Game.loaded.assets and which == "assets" or not which then
        Draw.setFont("04B_03.ttf", 16)
      end

      if not Game.loaded.scripts and which == "scripts" or not which then
        local scripts = Game.options.scripts or {}
        local no_user_scripts = (#scripts == 0)
        -- load plugins
        if Game.options.plugins then
          for _, f in ipairs(Game.options.plugins) do
            package.loaded["plugins." .. f] = nil
            require("plugins." .. f)
            -- table.insert(scripts,'lua/plugins/'..f..'/init.lua') -- table.insert(scripts,'plugins.'..f)
          end
        end
        -- load scripts
        if Game.options.auto_require and no_user_scripts then
          local load_folder
          load_folder = function(path)
            if path:starts("/.") then
              return
            end
            files = FS.ls(path)

            local dirs = {}

            for _, f in ipairs(files) do
              local file_path = path .. "/" .. f
              if FS.extname(f) == "lua" and not table.hasValue(scripts, file_path) then
                table.insert(scripts, file_path) -- table.join(string.split(FS.removeExt(file_path), '/'),'.'))
              end
              local info = FS.info(file_path)
              if info.type == "directory" and file_path ~= "/dist" and file_path ~= "/lua" then
                table.insert(dirs, file_path)
              end
            end

            -- load directories
            for _, d in ipairs(dirs) do
              load_folder(d)
            end
          end
          load_folder("")
        end

        for _, script in ipairs(scripts) do
          if not script:contains("main.lua") and not script:contains("blanke/init.lua") then
            local ok, chunk = pcall(love.filesystem.load, script)
            if not ok then
              error(chunk)
            end
            assert(chunk, "Script not found: " .. script)
            local ok2, result = pcall(chunk)
            if not ok2 then
              error('error loading "'..script..'"\n'..result)
            end
          -- require(script)
          end
        end
      end

      if not Game.loaded.settings and which == "settings" or not which then
        -- fullscreen toggle
        Input.set(
          {_fs_toggle = {"alt", "enter"}},
          {
            combo = {"_fs_toggle"},
            no_repeat = {"_fs_toggle"}
          }
        )
        if Game.options.fullscreen == true and not Game.restarting then
          Window.fullscreen(true)
        end
        if Game.options.load then
          Game.options.load()
        end
        -- round pixels
        if not Game.options.round_pixels then
          floor = function(x)
            return x
          end
        end

        love.graphics.setBackgroundColor(1, 1, 1, 0)

        Blanke.game_canvas = Canvas {draw=false, is_game_canvas=true}

        -- effect
        if Game.options.effect then
          Game.setEffect(unpack(Game.options.effect))
        end
      end

      -- is everything loaded?
      Game.loaded.all = true
      for k, v in pairs(Game.loaded) do
        if which == k or not which then
          Game.loaded[k] = true
        end
        if k ~= "all" and Game.loaded[k] == false then
          Game.loaded.all = false
        end
      end

      if Game.loaded.all then
        Signal.emit("Game.load")

        if Game.options.initial_state then
          Scene.start(Game.options.initial_state)
        end
      end

      if Game.restarting then
        Game.updateWinSize()
      end
      Signal.emit("Game.start")
    end,
    restart = function()
      Scene.stop()
      Timer.stop()
      Audio.stop()
      for _, obj in ipairs(Game.all_objects) do
        if obj then
          obj:destroy()
        end
      end
      objects = {}
      Game.all_objects = {}
      Game.updatables = {}
      Game.drawables = {}
      Game.loaded = {
        all = false,
        settings = false,
        scripts = false,
        assets = false
      }

      Game.restarting = true
    end,
    forced_quit = false,
    quit = function(force, status)
      Game.forced_quit = force
      love.event.quit(status)
    end,
    setEffect = function(...)
      Add(Blanke.game_canvas, "effect", {...})
    end,
    res = function(_type, file)
      if file == nil then
        error("Game.res(), nil given for " .. _type)
      end
      if file:contains(Game.options.res .. "/" .. _type) then
        return file
      end
      return Game.options.res .. "/" .. _type .. "/" .. file
    end,
    setBackgroundColor = function(...)
      --love.graphics.setBackgroundColor(Draw.parseColor(...))
      Game.options.background_color = {Draw.parseColor(...)}
    end,
    update = function(dt)
      local dt_ms = dt * 1000

      mouse_x, mouse_y = love.mouse.getPosition()
      if Game.options.scale == true then
        local scalex, scaley = Window.width / Game.width, Window.height / Game.height
        Blanke.scale = math.min(scalex, scaley)
        Blanke.padx, Blanke.pady = 0, 0
        if scalex > scaley then
          Blanke.padx = floor((Window.width - (Game.width * Blanke.scale)) / 2)
        else
          Blanke.pady = floor((Window.height - (Game.height * Blanke.scale)) / 2)
        end
        -- offset mouse coordinates
        mouse_x = floor((mouse_x - Blanke.padx) / Blanke.scale)
        mouse_y = floor((mouse_y - Blanke.pady) / Blanke.scale)
      end

      Game.time = Game.time + dt
      Physics.update(dt)
      Timer.update(dt, dt_ms)
      if Game.options.update(dt) == true then
        return
      end
      
      --love.profiler:attach()
      World.update(dt)
      Scene.update(dt)
      --love.profiler:detach()

      Scene._check()
      Signal.emit("update", dt, dt_ms)
      Input.group = nil
      local key = Input.pressed("_fs_toggle")
      if key and key[1].count == 1 then
        Window.toggleFullscreen()
      end
      Input.keyCheck()
      Audio.update(dt)

      BFGround.update(dt)

      if Game.restarting then
        Game.load()
        Game.restarting = false
      end
      changed_cache = {}
    end
  }
end

--BLANKE
Blanke = nil
do
  local update_obj = Game.updateObject
  local stack = Draw.stack

  local _drawGame = function()
    Draw.push()
    Draw.reset()
    Draw.color(Game.options.background_color)
    Draw.rect("fill", 0, 0, Game.width, Game.height)
    Draw.pop()

    -- Background.draw()
    -- if Camera.count() > 0 then
    --   Camera.useAll(actual_draw)
    -- else

    World.draw()
    if Game.options.postdraw then
      Game.options.postdraw()
    end
    Physics.drawDebug()
    Hitbox.draw()

    -- end
    -- Foreground.draw()
  end

  local _draw = function()
    if Game.options.draw then
      Game.options.draw(_drawGame)
    else
      _drawGame()
    end
  end

  Blanke = {
    config = {},
    game_canvas = nil,
    loaded = false,
    scale = 1,
    padx = 0,
    pady = 0,
    load = function()
      if not Blanke.loaded then
        Blanke.loaded = true
        if not Game.loaded.all then
          Game.load()
        end
      end
    end,
    --blanke.update
    update = function(dt)
      Game.update(dt)
    end,
    --blanke.draw
    draw = function()
      if not Game.loaded.all then
        return
      end
      Game.is_drawing = true
      Draw.origin()

      -- Blanke.game_canvas:renderTo(_draw)

      Draw.push()
      Draw.color("black")
      Draw.rect("fill", 0, 0, Window.width, Window.height)
      Draw.pop()

      --Blanke.game_canvas.align = {Game.width/2, Game.height/2}
      -- if Game.options.scale == true then
      --   Blanke.game_canvas.pos = {
      --     Blanke.padx,
      --     Blanke.pady
      --   }
      --   Blanke.game_canvas.scale = Blanke.scale

      --   love.graphics.draw(Blanke.game_canvas)
      -- else
      --   love.graphics.draw(Blanke.game_canvas)
      -- end
      _draw()

      if Game.debug then 
        World.drawDebug()
      end 

      Game.is_drawing = false
    end,
    resize = function(w, h)
      Game.updateWinSize()
    end,
    keypressed = function(key, scancode, isrepeat)
      Input.press(key, {scancode = scancode, isrepeat = isrepeat})
    end,
    keyreleased = function(key, scancode)
      Input.release(key, {scancode = scancode})
    end,
    mousepressed = function(x, y, button, istouch, presses)
      Input.press("mouse", {x = x, y = y, button = button, istouch = istouch, presses = presses})
      Input.press(
        "mouse" .. tostring(button),
        {x = x, y = y, button = button, istouch = istouch, presses = presses}
      )
    end,
    mousereleased = function(x, y, button, istouch, presses)
      Input.press("mouse", {x = x, y = y, button = button, istouch = istouch, presses = presses})
      Input.release(
        "mouse" .. tostring(button),
        {x = x, y = y, button = button, istouch = istouch, presses = presses}
      )
    end,
    wheelmoved = function(x, y)
      Input.store("wheel", {x = x, y = y})
    end,
    gamepadpressed = function(joystick, button)
      Input.press("gp." .. button, {joystick = joystick})
    end,
    gamepadreleased = function(joystick, button)
      Input.release("gp." .. button, {joystick = joystick})
    end,
    joystickadded = function(joystick)
      Signal.emit("joystickadded", joystick)
      refreshJoystickList()
    end,
    joystickremoved = function(joystick)
      Signal.emit("joystickremoved", joystick)
      refreshJoystickList()
    end,
    gamepadaxis = function(joystick, axis, value)
      Input.store("gp." .. axis, {joystick = joystick, value = value})
    end,
    touchpressed = function(id, x, y, dx, dy, pressure)
      Input.press("touch", {id = id, x = x, y = y, dx = dx, dy = dy, pressure = pressure})
    end,
    touchreleased = function(id, x, y, dx, dy, pressure)
      Input.release("touch", {id = id, x = x, y = y, dx = dx, dy = dy, pressure = pressure})
    end
  }
end

--TIMER
Timer = nil
do
  local clamp = Math.clamp

  local l_after = {}
  local l_every = {}
  local addTimer = function(t, fn, tbl)
    local id = uuid()
    local timer = {
      fn = fn,
      duration = t,
      t = t,
      iteration = 1,
      paused = false,
      scene_created = Scene.current,
      destroy = function()
        tbl[id] = nil
      end
    }
    tbl[id] = timer
    return timer
  end

  Timer = {
    update = function(dt, dt_ms)
      -- after
      for id, timer in pairs(l_after) do
        if not timer.paused then
          timer.t = timer.t - dt_ms
          timer.p = clamp((timer.duration - timer.t) / timer.duration, 0, 1)
          if timer.t < 0 then
            local new_t = timer.fn and timer.fn(timer)
            if new_t then
              -- another one (restart timer)
              timer.duration = (type(new_t) == "number" and new_t or timer.duration)
              timer.t = timer.duration
              timer.iteration = timer.iteration + 1
            else
              -- destroy it
              timer.destroy()
            end
          end
        end
      end
      -- every
      for id, timer in pairs(l_every) do
        if not timer.paused then
          timer.t = timer.t - dt_ms
          timer.p = clamp((timer.duration - timer.t) / timer.duration, 0, 1)
          if timer.t < 0 then
            if not timer.fn or timer.fn(timer) then
              -- destroy it!
              timer.destroy()
            else
              -- restart timer
              timer.t = timer.duration
              timer.iteration = timer.iteration + 1
            end
          end
        end
      end
    end,
    after = function(t, fn)
      assert(t, "Timer duration is nil")
      return addTimer(t, fn, l_after)
    end,
    every = function(t, fn)
      assert(t, "Timer duration is nil")
      return addTimer(t, fn, l_every)
    end,
    stop = function(state_name)
      for _, tmr in pairs(l_after) do
        if not state_name or tmr.scene_created == state_name then
          tmr.destroy()
        end
      end
      for _, tmr in pairs(l_every) do
        if not state_name or tmr.scene_created == state_name then
          tmr.destroy()
        end
      end
    end
  }
end

--CANVAS
Canvas = class {
    auto_clear = true,
    drawable = true,
    blendmode = {"alpha"},
    debug_color = "blue",
    init = function(ent, opts)
      table.update(self, opts)
      if ent.size[1] <= 0 then
        ent.size[1] = Game.width
      end
      if ent.size[2] <= 0 then
        ent.size[2] = Game.height
      end

      local canvas = love.graphics.newCanvas(unpack(ent.size))
      if ent.filter then 
        canvas:setFilter(unpack(ent.filter))
      end 
      ent.active = false
      ent.drawable = canvas

      local lg = love.graphics
      ent.renderTo = function(self, fn)
        if fn then
          lg.push("all")
          self.active = true
          lg.setCanvas {self.drawable}
          if self.auto_clear then
            lg.clear(self.auto_clear)
          end
          fn()
          lg.pop()
        end
      end
      ent.resize = function(self)
        canvas = love.graphics.newCanvas(unpack(self.size))
        ent.drawable = canvas
      end
    end
  }
CanvasStack =
  Stack(
  function()
    return Canvas{draw = false}
  end
)

--IMAGE: image
System(
  All("Image"),
  {
    added = function(ent)
      ent.Image = Node{
        image = Cache.image(ent.Image)
      }
      ent.addChild(ent.Image)
    end
  }
)

--ANIMATION
System(
  All("Animation"),
  {
    
  }
)

--ENTITY: gravity, velocity
Component("Velocity", { x = 0, y = 0 })
System(
  All("Velocity", Not("hitbox")),
  {
    update = function(ent, dt)
      ent.Transform.x = ent.Transform.x + ent.Velocity.x * dt
      ent.Transform.y = ent.Transform.y + ent.Velocity.y * dt
    end
  }
)
Component("Gravity", { direction = Math.rad(90), amount = 0 })
System(
  All("Gravity", "Velocity"),
  {
    update = function(ent, dt)
      local gravx, gravy = Math.getXY(ent.Gravity.direction, ent.Gravity.amount)
      ent.Velocity.x = ent.Velocity.x + gravx
      ent.Velocity.y = ent.Velocity.y + gravy
    end
  }
)

--EFFECT
Effect = nil
do
  local love_replacements = {
    float = "number",
    int = "number",
    sampler2D = "Image",
    uniform = "extern",
    texture2D = "Texel",
    gl_FragColor = "pixel",
    gl_FragCoord = "screen_coords"
  }
  local helper_fns =
    [[
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 pixelcoord, float seed) {
  /* use the fragment position for a different seed per-pixel */
  return fract(sin(dot(pixelcoord + seed, scale)) * 43758.5453 + seed);
}
float mod(float a, float b) { return - (a / b) * b; }
float getX(float amt) { return amt / love_ScreenSize.x; }
float getY(float amt) { return amt / love_ScreenSize.y; }
float lerp(float a, float b, float t) { return a * (1.0 - t) + b * t; }
]]
  local library = {}
  local shaders = {} -- { 'eff1+eff2' = { shader: Love2dShader } }

  local tryEffect = function(name)
    assert(library[name], "Effect :'" .. name .. "' not found")
  end

  local _generateShader, generateShader

  generateShader = function(names, override)
    if type(names) ~= "table" then
      names = {names}
    end
    local ret_shaders = {}
    for _, name in ipairs(names) do
      ret_shaders[name] = _generateShader(name, override)
    end
    return ret_shaders
  end

  local shader_obj = {} -- { name : LoveShader }
  _generateShader = function(name, override)
    tryEffect(name)
    local info = library[name]
    local shader = shader_obj[name] or love.graphics.newShader(info.code)
    if override then
      shader = love.graphics.newShader(info.code)
    end
    shader_obj[name] = shader

    return {
      vars = copy(info.opt.vars),
      unused_vars = copy(info.opt.unused_vars),
      shader = shader,
      auto_vars = info.opt.auto_vars
    }
  end

  local updateShader = function(ent, names)
    if not Feature("effect") then
      return
    end
    ent.shader_info = generateShader(names)
    for _, name in ipairs(names) do
      if not ent.vars[name] then
        ent.vars[name] = {}
      end
      ent.auto_vars[name] = ent.shader_info[name].auto_vars
      table.update(ent.vars[name], ent.shader_info[name].vars)
    end
  end

  Effect =
    class {
    library = function()
      return library
    end,
    new = function(name, in_opt)
      local opt = {
        use_canvas = true,
        vars = {},
        unused_vars = {},
        integers = {},
        code = nil,
        effect = "",
        vertex = "",
        auto_vars = false
      }
      table.update(opt, in_opt)

      -- mandatory vars
      if not opt.vars["tex_size"] then
        opt.vars["tex_size"] = {Game.width, Game.height}
      end
      if not opt.vars["time"] then
        opt.vars["time"] = 0
      end

      -- create var string
      var_str = ""
      for key, val in pairs(opt.vars) do
        -- unused vars?
        if not string.contains(opt.code or (opt.effect .. " " .. opt.vertex), key) then
          opt.unused_vars[key] = true
        end
        -- get var type
        switch(
          type(val),
          {
            table = function()
              var_str = var_str .. "uniform vec" .. tostring(#val) .. " " .. key .. ";\n"
            end,
            number = function()
              if table.hasValue(opt.integers, key) then
                var_str = var_str .. "uniform int " .. key .. ";\n"
              else
                var_str = var_str .. "uniform float " .. key .. ";\n"
              end
            end,
            string = function()
              if val == "Image" then
                var_str = var_str .. "uniform Image " .. key .. ";\n"
              end
            end
          }
        )
      end

      local code = var_str .. "\n" .. helper_fns .. "\n"
      if opt.code then
        code = code .. opt.code
      else
        code =
          code ..
          [[

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position) {
  ]] ..
            (opt.position or "") ..
              [[
  return transform_projection * vertex_position;
}
#endif


#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
  vec4 pixel = Texel(texture, texture_coords);
  ]] ..
                (opt.effect or "") .. [[
  return pixel * color;
}
#endif
          ]]
      end

      for old, new in pairs(love_replacements) do
        code = code:replace(old, new, true)
      end

      library[name] = {
        opt = copy(opt),
        code = code
      }
    end,
    info = function(name)
      return library[name]
    end,
    init = function(self, ...)
      self.classname = "Blanke.Effect"
      self.names = {...}
      if type(self.names[1]) == "table" then
        self.names = self.names[1]
      end

      if Feature("effect") then
        self.used = true
        self.vars = {}
        self.disabled = {}
        self.auto_vars = {}
        self:updateShader(self.names)
      end
    end,
    __ = {},
    updateShader = function(self, names)
      if not Feature("effect") then
        return
      end
      self.shader_info = generateShader(names)
      for _, name in ipairs(names) do
        if not self.vars[name] then
          self.vars[name] = {}
        end
        self.auto_vars[name] = self.shader_info[name].auto_vars
        table.update(self.vars[name], self.shader_info[name].vars)
      end
    end,
    disable = function(self, ...)
      if not Feature("effect") then
        return
      end
      local disable_names = {...}
      for _, name in ipairs(disable_names) do
        self.disabled[name] = true
      end
      local new_names = {}
      self.used = false
      for _, name in ipairs(self.names) do
        tryEffect(name)
        if not self.disabled[name] then
          self.used = true
          table.insert(new_names, name)
        end
      end
      self:updateShader(new_names)
    end,
    enable = function(self, ...)
      if not Feature("effect") then
        return
      end
      local enable_names = {...}
      for _, name in ipairs(enable_names) do
        self.disabled[name] = false
      end
      local new_names = {}
      self.used = false
      for _, name in ipairs(self.names) do
        tryEffect(name)
        if not self.disabled[name] then
          self.used = true
          table.insert(new_names, name)
        end
      end
      self:updateShader(new_names)
    end,
    set = function(self, name, k, v)
      if not Feature("effect") then
        return
      end
      -- tryEffect(name)
      if not self.disabled[name] then
        if not self.vars[name] then
          self.vars[name] = {}
        end
        self.vars[name][k] = v
      end
    end,
    send = function(self, name, k, v)
      if not Feature("effect") then
        return
      end
      local info = self.shader_info[name]
      if not info.unused_vars[k] then
        tryEffect(name)
        if info.shader:hasUniform(k) then
          info.shader:send(k, v)
        end
      end
    end,
    update = function(self, dt)
      if not Feature("effect") then
        return
      end
      local vars

      for _, name in ipairs(self.names) do
        if not self.disabled[name] then
          vars = self.vars[name]
          vars.time = vars.time + dt
          vars.tex_size = {Game.width, Game.height}

          if self.auto_vars[name] then
            vars.inputSize = {Game.width, Game.height}
            vars.outputSize = {Game.width, Game.height}
            vars.textureSize = {Game.width, Game.height}
          end
          -- send all the vars
          for k, v in pairs(vars) do
            self:send(name, k, v)
          end

          if library[name] and library[name].opt.update then
            library[name].opt.update(self.vars[name])
          end
        end
      end
    end,
    active = 0,
    --@static
    isActive = function()
      return Effect.active > 0
    end,
    draw = function(self, fn)
      if not self.used or not Feature("effect") then
        fn()
        return
      end

      Effect.active = Effect.active + 1

      local last_shader = love.graphics.getShader()
      local last_blend = love.graphics.getBlendMode()

      local canv_internal, canv_final = CanvasStack:new(), CanvasStack:new()

      canv_internal.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}
      canv_final.value.auto_clear = {Draw.parseColor(Game.options.background_color, 0)}

      for i, name in ipairs(self.names) do
        if not self.disabled[name] then
          -- draw without shader first
          canv_internal.value:renderTo(
            function()
              love.graphics.setShader()
              if i == 1 then
                -- draw unshaded stuff (first run)
                fn()
              else
                -- draw previous shader results
                Render(canv_final.value, true)
              end
            end
          )

          -- draw to final canvas with shader
          canv_final.value:renderTo(
            function()
              love.graphics.setShader(self.shader_info[name].shader)
              Render(canv_internal.value, true)
            end
          )
        end
      end

      -- draw final resulting canvas
      Render(canv_final.value, true)

      love.graphics.setShader(last_shader)
      love.graphics.setBlendMode(last_blend)

      CanvasStack:release(canv_internal)
      CanvasStack:release(canv_final)

      Effect.active = Effect.active - 1
    end
  }
end

System(
  All("effect"),
  {
    added = function(ent)
      ent.effect = Effect(unpack(ent.effect))
    end,
    update = function(ent, dt)
      ent.effect:update(dt)
    end
  }
)

--SPRITEBATCH
SpriteBatch = nil
do 
  local default_quad = {0, 0, 1, 1}
  local default_tform = {0, 0}
  SpriteBatch = class {
    init = function(ent)
      ent.drawable = Cache.spritebatch(ent.file, ent.z)
    end,
    set = function(ent, ...)
      local use_quad = false
      local image = Cache.image(ent.file)
      local x, y, qx, qy, qw, qh, id = 0, 0, 0, 0, image:getWidth(), image:getHeight()
      local in_quad, in_tform, id = default_quad, default_tform
      local args = {...}

      local argslen = #args
      if argslen == 2 then 
        x, y = unpack(args)
      elseif argslen == 3 then 
        x, y, id = unpack(args)
      elseif argslen > 3 then 
        use_quad = true
        x, y, qx, qy, qw, qh, id = unpack(args)
      end

      -- get quad
      local quad = Cache.quad(ent.file, qx, qy, qw, qh)
      if id then
        ent.drawable:set(id, quad, x, y)
        return id
      else
        return ent.drawable:add(quad, x, y)
      end
    end,
    remove = function(ent, id)
      return ent.drawable:set(id, 0, 0, 0, 0, 0)
    end
  }
end

--MAP (TODO needs update after adding scene graph)
Map = nil
do
  local getObjInfo = function(uuid, is_name)
    if Game.config.scene and Game.config.scene.objects then
      if is_name then
        for uuid, info in pairs(Game.config.scene.objects) do
          if info.name == uuid then
            return info
          end
        end
      else
        return Game.config.scene.objects[uuid]
      end
    end
  end

  Map = class{
      init = function(ent)
        ent.batches = {} -- { layer: SpriteBatch }
        ent.hb_list = {}
        ent.entity_info = {} -- { obj_name: { info_list... } }
        ent.entities = {} -- { layer: { entities... } }
        ent.paths = {} -- { obj_name: { layer_name:{ Paths... } } }
        ent.layer_order = {}
      end,
      destroy = function(ent)
        for _, batches in pairs(self.batches) do 
          for _, batch in pairs(batches) do 
            Destroy(batch)
          end 
        end 
      end,
      addTile = function(self, file, x, y, tx, ty, tw, th, layer)
        local options = Map.config
        layer = layer or "_"
        local tile_info = {
          x = x,
          y = y,
          width = tw,
          height = th,
          tag = hb_name,
          quad = {tx, ty, tw, th},
          transform = {x, y}
        }

        -- add tile to spritebatch
        if not self.batches[layer] then
          self.batches[layer] = {}
        end
        local sb = self.batches[layer][file]
        if not sb then
          sb = SpriteBatch {file=file, z=self:getLayerZ(layer)}
        end
        self.batches[layer][file] = sb
        local id = sb:set(x,y,tx,ty,tw,th)
        tile_info.id = id

        -- hitbox
        local hb_name = nil
        if options.tile_hitbox then
          hb_name = options.tile_hitbox[FS.removeExt(FS.basename(file))]
        end
        local body = nil
        if hb_name then
          tile_info.tag = hb_name
          if options.use_physics then
            hb_key = hb_name .. "." .. tw .. "." .. th
            if not Physics.getBodyConfig(hb_key) then
              Physics.body(
                hb_key,
                {
                  shapes = {
                    {
                      type = "rect",
                      width = tw,
                      height = th,
                      offx = tw / 2,
                      offy = th / 2
                    }
                  }
                }
              )
            end
            local body = Physics.body(hb_key)
            body:setPosition(x, y)
            tile_info.body = body
          end
        end
        if not options.use_physics and tile_info.tag then
          table.insert(
            self.hb_list,
            World.add {
              classname = "Blanke.Map.Tile",
              pos = {tile_info.x, tile_info.y},
              size = {tw, th},
              hitbox = {
                tag = hb_name
              }
            }
          )
        end
      end,
      getLayerZ = function(self, l_name)
        for i, name in ipairs(self.layer_order) do
          if name == l_name then
            return i
          end
        end
        return 0
      end,
      addHitbox = function(self, tag, dims, color)
        local new_hb = {
          pos = {dims[1], dims[2]},
          size = {dims[3], dims[4]},
          hitbox = tag,
          debug_color = color
        }
        table.insert(self.hb_list, World.add(new_hb))
      end,
      getEntityInfo = function(self, name)
        return self.entity_info[name] or {}
      end,
      _spawnEntity = function(self, ent_name, opt)
        local ent = Entity.spawn(ent_name, opt)
        if ent then
          opt.layer = opt.layer or "_"
          return self:addEntity(ent, opt.layer)
        end
      end,
      spawnEntity = function(self, ent_name, x, y, layer)
        layer = layer or "_"
        obj_info = getObjInfo(ent_name, true)
        if obj_info then
          obj_info.pos = {x, y}
          obj_info.z = self:getLayerZ(layer)
          obj_info.layer = layer or "_"
          obj_info.debug_color = obj_info.color 
          obj_info.color = {1,1,1,1}
          return self:_spawnEntity(ent_name, obj_info)
        end
      end,
      addEntity = function(self, ent, layer_name)
        layer_name = layer_name or "_"
        if not self.entities[layer_name] then
          self.entities[layer_name] = {}
        end
        table.insert(self.entities[layer_name], ent)
        sort(self.entities[layer_name], "z", 0)
        return ent
      end,
      getPaths = function(self, obj_name, layer_name)
        local ret = {}
        if self.paths[obj_name] then
          if layer_name and self.paths[obj_name][layer_name] then
            return self.paths[obj_name][layer_name]
          else
            for layer_name, paths in pairs(self.paths[obj_name]) do
              for _, path in ipairs(paths) do
                table.insert(ret, path)
              end
            end
          end
        end
        return ret
      end
    }
  Map.config = {}
  Map.load = function(name, opt)
    local data = love.filesystem.read(Game.res("map", name))
    assert(data, "Error loading map '" .. name .. "'")
    local new_map = Map(opt)
    data = json.decode(data)
    new_map.data = data
    local layer_name = {}
    -- get layer names
    local store_layer_order = false

    if #new_map.layer_order == 0 then
      new_map.layer_order = {}
      store_layer_order = true
    end
    for i = #data.layers, 1, -1 do
      local info = data.layers[i]
      layer_name[info.uuid] = info.name
      if store_layer_order then
        table.insert(new_map.layer_order, info.name)
      end
    end
    -- place tiles
    for _, img_info in ipairs(data.images) do
      for l_uuid, coord_list in pairs(img_info.coords) do
        l_name = layer_name[l_uuid]
        for _, c in ipairs(coord_list) do
          new_map:addTile(img_info.path, c[1], c[2], c[3], c[4], c[5], c[6], l_name)
        end
      end
    end
    -- make paths
    for obj_uuid, info in pairs(data.paths) do
      local obj_info = getObjInfo(obj_uuid)
      local obj_name = obj_info.name
      for layer_uuid, info in pairs(info) do
        local layer_name = layer_name[layer_uuid]
        local new_path = Path()
        -- add nodes
        local tag
        for node_key, info in pairs(info.node) do
          if type(info[3]) == "string" then
            tag = info[3]
          else
            tag = nil
          end
          new_path:addNode {x = info[1], y = info[2], tag = tag}
        end
        -- add edges
        for node1, edge_info in pairs(info.graph) do
          for node2, tag in pairs(edge_info) do
            local _, node1_hash =
              new_path:getNode {
              x = info.node[node1][1],
              y = info.node[node1][2],
              tag = info.node[node1][3]
            }
            local _, node2_hash =
              new_path:getNode {
              x = info.node[node2][1],
              y = info.node[node2][2],
              tag = info.node[node2][3]
            }
            if type(tag) ~= "string" then
              tag = nil
            end
            new_path:addEdge {a = node1_hash, b = node2_hash, tag = tag}
          end
        end

        if not new_map.paths[obj_name] then
          new_map.paths[obj_name] = {}
        end
        if not new_map.paths[obj_name][layer_name] then
          new_map.paths[obj_name][layer_name] = {}
        end
        -- get color
        if obj_info then
          new_path.color = {Draw.parseColor(obj_info.color)}
        end
        table.insert(new_map.paths[obj_name][layer_name], new_path)
      end
    end

    -- spawn entities/hitboxes
    for obj_uuid, info in pairs(data.objects) do
      local obj_info = getObjInfo(obj_uuid)
      if obj_info then
        for l_uuid, coord_list in pairs(info) do
          for _, c in ipairs(coord_list) do
            local hb_color = {Draw.parseColor(obj_info.color)}
            hb_color[4] = 0.8
            -- spawn entity
            if Entity.exists(obj_info.name) then
              -- spawn hitbox
              local new_entity =
                new_map:_spawnEntity(
                obj_info.name,
                {
                  map_tag = c[1],
                  pos = {c[2], c[3]},
                  z = new_map:getLayerZ(layer_name[l_uuid]),
                  layer = layer_name[l_uuid],
                  points = copy(c),
                  size = {obj_info.size[1], obj_info.size[2]},
                  align = 'center',
                  debug_color = hb_color
                }
              )
            else
              new_map:addHitbox(table.join({obj_info.name, c[1]}, "."), table.slice(c, 2), hb_color)
            end
            -- add info to entity_info table
            if not new_map.entity_info[obj_info.name] then
              new_map.entity_info[obj_info.name] = {}
            end
            table.insert(
              new_map.entity_info[obj_info.name],
              {
                map_tag = c[1],
                pos = { c[2], c[3] },
                z = new_map:getLayerZ(layer_name[l_uuid]),
                layer = layer_name[l_uuid],
                points = copy(c),
                size = { unpack(obj_info.size) },
                debug_color = hb_color
              }
            )
          end
        end
      end
    end

    return new_map
  end
end

--PHYSICS: (entity?)
Physics = nil
do
  local world_config = {}
  local body_config = {}
  local joint_config = {}
  local worlds = {}

  local setProps = function(obj, src, props)
    for _, p in ipairs(props) do
      if src[p] ~= nil then
        obj["set" .. string.capitalize(p)](obj, src[p])
      end
    end
  end

  --PHYSICS.BODYHELPER
  local BodyHelper =
    class {
    init = function(self, body)
      self.body = body
      self.body:setUserData(helper)
      self.gravx, self.gravy = 0, 0
      self.grav_added = false
    end,
    update = function(self, dt)
      if self.grav_added then
        self.body:applyForce(self.gravx, self.gravy)
      end
    end,
    setGravity = function(self, angle, dist)
      if dist > 0 then
        self.gravx, self.gravy = Math.getXY(angle, dist)
        self.body:setGravityScale(0)
        if not self.grav_added then
          table.insert(Physics.custom_grav_helpers, self)
          self.grav_added = true
        end
      end
    end,
    setPosition = function(self, x, y)
      self.body:setPosition(x, y)
    end
  }

  Physics = {
    custom_grav_helpers = {},
    debug = false,
    init = function(self)
      self.is_physics = true
    end,
    update = function(dt)
      for name, world in pairs(worlds) do
        local config = world_config[name]
        world:update(dt, 8 * config.step_rate, 3 * config.step_rate)
      end
      for _, helper in ipairs(Physics.custom_grav_helpers) do
        helper:update(dt)
      end
    end,
    getWorldConfig = function(name)
      return world_config[name]
    end,
    world = function(name, opt)
      if type(name) == "table" then
        opt = name
        name = "_default"
      end
      name = name or "_default"
      if opt or not world_config[name] then
        world_config[name] = opt or {}
        table.defaults(
          world_config[name],
          {
            gravity = 0,
            gravity_direction = 90,
            sleep = true,
            step_rate = 1
          }
        )
      end
      if not worlds[name] then
        worlds[name] = love.physics.newWorld()
      end
      local w = worlds[name]
      local c = world_config[name]
      -- set properties
      w:setGravity(Math.getXY(c.gravity_direction, c.gravity))
      w:setSleepingAllowed(c.sleep)
      return worlds[name]
    end,
    getJointConfig = function(name)
      return joint_config[name]
    end,
    joint = function(name, opt) -- TODO: finish joints
      if not worlds["_default"] then
        Physics.world("_default", {})
      end
      if opt then
        joint_config[name] = opt
      end
    end,
    getBodyConfig = function(name)
      return body_config[name]
    end,
    body = function(name, opt)
      if not worlds["_default"] then
        Physics.world("_default", {})
      end
      if opt then
        body_config[name] = opt
        table.defaults(
          body_config[name],
          {
            x = 0,
            y = 0,
            angularDamping = 0,
            gravity = 0,
            gravity_direction = 0,
            type = "static",
            fixedRotation = false,
            bullet = false,
            inertia = 0,
            linearDamping = 0,
            shapes = {}
          }
        )
        return
      end
      assert(body_config[name], "Physics config missing for '#{name}'")
      local c = body_config[name]
      if not c.world then
        c.world = "_default"
      end
      assert(worlds[c.world], "Physics world '#{c.world}' config missing (for body '#{name}')")
      -- create the body
      local body = love.physics.newBody(worlds[c.world], c.x, c.y, c.type)
      local helper = BodyHelper(body)
      -- set props
      setProps(body, c, {"angularDamping", "fixedRotation", "bullet", "inertia", "linearDamping", "mass"})
      helper:setGravity(c.gravity, c.gravity_direction)
      local shapes = {}
      for _, s in ipairs(c.shapes) do
        local shape = nil
        table.defaults(
          s,
          {
            density = 0
          }
        )
        switch(
          s.type,
          {
            rect = function()
              table.defaults(
                s,
                {
                  width = 1,
                  height = 1,
                  offx = 0,
                  offy = 0,
                  angle = 0
                }
              )
              shape =
                love.physics.newRectangleShape(c.x + s.offx, c.y + s.offy, s.width, s.height, s.angle)
            end,
            circle = function()
              table.defaults(
                s,
                {
                  offx = 0,
                  offy = 0,
                  radius = 1
                }
              )
              shape = love.physics.newCircleShape(c.x + s.offx, c.y + s.offy, s.radius)
            end,
            polygon = function()
              table.defaults(
                s,
                {
                  points = {}
                }
              )
              assert(
                #s.points >= 6,
                "Physics polygon must have 3 or more vertices (for body '" .. name .. "')"
              )
              shape = love.physics.newPolygonShape(s.points)
            end,
            chain = function()
              table.defaults(
                s,
                {
                  loop = false,
                  points = {}
                }
              )
              assert(
                #s.points >= 4,
                "Physics polygon must have 2 or more vertices (for body '" .. name .. "')"
              )
              shape = love.physics.newChainShape(s.loop, s.points)
            end,
            edge = function()
              table.defaults(
                s,
                {
                  points = {}
                }
              )
              assert(
                #s.points >= 4,
                "Physics polygon must have 2 or more vertices (for body '" .. name .. "')"
              )
              shape = love.physics.newEdgeShape(unpack(s.points))
            end
          }
        )
        if shape then
          fix = love.physics.newFixture(body, shape, s.density)
          setProps(fix, s, {"friction", "restitution", "sensor", "groupIndex"})
          table.insert(shapes, shape)
        end
      end
      return body, shapes
    end,
    setGravity = function(body, angle, dist)
      local helper = body:getUserData()
      helper:setGravity(angle, dist)
    end,
    draw = function(body, _type)
      for _, fixture in pairs(body:getFixtures()) do
        shape = fixture:getShape()
        if shape:typeOf("CircleShape") then
          local x, y = body:getWorldPoints(shape:getPoint())
          Draw.circle(_type or "fill", floor(x), floor(y), shape:getRadius())
        elseif shape:typeOf("PolygonShape") then
          local points = {body:getWorldPoints(shape:getPoints())}
          for i, p in ipairs(points) do
            points[i] = floor(p)
          end
          Draw.poly(_type or "fill", points)
        else
          local points = {body:getWorldPoints(shape:getPoints())}
          for i, p in ipairs(points) do
            points[i] = floor(p)
          end
          Draw.line(body:getWorldPoints(shape:getPoints()))
        end
      end
    end,
    drawDebug = function(world_name)
      world_name = world_name or "_default"
      if Physics.debug then
        world = worlds[world_name]
        for _, body in pairs(world:getBodies()) do
          Draw.color(1, 0, 0, .8)
          Physics.draw(body, "line")
          Draw.color(1, 0, 0, .5)
          Physics.draw(body)
        end
        Draw.color()
      end
    end
  }

  System(
    One("body", "fixture"),
    {
      added = function(ent)
        ent.physics = Physics.body(ent.physics)
      end,
      removed = function(ent)
        ent.physics:destroy()
      end
    }
  )
end

--HITBOX: pos, vel, size, hitbox
Hitbox = nil
do
  local bump = blanke_require("bump")
  local world = bump.newWorld(40)
  local new_boxes = true
  local hb_items = {}

  Hitbox = {
    debug = false,
    default_reaction = 'cross',
    config = { reaction={}, reactions={} },
    at = function(ent, x, y, tag)
      local l, t, _, _, w, h = unpack(ent.rect)
      l = l + x
      t = t + y
      
      local items, len = world:queryRect(l, t, w, h, function(item)
        if tag then 
          return item.hitbox.tag == tag 
        end 
        return true 
      end)
      if len > 0 then 
        return items, len 
      end
    end,
    point = function(x, y, queryFilter)
      return world:queryPoint(x, y, queryFilter)
    end;
    within = function(x, y, w, h, queryFilter)
      return world:queryRect(x, y, queryFilter)
    end;
    sight = function(x1, y1, x2, y2, queryFilter)
      return world:querySegment(x1, y1, x2, y2, queryFilter)
    end;
    draw = function()
      if Hitbox.debug then
        local lg = love.graphics
        local x, y, w, h
        if new_boxes then
          new_boxes = false
          hb_items, hb_len = world:getItems()
        end
        for _, i in ipairs(hb_items) do
          x, y, w, h = world:getRect(i)
          if i.hitbox and not i.destroyed then
            Draw.color(i.debug_color or {1, 0, 0, 0.9})
            lg.rectangle("line", x, y, w, h)
            Draw.color(i.debug_color or {1, 0, 0, 0.25})
            lg.rectangle("fill", x, y, w, h)
          end
        end
        Draw.color()
      end
    end
  }

  local get_dims = function(ent)
    local x, y, w, h
    if ent.hitbox.rect and #ent.hitbox.rect == 4 then
      x, y, w, h = unpack(ent.hitbox.rect)
    else
      x = 0
      y = 0
      _, _, w, h = getAlign(ent)
    end
    if w <= 0 then
      w = w % ent.scaled_size[1]
    end
    if h <= 0 then
      h = h % ent.scaled_size[2]
    end
    return ent.pos[1] + x, ent.pos[2] + y, w, h
  end

  System(
    All("hitbox", "pos", "size"),
    {
      order = "post",
      added = function(ent)
        local type_hbox = type(ent.hitbox)
        if type_hbox ~= "table" then
          if type_hbox == "string" then
            ent.hitbox = {tag = ent.hitbox}
          else
            ent.hitbox = {}
          end
        end
        if not ent.hitbox.tag then ent.hitbox.tag = ent.classname end 
        if not ent.vel then ent.vel = {0,0} end 
        local _, _, w, h = get_dims(ent)
        world:add(ent, ent.pos[1], ent.pos[2], w, h)
        new_boxes = true
      end,
      update = function(ent, dt)
        local filter_result
        local reactions

        local filter = function(obj_ent, other_ent)
          local _obj = obj_ent.hitbox
          local other = other_ent.hitbox

          local ret = Hitbox.config.reaction and Hitbox.config.reaction[obj_ent.tag] or Hitbox.default_reaction
          
          reactions = Hitbox.config.reactions and Hitbox.config.reactions[_obj.tag]
          if reactions and reactions[other.tag] then
            ret = reactions[other.tag]
          end

          reactions = Hitbox.config.reactions and Hitbox.config.reactions[other.tag]
          if reactions and reactions[_obj.tag] then
            ret = reactions[_obj.tag]
          end

          if _obj.filter then
            ret = _obj:filter(other_ent)
          end
          
          filter_result = ret

          return ret
        end

        local ax, ay = getAlign(ent)
        if ent.hitbox.rect then 
          ax, ay = ent.hitbox.rect[1] or 0, ent.hitbox.rect[2] or 0
        end

        local next_x = (ent.pos[1] - ax) + ent.vel[1] * dt
        local next_y = (ent.pos[2] - ay) + ent.vel[2] * dt
        local new_x, new_y, cols, len = world:move(ent, next_x, next_y, filter)

        if ent.destroyed then
          return
        end
        --if filter_result ~= 'static' then
        ent.pos[1] = new_x + ax
        ent.pos[2] = new_y + ay
        --end

        local swap = function(t, key1, key2)
          local temp = t[key1]
          t[key1] = t[key2]
          t[key2] = temp
        end
        if len > 0 then
          local hspeed, vspeed, bounciness, nx, ny
          for i = 1, len do
            hspeed, vspeed, bounciness = ent.vel[1], ent.vel[2], ent.bounciness or 1
            nx, ny = cols[i].normal.x, cols[i].normal.y
            -- change velocity by collision normal
            if cols[i].bounce then
              if hspeed and ((nx < 0 and hspeed > 0) or (nx > 0 and hspeed < 0)) then
                ent.vel[1] = -ent.vel[1] * bounciness
              end
              if vspeed and ((ny < 0 and vspeed > 0) or (ny > 0 and vspeed < 0)) then
                ent.vel[2] = -ent.vel[2] * bounciness
              end
            end

            if not ent or ent.destroyed then
              return
            end
            if ent.collision then
              ent:collision(cols[i], cols[i].other.hitbox.tag, cols[i].other.classname)
            end

            local info = cols[i]
            local other = info.other
            swap(info, "item", "other")
            swap(info, "itemRect", "otherRect")
            if other and not other.destroyed and other.collision then
              other:collision(info, info.other.hitbox.tag)
            end
          end
        end
        -- entity size changed, update in world
        if ent.hitbox.rect and (changed(ent.hitbox.rect, 1) or changed(ent.hitbox.rect, 2)  or changed(ent.hitbox.rect, 3) or changed(ent.hitbox.rect, 4)) then
          --world:update(ent, get_dims(ent))
        end
      end,
      removed = function(ent)
        if world:hasItem(ent) then 
          world:remove(ent)
          new_boxes = true
        end
      end
    }
  )
end

--BACKGROUND
Background = nil
BFGround = nil
do
  local bg_list = {}
  local fg_list = {}

  local quad
  local add = function(opt)
    opt = opt or {}
    if opt.file then
      opt.image =
        Cache.get(
        "Image",
        Game.res("image", opt.file),
        function(key)
          return love.graphics.newImage(key)
        end
      )
      opt.x = 0
      opt.y = 0
      opt.scale = 1
      opt.width = opt.image:getWidth()
      opt.height = opt.image:getHeight()
      if not quad then
        quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)
      end
    end
    return opt
  end

  local update = function(list, dt)
    iterate(
      list,
      function(t)
        if t.remove == true then
          return true
        end

        if t.size == "cover" then
          if t.width < t.height then
            t.scale = Game.width / t.width
          else
            t.scale = Game.height / t.height
          end
          t.image:setWrap("clamp", "clamp")
          t.x = (Game.width - (t.width * t.scale)) / 2
          t.y = (Game.height - (t.height * t.scale)) / 2
        else
          t.image:setWrap("repeat", "repeat")
        end
      end
    )
  end

  local draw = function(list)
    local lg_draw = love.graphics.draw
    for _, t in ipairs(list) do
      if t.image then
        if t.size == "cover" then
          lg_draw(t.image, 0, 0, 0, t.scale, t.scale)
        else
          quad:setViewport(-t.x, -t.y, Game.width, Game.height, t.width, t.height)
          lg_draw(t.image, quad, 0, 0, 0, t.scale, t.scale)
        end
      end
    end
  end

  BFGround = {
    update = function(dt)
      update(bg_list, dt)
      update(fg_list, dt)
    end
  }

  Background =
    callable {
    __call = function(self, opt)
      local t = add(opt)
      table.insert(bg_list, opt)
      return t
    end,
    draw = function()
      draw(bg_list)
    end
  }
  Foreground =
    callable {
    __call = function(self, opt)
      local t = add(opt)
      table.insert(fg_list, opt)
      return t
    end,
    draw = function()
      draw(fg_list)
    end
  }
end

--PARTICLES (TODO needs update after adding scene graph)
Particles = nil
do
  local methods = {
    offset = "Offset",
    rate = "EmissionRate",
    area = "EmissionArea",
    colors = "Colors",
    max = "BufferSize",
    lifetime = "ParticleLifetime",
    linear_accel = "LinearAcceleration",
    linear_damp = "LinearDamping",
    rad_accel = "RadialAcceleration",
    relative = "RelativeRotation",
    direction = "Direction",
    rotation = "Rotation",
    size_vary = "SizeVariation",
    sizes = "Sizes",
    speed = "Speed",
    spin = "Spin",
    spin_vary = "SpinVariation",
    spread = "Spread",
    tan_accel = "TangentialAcceleration",
    position = "Position",
    insert = "InsertMode"
  }

  local update_source = function(ent)
    local source = ent.source
    local type_src = type(source)

    -- get texture and quad from image
    if type_src == "string" then
      ent.source = Image.get {parent = ent, name = source}
      --ent.size = ent.source.size
      source = ent.source
    end

    if not source.drawable then
      return
    end

    -- create/edit the particle system
    if not ent.psystem then
      ent.psystem = love.graphics.newParticleSystem(source.drawable)
    else
      ent.psystem:setTexture(source.drawable)
    end
  end

  Particles = class{
      frame = 0,
      init = function(ent, args)
        if args and #args > 0 then
          if type(args[1]) == "table" then
            ent.source = args[1].source
          else
            ent.source = args[1]
          end
        end
        assert(ent.source, "Particles instance needs source")

        update_source(ent)
        reset(ent, "source")

        -- initial psystem settings
        if ent.psystem then
          for k, v in pairs(ent) do
            if methods[k] then
              if type(v) == "table" then
                ent.psystem["set" .. methods[k]](ent.psystem, unpack(v))
              else
                ent.psystem["set" .. methods[k]](ent.psystem, v)
              end
            end
            args[k] = nil
          end
        end

        -- getters/setters
        for k, v in pairs(methods) do
          ent[k] = function(ent, ...)
            if ent.psystem then
              ent.psystem["set" .. v](ent.psystem, ...)
              return ent.psystem["get" .. v](ent.psystem)
            end
          end
        end

        ent.drawable = ent.psystem
      end,
      stop = function(self)
        self:rate(0)
      end,
      emit = function(self, n)
        self.psystem:emit(n)
      end,
      update = function(ent, dt)
        if changed(ent, "source") then
          update_source(ent)
        end
        if changed(ent, "frame") and ent.source.quads then
          local f, quads = ent.frame, ent.source.quads
          if f > 0 and f < #quads + 1 then
            ent.psystem:setQuads(quads[f])
          else
            ent.psystem:setQuads(quads)
          end
        end

        if ent.psystem then
          local follow = ent.follow
          if follow then
            local ax, ay = getAlign(follow)
            ent.scale = follow.scale
            ent.scalex = follow.scalex
            ent.scaley = follow.scaley
            ent.align = {ax, ay}
            ent.psystem:setPosition(
              (follow.pos[1] + ax) / follow.scale / follow.scalex,
              (follow.pos[2] + ay) / follow.scale / follow.scaley
            )
          end
          ent.psystem:update(dt)
        end
      end
    }
end

--TIMELINE (TODO needs update after adding scene graph)
Timeline = class{
    init = function(ent, args)
      if #args > 0 then
        ent.events = args[1]
      end
      ent.t = 0
      ent.index = 0
      ent.running = false
    end,
    pause = function(self)
      self.running = false
    end,
    resume = function(self)
      self.running = true
    end,
    play = function(self, name)
      self:step(name or 1)
      self.running = true
    end,
    step = function(self, name)
      self.t = 0
      self.waiting = false
      if type(name) == "string" then
        for i, ev in ipairs(self.events) do
          if ev.name == name then
            self.index = i
          end
        end
      elseif type(name) == "number" then
        while name < 0 do
          name = #self.events - name
        end
        self.index = name
      else
        self.index = self.index + 1
        -- stop the timeline and destroy it??
        if self.index > #self.events then
          self.running = false
          Destroy(self)
        end
      end
      self:call()
    end,
    call = function(self, name, ...)
      local ev = self.events[self.index]
      if not ev then
        return
      end

      if not name then
        name = "fn"
      end

      if name and ev[name] then
        -- call named fn
        ev[name](self, ...)
      end
    end,
    reset = function(self)
      self:step(1)
    end,
    update = function(ent, dt)
      if not ent.running then
        return
      end
      ent:call("update", dt)

      local ev = ent.events[ent.index]
      -- move onto next step?
      if not ev or #ev == 0 or (type(ev[1]) == "number" and ent.t > ev[1]) then
        ent:step()
      elseif ev and ev[1] == "wait" and not ent.waiting then
        ent.waiting = true
      end

      ent.t = ent.t + dt * 1000
    end,
    draw = function(ent)
      ent:call("draw")
    end
  }

--PATH (TODO needs update after adding scene graph)
Path = nil 
do
  local lerp, distance, sign = Math.lerp, Math.distance, Math.sign
  local hash_node = function(x, y, tag)
    local parts = {}
    if tag then
      parts = {tag}
    end
    if not tag then
      parts = {x, y}
    end
    return table.join(parts, ",")
  end

  local hash_edge = function(node1, node2)
    return table.join({node1, node2}, ":"), table.join({node2, node1}, ":")
  end

  Path = class{
      debug = false,
      -- TODO: Disjkstra cache (clear when node/edge changes)
      added = function(ent)
        ent.color = "blue"
        ent.node = {} -- { hash:{x,y,tag} }
        ent.edge = {} -- { hash:{node1:hash, node2:hash, direction:-1,0,1, tag} }
        ent.matrix = {} -- adjacency matrix containg node/edge info

        ent.pathing_objs = {} -- { obj... }
      end,
      addNode = function(self, opt)
        if not opt then
          return
        end
        local hash = hash_node(opt.x, opt.y, opt.tag)

        self.node[hash] = copy(opt)
        -- setup edges in matrix
        self.matrix[hash] = {}
        for xnode, edges in pairs(self.matrix) do
          if xnode ~= hash and not edges[hash] then
            edges[hash] = nil
          end
        end

        return hash
      end,
      getNode = function(self, opt)
        opt = opt or {}
        local hash = hash_node(opt.x, opt.y, opt.tag)
        assert(self.node[hash], "Node '" .. hash .. "' not in path")
        return self.node[hash], hash
      end,
      addEdge = function(self, opt)
        opt = opt or {}
        local hash = hash_edge(opt.a, opt.b)

        assert(self.node[opt.a], "Node '" .. (opt.a or "nil") .. "' not in path")
        assert(self.node[opt.b], "Node '" .. (opt.b or "nil") .. "' not in path")

        local node1, node2 = self.node[opt.a], self.node[opt.b]
        opt.length = floor(Math.distance(node1.x, node1.y, node2.x, node2.y))

        self.edge[hash] = copy(opt)
        -- add edge to matrix
        for xnode, edges in pairs(self.matrix) do
          if not edges[hash] then
            edges[hash] = nil
          end
        end
        self.matrix[opt.a][opt.b] = hash

        return hash
      end,
      getEdge = function(self, opt)
        opt = opt or {}
        local hash1, hash2 = hash_edge(opt.a, opt.b)
        assert(self.edge[hash1] or self.edge[hash2], "Edge '" .. hash1 .. "'/'" .. hash2 .. "' not in path")
        return self.edge[hash1] or self.edge[hash2], hash
      end,
      go = function(self, obj, opt)
        opt = opt or {}
        local speed = opt.speed or 1
        local target = opt.target
        local start = opt.start

        assert(target, "Path:go() requires target node")

        if obj.is_pathing and opt.force then
          self:stop(obj)
        end

        if not obj.is_pathing then
          local extra_dist = 0
          obj.is_pathing = {
            uuid = uuid(),
            direction = {x = 1, y = 1},
            speed = speed,
            index = 1,
            path = {},
            t = 0,
            prev_pos = {unpack(obj.pos)},
            onFinish = opt.onFinish
          }
          table.insert(self.pathing_objs, obj)

          if not start then
            -- find nearest node
            local closest_node
            local d = -1
            local new_d
            for hash, info in pairs(self.node) do
              new_d = Math.distance(info.x, info.y, obj.pos[1], obj.pos[2])
              if new_d < d or d < 0 then
                d = new_d
                closest_node = info
              end
            end
            if closest_node then
              extra_dist = new_d
              start = closest_node
            end
          end

          -- perform Dijskstra to find shortest path
          local INF = math.huge
          local dist = {}
          local previous = {}
          local Q = {}
          local checked = {}
          local start_hash = hash_node(start.x, start.y, start.tag)
          local target_hash = hash_node(target.x, target.y, target.tag)

          for v, info in pairs(self.node) do
            if v ~= target_hash then
              dist[v] = INF
            end
            table.insert(Q, v)
          end
          dist[target_hash] = 0
          while #Q > 0 do
            -- iterate backwards to avoid using the slow table.remove(Q, 1)
            table.sort(
              Q,
              function(a, b)
                return dist[a] > dist[b]
              end
            )
            -- lowest distance
            local u = Q[#Q]
            table.remove(Q)

            if dist[u] == INF then
              break
            end

            -- iterate neighbors
            for v, edge_hash in pairs(self.matrix[u]) do
              if not checked[u] then
                local alt = dist[u] + self.edge[edge_hash].length

                if alt < dist[v] then
                  dist[v] = alt
                  previous[v] = u
                end
              end
            end
            checked[u] = true
          end

          local next_node = start_hash
          obj.is_pathing.total_distance = dist[start_hash] + extra_dist

          repeat
            table.insert(obj.is_pathing.path, next_node)
            next_node = previous[next_node]
          until not next_node

          table.insert(self.pathing_objs, obj)
        end
      end,
      -- static
      stop = function(self, obj)
        if obj.is_pathing then
          local next_node = self.node[obj.is_pathing.path[obj.is_pathing.index]]
          local onFinish = obj.is_pathing.onFinish
          table.filter(
            self.pathing_objs,
            function(_obj)
              return obj.is_pathing.uuid ~= _obj.is_pathing.uuid
            end
          )
          obj.is_pathing = nil
          return next_node, onFinish
        end
      end,
      -- static
      pause = function(obj)
        if obj.is_pathing then
          obj.is_pathing.paused = true
        end
      end,
      -- static
      resume = function(obj)
        if obj.is_pathing then
          obj.is_pathing.paused = false
        end
      end,
      update = function(ent, dt)
        for _, obj in ipairs(ent.pathing_objs) do
          local info = obj.is_pathing
          if info and not info.paused then
            local next_node = ent.node[info.path[info.index]]
            local total_dist = info.total_distance
            if not info.next_dist then
              info.next_dist = distance(info.prev_pos[1], info.prev_pos[2], next_node.x, next_node.y)
            end
            info.t = info.t + (info.speed / (info.next_dist / total_dist)) * dt

            if info.t >= 100 then
              info.index = info.index + 1
              info.t = 0
              info.prev_pos = {unpack(obj.pos)}
              info.next_dist = nil
            else
              obj.pos[1] = lerp(info.prev_pos[1], next_node.x, info.t / 100)
              obj.pos[2] = lerp(info.prev_pos[2], next_node.y, info.t / 100)

              -- store direction object is moving
              local xdiff = floor(next_node.x - info.prev_pos[1])
              local xsign = sign(xdiff)
              if xdiff ~= 0 then
                info.direction.x = xsign
              end

              local ydiff = floor(next_node.y - info.prev_pos[2])
              local ysign = sign(ydiff)
              if ydiff ~= 0 then
                info.direction.y = ysign
              end
            end
            if info.index > #info.path then
              local _, onFinish = ent:stop(obj)
              if onFinish then
                onFinish(obj)
              end
            end
          end
        end
      end,
      draw = function(ent)
        if not (Path.debug or ent.debug) then
          return
        end
        -- draw nodes
        for hash, node in pairs(ent.node) do
          Draw {
            {"color", ent.color},
            {"circle", "fill", node.x, node.y, 4},
            {"color"}
          }
          local tag = node.tag or (node.x .. "," .. node.y)
          if tag then
            local tag_w = Draw.textWidth(tag)
            local tag_h = Draw.textHeight(tag)
            Draw {
              {"color", "black", 0.8},
              {"rect", "fill", node.x, node.y, tag_w + 2, tag_h + 2, 2},
              {"color", "white"},
              {"print", tag, node.x + 1, node.y + 1},
              {"color"}
            }
          end
        end
        -- draw edges
        local node1, node2
        for hash, edge in pairs(ent.edge) do
          node1 = ent.node[edge.a]
          node2 = ent.node[edge.b]
          Draw {
            {"color", ent.color},
            {"line", node1.x, node1.y, node2.x, node2.y},
            {"color"}
          }
          local tag = edge.tag
          if tag then
            local tag_w = Draw.textWidth(tag)
            local tag_h = Draw.textHeight(tag)
            Draw {
              {"color", "gray", 0.9},
              {"rect", "fill", (node1.x + node2.x) / 2, (node1.y + node2.y) / 2, tag_w + 2, tag_h + 2, 2},
              {"color", "white"},
              {"print", tag, (node1.x + node2.x) / 2 + 1, (node1.y + node2.y) / 2 + 1},
              {"color"}
            }
          end
        end
      end
    }
end

--NET
Net = nil
do
  blanke_require("noobhub")
  local client
  local leader = false
  local net_objects = {} -- { clientid: { objid: obj } }

  local triggerSyncFn = function(obj, data, force)
    local len, sync_data = 0, {}
    if not obj.net then
      return
    end
    if obj.net.sync then
      for _, prop in ipairs(obj.net.sync) do
        if force or type(obj) == "table" or changed(obj, prop) then
          len = len + 1
          sync_data[prop] = obj[prop]
        end
      end
    end
    return len, sync_data
  end

  local destroyObj = function(clientid, objid)
    local obj = net_objects[clientid][objid]
    if obj and obj.net then
      if not obj.net.persistent then
        Destroy(obj)
        net_objects[clientid][objid] = nil
      end
    end
  end

  local destroyNetObjects = function(clientid, _objid)
    if net_objects[clientid] then
      if _objid then
        destroyObj(clientid, _objid)
      else
        for objid, obj in pairs(net_objects[clientid]) do
          destroyObj(clientid, objid)
        end
      end
      net_objects[clientid] = nil
    end
  end

  local sendData = function(data)
    if client then
      client:publish(
        {
          message = {
            type = "data",
            timestamp = love.timer.getTime(),
            clientid = Net.id,
            data = data,
            room = Net.room
          }
        }
      )
    end
  end

  local sendNetEvent = function(event, data)
    if client then
      client:publish(
        {
          message = {
            type = "netevent",
            timestamp = love.timer.getTime(),
            event = event,
            data = data,
            room = Net.room
          }
        }
      )
    end
  end

  local storeNetObject = function(clientid, obj, objid)
    objid = objid or obj.net.id or uuid()
    if not net_objects[clientid] then
      net_objects[clientid] = {}
    end
    net_objects[clientid][objid] = obj
  end

  local onReceive = function(data)
    local netdata = data.data
    if data.type == "netevent" then
      if data.event == "getID" then
        if Net.id then
          net_objects[Net.id] = nil
        end
        Net.id = data.info.id
        leader = data.info.is_leader
        net_objects[Net.id] = {}
        Signal.emit("net.ready", data.info)
      end
      if data.event == "set.leader" and data.info == Net.id then
        leader = true
      end
      if data.event == "client.connect" and data.clientid ~= Net.id then
        Signal.emit("net.connect", data.clientid)
        -- get new client up to speed with net objects
        Net.syncAll(data.clientid)
      end
      if data.event == "client.disconnect" then
        Signal.emit("net.disconnect", data.clientid)
        destroyNetObjects(data.clientid)
      end
      if data.event == "obj.sync" and netdata.clientid ~= Net.id then
        local obj = (net_objects[netdata.clientid] or {})[netdata.id]
        if obj then
          -- update existing entity
          for prop, val in pairs(netdata.props) do
            obj[prop] = val
          end
        else
          -- spawn new entity
          if not netdata.props.net then
            netdata.props.net = {}
          end
          netdata.props.net.external = true
          netdata.props.net.persistent = netdata.persistent
          obj = Entity.spawn(netdata.classname, netdata.props)
          storeNetObject(netdata.clientid, obj, netdata.id)
        end
      end
      if data.event == "obj.syncAll" and netdata.targetid == Net.id then
        for clientid, objs in pairs(netdata.sync_objs) do
          for objid, props in pairs(objs) do
            if not net_objects[clientid][objid] then
              local obj = Entity.spawn(props.classname, props)
              storeNetObject(clientid, obj, objid)
            end
          end
        end
      end
      if data.event == "obj.destroy" and netdata.clientid ~= Net.id then
        destroyObj(netdata.clientid, netdata.id)
      end
    elseif data.type == "data" and netdata.clientid ~= Net.id then
      Signal.emit("net.data", netdata, data)
    end
  end

  local onFail = function()
    Signal.emit("net.fail")
  end

  local prepNetObject = function(obj)
    if not obj.net then
      obj.net = {}
    end
    -- setup object for net syncing
    if not net_objects[Net.id] then
      net_objects[Net.id] = {}
    end
    if not obj.net.id then
      obj.net.id = uuid()
    end
    net_objects[Net.id][obj.net.id] = obj
  end

  Signal.on(
    "update",
    function(dt)
      if client then
        client:enterFrame()
      end
    end
  )

  Net = {
    address = "localhost",
    port = 8080,
    room = 1,
    id = "0",
    connect = function(address, port)
      Net.address = address or Net.address
      Net.port = port or Net.port
      client = noobhub.new({server = Net.address, port = Net.port})
      if client then
        client:subscribe(
          {
            channel = "room" .. tostring(Net.room),
            callback = onReceive,
            cb_reconnect = onFail
          }
        )
      else
        print("failed connecting to " .. Net.address .. ":" .. Net.port)
        onFail()
      end
    end,
    disconnect = function()
      if client then
        client:unsubscribe()
        client = nil
        leader = false
      end
    end,
    connected = function()
      return client ~= nil
    end,
    send = function(data)
      if not client then
        return
      end
      sendData(data)
    end,
    on = function(event, fn)
      Signal.on("net." .. event, fn)
    end,
    spawn = function(obj, args)
      if not client then
        return
      end
      prepNetObject(obj)
      -- trash function arguments
      args = args or {}
      for prop, val in pairs(args) do
        if type(val) == "function" then
          args[prop] = nil
        end
      end
      triggerSyncFn(obj, args, true)
      args.id = obj.net.id
      sendNetEvent(
        "obj.spawn",
        {
          clientid = Net.id,
          classname = obj.classname,
          args = args
        }
      )
      Net.sync(obj, nil, true)
    end,
    destroy = function(obj)
      if obj.net and not obj.external and not obj.net.persistent then
        sendNetEvent(
          "obj.destroy",
          {
            clientid = Net.id,
            id = obj.net.id
          }
        )
      end
    end,
    -- only to be used with class instances. will not sync functions?/table data (TODO: sync functions too?)
    sync = function(obj, vars, spawning)
      if not Net.connected or not obj or not obj.net or obj.net.external then
        return
      end
      if not obj then
        for objid, obj in pairs(net_objects[Net.id]) do
          Net.sync(obj)
        end
        return
      end
      prepNetObject(obj)
      local net_vars = vars or obj.net.sync or {}
      if not obj.net.external and #net_vars > 0 then
        -- get vars to sync
        local len, sync_data = triggerSyncFn(obj, sync_data, spawning)
        -- sync vars
        if len > 0 then
          sendNetEvent(
            "obj.sync",
            {
              clientid = Net.id,
              id = obj.net.id,
              persistent = obj.net.persistent,
              classname = obj.classname,
              props = sync_data
            }
          )
        end
      end
    end,
    syncAll = function(targetid)
      if not client then
        return
      end
      if leader then
        local sync_objs = {}
        for clientid, objs in pairs(net_objects) do
          sync_objs[clientid] = {}
          for objid, obj in pairs(objs) do
            if obj and not obj.destroyed then
              sync_objs[clientid][objid] = {
                classname = obj.classname,
                net = {id = objid, external = true}
              }
              for _, prop in ipairs(obj.net.sync) do
                sync_objs[clientid][objid][prop] = obj[prop]
              end
              triggerSyncFn(obj, sync_objs[clientid][objid], true)
            end
          end
        end
        sendNetEvent(
          "obj.syncAll",
          {
            clientid = Net.id,
            targetid = targetid,
            sync_objs = sync_objs
          }
        )
      end
    end,
    ip = function()
      local s = socket.udp()
      s:setpeername("74.125.115.104", 80)
      local ip, _ = s:getsockname()
      return ip
    end
  }

  System(
    All("net"),
    {
      added = function(ent)
        if type(ent.net) ~= "table" then
          ent.net = {
            sync = {"pos"}
          }
        end
        if not ent.net.clientid ~= Net.id then
          Net.sync(ent)
        end
      end,
      update = function(ent, dt)
        Net.sync(ent)
      end,
      removed = function(ent)
        Net.destroy(ent)
      end
    }
  )
end