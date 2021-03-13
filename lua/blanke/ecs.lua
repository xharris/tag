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

local is_component = {}
local component_templates = {}
local template_is_table = {}

local entity_order = {}

local sys_properties = {'add','update','remove','draw','order','dt_mod'}

Component = function(name, template)
  is_component[name] = true
  template_is_table[name] = type(template) == 'table'
  if template_is_table[name] then 
    template._name = name
    component_templates[name] = template 
  end
end

--ENTITY
Entity = callable {
  __call = function(_, props, ...)
    props = props or {}
    if not props.uuid then props.uuid = uuid() end
    for name, prop in pairs(props) do
      Add(props, name, prop)
    end
    local node = Node(props)
    Scene.addChild(node)
    -- add any child entities
    for c = 1,select("#", ...) do 
      node.addChild(select(c, ...))
    end 
    return node
  end,
  get = function(uuid)
    assert(entities[uuid], "Could not find entity with id \""..uuid.."\"")
    return entities[uuid]
  end 
}

--SYSTEM
System = callable {
  __call = function(_, query, opt)
    local cb = copy(opt)
    local id = uuid()
    cb.order = nil 

    if type(query) == "string" then query = All(query) end

    local sys_info = {
      uuid=id,
      query=query,
      order=opt.order,
      cb=cb,
      dt_mod=opt.dt_mod,
      entities={},
      remove_entity={},
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

function print_query(q, depth)
  local first = depth == nil
  local str = q.type..'('
  if first then 
    str = "Query\t"..str
  end 
  for a, arg in ipairs(q.args) do 
    if type(arg) == 'table' then 
      str = str..print_query(arg, depth == nil and 0 or depth + 1)
    else 
      str = str..arg
    end 
    if a < #q.args then 
      str = str..', '
    end 
  end
  str = str..')'
  if first then
    print(str)
  end
  return str
end

function print_entity(ent, expand)
  local str = "Entity\t"..ent.uuid..' {'
  local props = {}
  if expand then 
    str = str .. '\n'
    for k, v in pairs(ent) do 
      if component_templates[k] then 
        local cprops = {}
        for k2,v2 in pairs(v) do 
          if type(v) == 'table' and k ~= 'children' and type(v) ~= "function" then 
            table.insert(cprops, '\t\t\t'..k2.."="..tostring(v2))
          end
        end
        table.insert(props, '\t'..k..'\n'..table.join(cprops,'\n'))
      end 
    end
    str = str..table.join(props, '\n')
  else 
    for k, v in pairs(ent) do 
      if is_component[k] then 
        table.insert(props, k)
      end 
    end
    str = str..table.join(props, ',')..'}'
  end
  print(str)
  return str
end

All = function(...) return { type="all", args={...} } end
Some = function(...) return { type="some", args={...} } end
Not = function(...) return { type="not", args={...} } end
One = function(...) return { type="one", args={...} } end

Test = function(query, obj, _not) 
  if type(query) == "string" then
    assert_warn_once(is_component[query], "Component \"", query, "\" is not declared")
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

call_sys_add = function(ent)
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if not sys.has_entity[ent.uuid] and Test(sys.query, ent) then
      sys.has_entity[ent.uuid] = true
      -- entity fits in this system
      table.insert(sys.entities, ent.uuid)
      if sys.cb.add then 
        sys.cb.add(ent) 
      end 
    end 
  end 
end

local _Add
_Add = function (ent, k) 
  -- add new entity
  if not ent.uuid then 
    ent.uuid = uuid()
  end 
  entities[ent.uuid] = ent
  -- make sure component has all default properties
  if k then 
    if is_component[k] then 
      if not ent[k] then 
        ent[k] = copy(component_templates[k])
      elseif template_is_table[k] then
        table.defaults(ent[k], component_templates[k])
      end
    end 
  end
end 

function Add(ent, k, v)
  ent[k] = v or ent[k]
  _Add(ent, k)
  if not table.includes(new_entities, ent.uuid) then 
    table.insert(new_entities, ent.uuid)
  end 
  return ent[k]
end

function Remove(ent, k)
  if type(ent) == "string" then 
    ent = Entity.get(ent)
  end 
  -- make entity copy without the removed prop 
  local fake_ent = {}
  for k2,v in pairs(ent) do 
    if is_component[k2] then 
      fake_ent[k2] = true
    end
  end 
  fake_ent[k] = nil
  -- iterate systems
  local sys, ent2
  for s=1, #systems do 
    sys = systems[s]
    local remove = sys.cb.remove
    table.filter(sys.entities, function(eid)
      ent2 = entities[eid]
      if eid == ent.uuid then 
        if Test(sys.query, fake_ent) then 
          return true
        else 
          if remove then remove(ent2) end 
          sys.has_entity[eid] = nil 
          return false
        end 
      end
      return true
    end)
  end
   
  if ent[k].parent then 
    ent[k].parent.removeChild(ent[k])
  end
  ent[k] = nil
end 

function Destroy(ent) 
  local sys
  ent.destroyed = true
  for i = 1, table.len(systems) do 
    sys = systems[i]
    if Test(sys.query, ent) then 
      sys.remove_entity[ent.uuid] = true 
      if sys.cb.remove then sys.cb.remove(ent) end 
    end
  end 
  ent.parent.removeChild(ent)
  --nodes[ent.uuid] = nil
end 


--WORLD
World = {
  init = function()
    Scene.init()
  end,
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
        sys.remove_entity[ent.uuid] = true
      end 
    end 
    dead_entities = {}
    Scene.update(dt)
    -- add entities
    local new_entities_copy = {unpack(new_entities)}
    new_entities = {}
    for n = 1, table.len(new_entities_copy) do 
      ent = entities[new_entities_copy[n]]
      call_sys_add(ent)
    end 
    local g_time = floor(Game.time * 1000)
    for s = 1, #systems do 
      sys = systems[s]
      local update, remove = sys.cb.update, sys.cb.remove 
 
      table.filter(sys.entities, function(eid)
        ent = entities[eid]
        -- entity was removed from system
        if not sys.has_entity[eid] then 
          return false 
        end
        -- update entity
        if update and (not sys.dt_mod or g_time % sys.dt_mod == 0) then -- if Camera.visible(ent) then
          update(ent, dt)
        end 
        return true            
      end)
    end 
  end,
  draw = function()
    for name, scene in pairs(Scene.scenes) do 
      Scene.draw(name) 
    end 
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

function SetupTransform(t)
  if not t._transform then 
    t._transform = love.math.newTransform()
    t._world = love.math.newTransform()
    t.toLocal = function(self, x, y)
      return self._transform:transformPoint(x, y)
    end
    t.toGlobal = function(self, x, y)
      return self._transform:inverseTransformPoint(x, y)
    end
    t.getWorldScale = function(self)
      local a, b, c, d, e, f, g, h, i, j, k, l = self._world:getMatrix()
      local sqrt = math.sqrt
      return sqrt((a*a)+(e*e)+(i*i)), sqrt((b*b)+(f*f)+(j*j)), sqrt((c*c)+(g*g)+(k*k))
    end
    t.updateTransform = function(s)
      s._transform:setTransformation(
        floor(s.x), floor(s.y), s.angle, 
        s.sx, s.sy, s.ox, s.oy,
        s.kx, s.ky
      )
    end
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
    if not nodes[node.uuid] then 
      nodes[node.uuid] = node

      node.addChild = function(...)
        for c = 1,select('#', ...) do 
          local child = select(c, ...)
          if not child.RootNode then 
            Node.from(child)
            if child.parent then 
              child.parent.removeChild(child)
            end 
            -- add child uuid to children table
            if not table.includes(node.children, child.uuid) then 
              table.insert(node.children, child.uuid)
            end 
            child.parent = node
            child.scene = node.is_scene or node.scene
            child.Transform:updateTransform()
          end
        end
        node._needs_sort = true
        return node
      end

      node.removeChild = function(...)
        for _, child in ipairs({...}) do 
          if child.parent and child.parent.uuid == node.uuid then
            -- remove child uuid from children table
            child.scene = nil
            table.filter(child.parent.children, function(c)
              return c ~= child.uuid
            end)
          end
        end 
      end
    end 

    Add(node, "Transform")
    Add(node, "Draw")
    
    local t = node.Transform
    SetupTransform(t)
    node.Transform._transform:setTransformation(
      floor(t.x), floor(t.y), t.angle, 
      t.sx, t.sy, t.ox, t.oy,
      t.kx, t.ky
    )

    return node
  end
}

-- local spare_tform = love.math.newTransform()
local draw_node = function(node, transform)
  local lg = love.graphics

  if node.drawable then 
    if type(node.drawable) == 'function' then 
      if transform then 
        lg.applyTransform(transform._transform)
      end 
      node:drawable()
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
  __call = function(_, name, props)
    if type(name) == "table" and name.scene then 
      -- using entity as arg 
      name = name.scene
    end 
    if Scene.scenes[name] then
      return Scene.scenes[name] 
    else 
      Scene.scenes[name] = Node(props)
      Scene.scenes[name].canvas = Canvas()
      Scene.scenes[name].is_scene = name
      return Scene.scenes[name]
    end 
  end,
  init = function()
    Scene("root", { RootNode=true })
    if not Scene.canvas then
      Scene.canvas = Canvas()
    end 
  end,
  addChild = function(...)
    return Scene("root").addChild(...)
  end,
  update = function(dt, node)
    if not node then 
      for name, scene in pairs(Scene.scenes) do 
        Scene.update(dt, scene, 0)
      end
    else  
      if node.children then 
        local child 
        for c, cuuid in ipairs(node.children) do 
          child = nodes[cuuid]
          -- check scene property is correct
          child.scene = node.is_scene or node.scene 
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
  draw = function(scene_name, camera_name)
    scene_name = scene_name or 'root'

    local scene = Scene(scene_name)
    local cam = Camera.get(camera_name)
    local lg = love.graphics
    Scene.canvas:renderTo(function()
      if cam then 
        lg.push()
        lg.applyTransform(cam._transform)
      end
      Scene._draw(scene, scene)
      if cam then 
        lg.pop()
      end 
    end)
    draw_node(Scene.canvas, Scene.scenes.root.Transform)
  end,
  _draw = function(node, scene)
    if node then 
      local lg = love.graphics
      local drw = node.Draw

      lg.push('all') 
        
      if drw.color then Draw.color(drw.color) end 

      -- draw this node?
      if node.uuid ~= scene.uuid then
        draw_node(node, node.Transform)
      end
      check_z(node)

      -- iterate children
      if node.children and node.Transform._transform then 
        if not node.RootNode then 
          lg.applyTransform(node.Transform._transform)
        end
        local child 
        for c, cuuid in ipairs(node.children) do 
          child = nodes[cuuid]
          if child then 
            Scene._draw(child, scene) 
          end
        end 

        -- sort z indexes? 
        if node._needs_sort then 
          table.sort(node.children, function(a, b) return nodes[a].z < nodes[b].z end)
          node._needs_sort = false
        end 
      end

      lg.pop()

      return head_open
    end 
  end
}

Component("Transform", { x=0, y=0, angle=0, sx=1, sy=1, ox=0, oy=0, kx=0, ky=0 })
Component("Draw", { color=false, blendmode=false, crop=false })

System(All("Transform"), {
  order = System.order.pre-1,
  update = function(ent, dt)
    ent.Transform:updateTransform()
  end 
})

Component("RootNode")

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