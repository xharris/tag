local bump = blanke_require("bump")
local world 

Component("Hitbox", { w=32, h=32, ox=0, oy=0, filter=nil, collide=nil })
System(All("Hitbox"),{
  add = function(ent)
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
  end,
  remove = function(ent)
    world:remove(ent.Hitbox)
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
      local prevx, prevy = t.x, t.y
      if len > 0 then 
        local col
        for c=1,len do 
          col = cols[c]
          col.actualx = actualx
          col.actualy = actualy
          if not hb.collide or not hb:collide(col.other, col) then 
            -- default collision response
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
            if v.x == 0 then t.x = col.actualx+hb.ox end 
            if v.y == 0 then t.y = col.actualy+hb.oy end
          end
        end 
      end 
    else 
      local actualx, actualy, cols, len = world:move(hb, tx-hb.ox, ty-hb.oy, filter)
      local prevx, prevy = t.x, t.y
      if len > 0 then 
        local ret
        -- custom collision response
        if hb.collide then 
          for c=1, len do 
            cols[c].actualx = actualx
            cols[c].actualy = actualy
            ret = hb:collide(cols[c].other, cols[c]) or ret
          end
        end
        if not ret then 
          if prevx == t.x then t.x = actualx+hb.ox end 
          if prevy == t.y then t.y = actualy+hb.oy end
        end
      end 
    end
  end
})

Hitbox = {
  reactions = {}
}