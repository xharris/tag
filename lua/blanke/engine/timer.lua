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