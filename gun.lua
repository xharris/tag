System(All("Gun"), {
  added = function(ent)
    ent.Gun = Entity{
      Image = "gun.png",
      Transform = { x=5, oy=3.5 },
      FaceMouse = { entity=ent, rotate=true }
    }
    ent.addChild(ent.Gun)
  end,
  update = function(ent, dt)
    ent.Gun.z = ent.FaceMouse.vert == "up" and 10 or -10
    -- shooting 
    if Input.released("primary") then 
      local angle = ent.Gun.FaceMouse.angle
      local tx, ty = ent.Transform:getWorldTranslate()
      local vx, vy = Math.getXY(angle, 600)
      
      local bullet = Entity{
        z = -20,
        Transform = { x=tx, y=ty, ox=-1, oy=3.5, angle=angle },
        Velocity = { x=vx, y=vy },
        Image = "bullet.png",
        DestroyAfterTime = { time=0.5 }
      }
      Scene.addChild(bullet)
    end 
  end
})

System(All("DestroyAfterTime"),{
  added = function(ent)
    ent.DestroyAfterTime.t = 0
  end,
  update = function(ent, dt)
    local dat = ent.DestroyAfterTime
    dat.t = dat.t + dt 
    if dat.t > dat.time then 
      Destroy(ent)
    end 
  end
})