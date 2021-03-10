local bump = blanke_require("bump")
local world 

Component("Hitbox", { w=32, h=32, ox=0, oy=0, filter=nil })
System(All("Hitbox"),{
  added = function(ent)
    if not world then 
      world = bump.newWorld()
    end 
    local hb, t = ent.Hitbox, ent.Transform
    local tx, ty = t:toLocal(t.ox, t.oy)
    hb.entityid = ent.uuid
    world:add(hb, tx-hb.ox, ty-hb.oy, hb.w, hb.h)
    -- hb.drawable = function(self)
    --   Draw.rect("line", world:getRect(self))
    -- end
    hb.getRect = function(self)
      return world:getRect(self)
    end
    Scene(ent).addChild(hb)
  end
})

local filter = function(item, other)
  if item.filter or other.filter then 
    local ret
    if item.filter then
      ret = item.filter(item, other) 
      if ret ~= true then 
        return ret
      end
    end 
    if other.filter then 
      ret = other.filter(other, item) 
      if ret ~= true then 
        return ret
      end
    end 
  end 
  if Hitbox.reactions[item.tag] then 
    return Hitbox.reactions[item.tag][other.tag] or Hitbox.reactions[item.tag]['*']
  end
  if Hitbox.reactions[other.tag] then 
    return Hitbox.reactions[other.tag][item.tag] or Hitbox.reactions[other.tag]['*']
  end
end

System(All("Hitbox", Some("Velocity")), {
  update = function(ent, dt)
    local t, hb, v = ent.Transform, ent.Hitbox, ent.Velocity
    local tx, ty = t:toLocal(t.ox, t.oy)

    if v then 
      local actualx, actualy, cols, len = world:move(hb, tx-hb.ox+v.x*dt, ty-hb.oy+v.y*dt, filter)
      if len > 0 then 
        local col
        for c=1,len do 
          col = cols[c]
          if col.type == 'touch' then 
            v.x, v.y = 0, 0
          elseif col.type == 'slide' then 
            if col.normal.x == 0 then 
              v.y = 0
            else 
              v.x = 0
            end 
          elseif col.type == "bounce" then 
            if col.normal.x == 0 then 
              v.y = -v.y
            else 
              v.x = -v.x
            end
          end
        end 
      end 
      t.x = actualx+hb.ox
      t.y = actualy+hb.oy
    else 
      local actualx, actualy, cols, len = world:move(hb, tx-hb.ox, ty-hb.oy, filter)
      if len > 0 then 
        -- print('colliding', world:getRect(hb))
        t.x = actualx+hb.ox
        t.y = actualy+hb.oy
      end 
    end
  end
})

Hitbox = {
  reactions = {}
}