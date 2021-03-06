blanke_require = function(r)
    return require('blanke.'..r)
end

uuid = blanke_require("uuid")
json = blanke_require("json")
class = blanke_require("clasp")
blanke_require("print_r")

blanke_require('util')
blanke_require('ecs')
blanke_require('core')

require 'imgui'

local profiling_color = {1,0,0,1}

love.load = function()
  if do_profiling and do_profiling > 0 then
      love.profiler = blanke_require("piefiller"):new()-- blanke_require('profile')
      -- love.profiler.start()
  else
      do_profiling = nil
  end

  Blanke.load()
end

love.frame = 0
local update = function(dt)
  if do_profiling and do_profiling > 0 then
    --[[
      love.frame = love.frame + 1
      if love.frame % 100 == 0 then
          love.report = love.profiler.report(do_profiling)
          --love.profiler.reset()
      end
      ]]
  else
      do_profiling = nil
  end

  Blanke.update(dt)

  if do_profiling then 
    love.profiler:detach()
  end 
end

do
  local dt = 0
  local accumulator = 0
  local fixed_dt
  love.update = function(dt)
    imgui.NewFrame()
      fixed_dt = Game.options.fps and 1/Game.options.fps or nil
      if fixed_dt == nil then
          update(dt)
      else
          accumulator = accumulator + dt
          while accumulator >= fixed_dt do
              update(fixed_dt)
              accumulator = accumulator - fixed_dt
          end
      end
  end
end
love.draw = function()
  Blanke.draw()
  if do_profiling then 
    love.profiler:draw()
  end 
  -- imgui.ShowDemoWindow(true)
  imgui.Render()
end
love.resize = function(w, h) Blanke.resize(w, h) end
love.gamepadpressed = function(joystick, button) Blanke.gamepadpressed(joystick, button) end
love.gamepadreleased = function(joystick, button) Blanke.gamepadreleased(joystick, button) end
love.joystickadded = function(joystick) Blanke.joystickadded(joystick) end
love.joystickremoved = function(joystick) Blanke.joystickremoved(joystick) end
love.gamepadaxis = function(joystick, axis, value) Blanke.gamepadaxis(joystick, axis, value) end
love.touchpressed = function(id, x, y, dx, dy, pressure) Blanke.touchpressed(id, x, y, dx, dy, pressure) end
love.touchreleased = function(id, x, y, dx, dy, pressure) Blanke.touchreleased(id, x, y, dx, dy, pressure) end
-- love.keypressed = function(key, scancode) Blanke.keypressed(key, scancode) end
-- love.keyreleased = function(key, scancode) Blanke.keyreleased(key, scancode) end
-- love.mousepressed = function(...) Blanke.mousepressed(...) end
-- love.mousereleased = function(x, y, button, istouch, presses) Blanke.mousereleased(x, y, button, istouch, presses) end
-- love.wheelmoved = function(x, y) Blanke.wheelmoved(x, y) end
function love.textinput(t)
  imgui.TextInput(t)
  if not imgui.GetWantCaptureKeyboard() then
      -- Pass event to the game
  end
end

function love.keypressed(key)
  imgui.KeyPressed(key)
  if not imgui.GetWantCaptureKeyboard() then
    Blanke.keypressed(key) 
  end
end

function love.keyreleased(key, scancode)
  imgui.KeyReleased(key)
  if not imgui.GetWantCaptureKeyboard() then
      -- Pass event to the game
      Blanke.keyreleased(key, scancode)
  end
end

function love.mousemoved(x, y)
  imgui.MouseMoved(x, y)
  if not imgui.GetWantCaptureMouse() then
      -- Pass event to the game
  end
end

function love.mousepressed(x, y, button)
  imgui.MousePressed(button)
  if not imgui.GetWantCaptureMouse() then
    -- Pass event to the game
    Blanke.mousepressed(x, y, button) 
  end
end

function love.mousereleased(x, y, button, istouch, presses)
  imgui.MouseReleased(button)
  if not imgui.GetWantCaptureMouse() then
    -- Pass event to the game
    Blanke.mousereleased(x, y, button, istouch, presses)
  end
end

function love.wheelmoved(x, y)
  imgui.WheelMoved(y)
  if not imgui.GetWantCaptureMouse() then
    -- Pass event to the game
    Blanke.wheelmoved(x, y)
  end
end

love.quit = function()
  imgui.ShutDown()
  Save.save()
  local stop = false
  if Game.forced_quit then return stop end
  local abort = function() stop = true end
  Signal.emit("Game.quit", abort)

  if not stop and do_profiling and love.report then
      local f = FS.open('profile.txt', 'w')
      f:write(love.report)
      f:close()
      FS.openURL("file://"..Save.dir().."/profile.txt")
  end

  return stop
end