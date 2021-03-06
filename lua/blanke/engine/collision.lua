local bump = blanke_require("bump")
local word 

Component("Hitbox", { w=32, h=32, ox=0, oy=0 })
System(All("Hitbox"),{
  added = function(ent)
    if not world then 
      world = bump.newWorld()
    end 
    local hb, t = ent.Hitbox, ent.Transform
    local tx, ty = t:getWorldTranslate()
    world:add(hb, tx+hb.ox, ty+hb.oy, hb.w, hb.h)
    print('add', t.x, t.y, tx+hb.ox, ty+hb.oy, hb.w, hb.h,ent.uuid)
    hb.drawable = function(self)
      Draw.rect("line", world:getRect(self))
    end
    Scene.addChild(hb)
  end,
  update = function(ent, dt)
    local t, hb = ent.Transform, ent.Hitbox
    local tx, ty = t:getWorldTranslate()
    local actualx, actualy, cols, len = world:move(hb, tx+hb.ox, ty+hb.oy)
    if len > 0 then 
      -- print('colliding', world:getRect(hb))
    end 
  end
})