blanke_require("engine.image")
blanke_require("engine.input")
blanke_require("engine.movement")
blanke_require("engine.draw")
blanke_require("engine.window")
blanke_require("engine.canvas")
blanke_require("engine.timer")
blanke_require("engine.collision")

Game = nil
Blanke = nil
mouse_x, mouse_y = 0, 0

--GAME
do
  Game = callable {
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
        World.init()
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

        -- effect
        if Game.options.effect then
          Scene.node.effect = Game.options.effect
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
      -- Physics.update(dt)
      Timer.update(dt, dt_ms)
      if Game.options.update(dt) == true then
        return
      end
      
      --love.profiler:attach()
      World.update(dt)
      --love.profiler:detach()

      Signal.emit("update", dt, dt_ms)
      Input.group = nil
      local key = Input.pressed("_fs_toggle")
      if key and key[1].count == 1 then
        Window.toggleFullscreen()
      end
      Input.keyCheck()
      -- Audio.update(dt)

      -- BFGround.update(dt)

      if Game.restarting then
        Game.load()
        Game.restarting = false
      end
      changed_cache = {}
    end
  }
end

--BLANKE
do
  local update_obj = Game.updateObject
  local stack = Draw.stack

  local _drawGame = function()
    Draw.push()
    Draw.reset()
    Draw.color(Game.options.background_color)
    love.graphics.applyTransform(Scene.node.Transform._transform)
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
    -- Physics.drawDebug()
    -- Hitbox.draw()

    -- end
    -- Foreground.draw()
  end

  Blanke = {
    config = {},
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
      Game._first_update = true
    end,
    --blanke.draw
    draw = function()
      if not (Game.loaded.all and Game._first_update) then
        return
      end
      Game.is_drawing = true
      Draw.origin()

      Draw.push()
      Draw.color("black")
      Draw.rect("fill", 0, 0, Window.width, Window.height)
      Draw.pop()
      
      if Game.options.draw then
        Game.options.draw(_drawGame)
      else
        _drawGame()
      end

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



