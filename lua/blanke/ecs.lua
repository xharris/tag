--[[
  reserved entity properties:
    drawable - love2d object 
    draw - draw automatically or not
    quad - love2d Quad
    renderer - ecs system that renders entity. leave empty to use default
    z 
    uuid
    position, size, angle, scale, scalex, scaley, shear, color, blendmode, align - only set if drawable is set
]]
local abs = math.abs

local call_sys_add
local new_entities = {}
local dead_entities = {}

local entities = {}
local systems = {}
local system_ref = {}

local entity_templates = {} -- TODO: reimplement?
local entity_callable = {}
local spawn

local component_templates = {}

local entity_order = {}

local sys_properties = {'added','update','removed','draw','order','dt_mod'}

Component = function(name, template)
  component_templates[name] = template
end

--ENTITY
Entity = callable {
  __call = function(_, props)
    for name, prop in pairs(props) do 
      Add(props, name, prop)
    end
    return Node(props)
  end,
  get = function(uuid)
    return entities[uuid]
  end 
}

--SYSTEM
System = callable {
  __call = function(_, query, opt)
    local cb = copy(opt)
    local id = uuid()
    cb.order = nil 

    local sys_info = {
      uuid=id,
      query=query,
      order=opt.order,
      cb=cb,
      dt_mod=opt.dt_mod,
      entities={},
      changed={},
      removed={},
      has_entity={}
    }
    table.insert(systems, sys_info)
    system_ref[id] = sys_info

    System.sort()
    return id
  end,
  order = {pre=-10000,_=0,post=10000},
  sort = function()
    table.sort(systems, function(a, b)
      if (type(a.order) ~= "number") then 
        a.order = a.order ~= nil and (System.order[a.order] or a.order) or System.order._
      end
      if (type(b.order) ~= "number") then 
        b.order = b.order ~= nil and (System.order[b.order] or b.order) or System.order._
      end
      return a.order < b.order
    end)
  end
}

All = function(...) return { type="all", args={...} } end
Some = function(...) return { type="some", args={...} } end
Not = function(...) return { type="not", args={...} } end
One = function(...) return { type="one", args={...} } end

Test = function(query, obj, _not) 
  if type(query) == "string" then
    if (_not and obj[query] == nil) or (not _not and obj[query] ~= nil)  then 
      return true 
    end
    return false
  end 
  if type(query) == "table" and query.args then 
    local qtype = query.type
    if qtype == "all" then 
      return table.every(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "some" then 
      return table.some(query.args, function(q) return Test(q, obj, _not) end)
    elseif qtype == "not" then 
      return table.every(query.args, function(q) return Test(q, obj, not _not) end)
    elseif qtype == "one" then 
      local found = 0
      for q = 1, #query.args do 
        if Test(query.args[q], obj, _not) then 
          found = found + 1
        end 
        if found > 1 then return false end 
      end
      if found == 1 then return true end  
    end 
  end 
end 

local _Add
_Add = function (ent, k, v) 
  -- add new entity
  if not ent.uuid then 
    ent.uuid = uuid()
  end 
  entities[ent.uuid] = ent
  -- make sure component has all default properties
  if k or v then 
    if component_templates[k] ~= nil then
      if not ent[k] then 
        ent[k] = copy(component_templates[k])
      end
      if type(ent[k]) == 'table' then 
        table.defaults(ent[k], component_templates[k])
      end 
    end 
  end
end 

function Add(ent, k, v)
  _Add(ent, k, v)
  if not table.includes(new_entities, ent.uuid) then 
    table.insert(new_entities, ent.uuid)
  end 
end

function AddImmediate(ent, k, v)
  _Add(ent, k, v)
  call_sys_add(ent)
end

local remove_prop = {}
function Remove(ent, k)
  for i = 1, table.len(systems) do 
    systems[i].changed[ent.uuid] = true 
  end 
  table.insert(remove_prop, {ent,k})
end 

function Destroy(ent) 
  local sys
  ent.destroyed = true
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if Test(sys.query, ent) then 
      sys.removed[ent.uuid] = true 
      if sys.cb.removed then sys.cb.removed(ent) end 
    end
  end 
  ent.parent.removeChild(ent)
  --nodes[ent.uuid] = nil
end 

local check_sub_entities
check_sub_entities = function(ent, checked)
  if not checked then checked = {} end
  if checked and checked[ent] then return end 
  for k,v in pairs(ent) do 
    if type(v) == 'table' then 
      if v._new and entity_callable[v._new] then 
        -- found a sub-entity
        if v.args.child == true then 
          v.args.parent = ent
        end 
        ent[k] = entity_callable[v._new](v.args)
      else 
        checked[v] = true
        check_sub_entities(v, checked)
      end 
    end 
  end
end

call_sys_add = function(ent)
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if not sys.has_entity[ent.uuid] and Test(sys.query, ent) then
      sys.has_entity[ent.uuid] = true
      -- entity fits in this system
      table.insert(sys.entities, ent.uuid)
      if sys.cb.added then sys.cb.added(ent, args) end 
    end 
  end 
end

--WORLD
World = {
  add = function(ent, args) 
    Add(ent)
    return ent 
  end,
  remove = function(obj) table.insert(dead_entities, obj) end,
  update = function(dt)
    local ent, sys 
    -- remove dead entities 
    for n = 1, table.len(dead_entities) do 
      ent = dead_entities[n]
      for s = 1, table.len(systems) do 
        sys.removed[ent.uuid] = true
      end 
    end 
    dead_entities = {}
    -- added entities 
    for n = 1, table.len(new_entities) do 
      ent = entities[new_entities[n]]
      call_sys_add(ent)
    end 
    new_entities = {}
    Scene.update(dt)
    -- update systems
    local g_time = floor(Game.time * 1000)
    for s = 1, table.len(systems) do 
      sys = systems[s]
      local update, removed = sys.cb.update, sys.cb.removed 
      
      if update and (not sys.dt_mod or g_time % sys.dt_mod == 0) then 
        table.filter(sys.entities, function(eid)
          ent = entities[eid]
          -- entity was removed from world
          if sys.removed[eid] then 
            --if removed then removed(ent) end
            sys.removed[eid] = nil 
            return false 

          -- entity property was changed
          elseif sys.changed[eid] then 
            sys.changed[eid] = nil 
            if Test(sys.query, ent) then 
              -- entity can stay
              return true 
            else 
              -- entity removed from system 
              --if removed then removed(ent) end
              sys.has_entity[eid] = nil
              return false 
            end 
          elseif ent then -- if Camera.visible(ent) then
            update(ent, dt)
          end 
          return true            
        end)
        -- check for changed entities that were not previously in this system 
        for eid,_ in pairs(sys.changed) do 
          if Test(sys.query, entities[eid]) and not table.includes(sys.entities, eid) then
            table.insert(sys.entities, eid)
          end 
        end 
        sys.changed = {}
      end 
    end 

    for r = 1, #remove_prop do
      remove_prop[1][remove_prop[2]] = nil
    end 
    remove_prop = {}
  end,
  draw = function()
    Scene.draw() 
  end,
  drawDebug = function()
    if Game.debug and dbg_canvas then 
      dbg_canvas.pos = Blanke.game_canvas.pos 
      dbg_canvas.scale = Blanke.game_canvas.scale 

      Render(dbg_canvas)
      dbg_canvas:renderTo(function()
        love.graphics.clear(1,1,1,1)
      end)
    end
  end 
}

--SCENE GRAPH stuff
local nodes = {} -- uuid : node
local z_sort = false
local check_z = function(ent)
  if ent.z == nil then ent.z = 0 end
  if ent._last_z ~= ent.z and ent.parent then 
    ent._last_z = ent.z
    ent.parent._needs_sort = true
  end 
end 

--NODE
Node = callable {
  __call = function(_, t)
    if t == nil then t = {} end 
    return Node.from(t)
  end,
  from = function(node)
    if not node.uuid then node.uuid = uuid() end 
    if not node.children then node.children = {} end 
    nodes[node.uuid] = node

    node.addChild = function(...)
      for c = 1,select('#', ...) do 
        local child = select(c, ...)
        Node.from(child)
        -- add child uuid to children table
        if not table.includes(node.children, child.uuid) then 
          table.insert(node.children, child.uuid)
        end 
        child.parent = node
      end
      return node
    end

    node.removeChild = function(...)
      for _, child in ipairs({...}) do 
        if child.parent and child.parent.uuid == node.uuid then
          -- remove child uuid from children table
          table.filter(child.parent.children, function(c)
            return c ~= child.uuid
          end)
        end
      end 
    end

    AddImmediate(node, "Transform")
    if node.drawable then 
      Add(node, "Draw")
    end

    return node
  end
}

-- local spare_tform = love.math.newTransform()
local draw_node = function(node, transform)
  local lg = love.graphics
  if node.drawable then 
    if not node.Draw then Add(node, "Draw") end 

    if type(node.drawable) == 'function' then 
      lg.push()
      if transform then 
        lg.applyTransform(transform._transform)
      end 
      node:drawable()
      lg.pop()
    else
      if node.quad then 
        lg.draw(node.drawable, node.quad, transform and transform._transform)
      else
        lg.draw(node.drawable, transform and transform._transform)
      end
    end
  end
end

--SCENE
Scene = callable {
  scenes = {},
  __call = function(_, name)
    if Scene.scenes[name] then
      return Scene.scenes[name] 
    else 
      Scene.scenes[name] = Entity{}
      return Scene.scenes[name]
    end 
  end,
  init = function()
    if not Scene.node then 
      Scene.node = Entity{ RootNode=true }
    end 
    if not Scene.canvas then
      Scene.canvas = Canvas()
    end 
  end,
  addChild = function(...)
    return Scene.node.addChild(...)
  end,
  update = function(dt, node)
    if not node then 
      Scene.update(dt, Scene.node)
    else   
      if node.children then 
        local child 
        for c, cuuid in ipairs(node.children) do 
          child = nodes[cuuid]
          child.Transform._world:reset()
          if not node.RootNode then
            child.Transform._world:apply(node.Transform._world)
          end
          child.Transform._world:apply(child.Transform._transform)
          Scene.update(dt, child)
        end 
      end 
    end 
  end,
  draw = function(node)
    if not node then 
      if Scene.node then 
        Scene.canvas:renderTo(function()
          Scene.draw(Scene.node, true)
        end)
        local t = Scene.node.Transform
        draw_node(Scene.canvas, Scene.node.Transform)
      end
    else 
      -- draw this node?
      if not node.RootNode then
        check_z(node)
        draw_node(node, node.Transform)
      end
      -- iterate children
      if node.children and node.Transform._transform then 
        love.graphics.push()
        if not node.RootNode then 
          love.graphics.applyTransform(node.Transform._transform)
        end
        local child 
        for c, cuuid in ipairs(node.children) do 
          child = nodes[cuuid]
          if child then 
            Scene.draw(child)
          end
        end 
        love.graphics.pop()

        -- sort z indexes? 
        if node._needs_sort then 
          table.sort(node.children, function(a, b) return nodes[a].z < nodes[b].z end)
          node._needs_sort = false
        end 
      end
    end 
  end
}

Component("Transform", { x=0, y=0, angle=0, sx=1, sy=1, ox=0, oy=0, kx=0, ky=0 })
Component("Draw", { color={1,1,1,1}, blendmode={'alpha'} })

System(All("Transform"), {
  order = System.order.pre-1,
  added = function(ent)
    local t = ent.Transform
    t._transform = love.math.newTransform()
    t._world = love.math.newTransform()
    -- TODO may need to recalculate to compensate for shear (affine tformation)
    t.getWorldTranslate = function(t)
      local a, b, c, d, e, f, g, h, i, j, k, l = t._world:getMatrix()
      return d, h, l
    end
    t.getWorldScale = function(t)
      local a, b, c, d, e, f, g, h, i, j, k, l = t._world:getMatrix()
      local sqrt = math.sqrt
      return sqrt((a*a)+(e*e)+(i*i)), sqrt((b*b)+(f*f)+(j*j)), sqrt((c*c)+(g*g)+(k*k))
    end
    t._transform:setTransformation(
      floor(t.x), floor(t.y), t.angle, 
      t.sx, t.sy, t.ox, t.oy,
      t.kx, t.ky
    )
  end,
  update = function(ent, dt)
    local t = ent.Transform
    t._transform:setTransformation(
      floor(t.x), floor(t.y), t.angle, 
      t.sx, t.sy, t.ox, t.oy,
      t.kx, t.ky
    )
  end 
})

System(All("RootNode"), {
  order = "pre",
  update = function(ent, dt)
    local t = ent.Transform
    -- t.ox = Game.width/2
    -- t.oy = Game.width/2
    if Game.options.scale == true then
      t.x = Blanke.padx
      t.y = Blanke.pady
      t.sx = Blanke.scale
      t.sy = Blanke.scale
    end
  end
})