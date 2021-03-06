
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


--STATE
State = nil
do
  local states = {}
  local stop_states = {}
  local stateCB = function(name, fn_name, ...)
    local state = states[name]
    assert(state, "State '" .. name .. "' not found")
    if state then
      state.running = true
      State.curr_state = name
      if state.callbacks[fn_name] then
        state.callbacks[fn_name](...)
      end
      State.curr_state = nil
      return state
    end
  end
  local stop_states, start_states
  local stateStart = function(name)
    local state = states[name]
    assert(state, "State '" .. name .. "' not found")
    if state and not state.running then
      stateCB(name, "enter")
      
      World.sort()
    end
  end
  local stateStop = function(name)
    local state = states[name]
    assert(state, "State '" .. name .. "' not found")
    if state and state.running then
      state = stateCB(name, "leave")
      local objs = state.objects
      state.objects = {}
      for _, obj in ipairs(objs) do
        if obj then
          Destroy(obj)
        end
      end
      Timer.stop(name)
      state.running = false
    end
  end
  State =
    class {
    curr_state = nil,
    init = function(self, cbs)
      local name = cbs[1]
      if states[name] then
        return nil
      end
      self.name = name
      self.callbacks = cbs
      self.objects = {}
      self.running = false
      states[name] = self
    end,
    addObject = function(obj)
      local state = states[State.curr_state]
      if state then
        table.insert(state.objects, obj)
      end
    end,
    update = function(dt)
      for name, state in pairs(states) do
        if state.running then
          stateCB(name, "update", dt)
        end
      end
    end,
    draw = function()
      for name, state in pairs(states) do
        if state.running then
          Draw.push()
          stateCB(name, "draw")
          Draw.pop()
        end
      end
    end,
    start = function(name)
      if name then
        if not start_states then
          start_states = {}
        end
        start_states[name] = true
      end
    end,
    stop = function(name)
      if stop_states == "all" then
        return
      end
      if not name then
        stop_states = "all"
      else
        if not stop_states then
          stop_states = {}
        end
        stop_states[name] = true
      end
    end,
    restart = function(name)
      if name then
        stateStop(name)
        stateStart(name)
      end
    end,
    _check = function()
      if stop_states == "all" then
        for name, _ in pairs(states) do
          stateStop(name)
        end
      elseif stop_states then
        for name, _ in pairs(stop_states) do
          stateStop(name)
        end
      end
      if start_states then
        for name, _ in pairs(start_states) do
          stateStart(name)
        end
      end
      stop_states = nil
      start_states = nil
    end
  }
end

-- ECS STUFF

System(All("size", "scale", "scalex", "scaley"), {
  added = function(ent)
    ent.scaled_size = {
      abs(ent.size[1] * ent.scale * ent.scalex),
      abs(ent.size[2] * ent.scale * ent.scaley)
    }
  end
})

function getAlign(ent)
  local ax, ay = 0, 0
  
  ent.scaled_size[1] = abs(ent.size[1] * ent.scale * ent.scalex)
  ent.scaled_size[2] = abs(ent.size[2] * ent.scale * ent.scaley)

  local sizew, sizeh = ent.scaled_size[1], ent.scaled_size[2]
  local type_align = type(ent.align)

  if type_align == 'table' then 
    ax, ay = unpack(ent.align)

  elseif type_align == 'string' then 
    local align = ent.align
    
    if string.contains(align, 'center') then
        ax = 0.5
        ay = 0.5
    end
    if string.contains(align,'left') then
        ax = 0
    end
    if string.contains(align, 'right') then
        ax = 1
    end
    if string.contains(align, 'top') then
        ay = 0
    end
    if string.contains(align, 'bottom') then
        ay = 1
    end
    ent.align = {ax, ay} 
  end 

  local axw, ayh = floor(ax * sizew), floor(ay * sizeh)
  local left, top = floor(ent.pos[1]) - axw, floor(ent.pos[2]) - ayh
  ent.rect = {left, top, left+sizew, top+sizeh, sizew, sizeh}
  return axw, ayh, sizew, sizeh
end

local transform = {}
local dbg_canvas
--RENDER
function Render(_ent, skip_tf)    
  transform = {0,0,0,1,1,0,0,0,0}
  local drawable = _ent.drawable 
  local ent = _ent.parent or _ent
  local quad = ent.quad or _ent.quad
  local ax, ay, sizew, sizeh = getAlign(ent)
  local unscaled_ax, unscaled_ay = abs(ax / ent.scale / ent.scalex), abs(ay / ent.scale / ent.scaley) 

  local lg = love.graphics
  lg.push('all')

  if type(drawable) == 'function' then
    drawable(_ent)

  elseif drawable then 

    Draw.color(ent.color)
    lg.setBlendMode(unpack(ent.blendmode))
    
    local draw = function() 
      if not skip_tf then 
        transform = {
          floor(ent.pos[1]), floor(ent.pos[2]),
          ent.angle, ent.scale * ent.scalex, ent.scale * ent.scaley,
          unscaled_ax, unscaled_ay,
          ent.shear[1], ent.shear[2]
        }
      end 
      if quad then 
        lg.draw(drawable, quad, unpack(transform))
      else
        lg.draw(drawable, unpack(transform))
      end
    end

    if ent.effect and ent.effect.classname == "Blanke.Effect" then 
      ent.effect:draw(draw)
    else 
      draw()
    end 

  end 
  
  if (Game.debug or ent.debug) and not ent.is_game_canvas and not _ent.parent then 
    if not dbg_canvas then 
      dbg_canvas = Canvas{draw=false, auto_clear=false, filter={'nearest','nearest'}, blendmode={"multiply","premultiplied"}} 
    end
    
    dbg_canvas:renderTo(function()
      Draw.color(_ent.debug_color or 'red')
      lg.print(ent.classname, floor(_ent.pos[1]), floor(_ent.pos[2]))
      if not skip_tf then
        lg.translate(floor(_ent.pos[1]), floor(_ent.pos[2]))
        lg.rotate(transform[3])
        lg.shear(transform[8], transform[9])
      end 
      lg.rectangle('line',
        -ax, 
        -ay, 
        ent.scaled_size[1],
        ent.scaled_size[2]
      )
      lg.line(-ax,-ay,-ax+ent.scaled_size[1],-ay+ent.scaled_size[2])
      lg.line(-ax+ent.scaled_size[1],-ay,-ax,-ay+ent.scaled_size[2])
      lg.circle('fill', 0, 0, 3)
      lg.shear(-transform[8], -transform[9])
      lg.rotate(-transform[3])
    end)
  end
  lg.pop()
end