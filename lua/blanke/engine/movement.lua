--ENTITY: gravity, velocity
Component("Velocity", { x = 0, y = 0 })
System(
  All("Velocity"),
  {
    update = function(ent, dt)
      local t, v = ent.Transform, ent.Velocity
      t.x = t.x + v.x * dt
      t.y = t.y + v.y * dt
    end
  }
)

Component("Gravity", { direction = Math.rad(90), amount = 0 })
System(
  All("Gravity", "Velocity"),
  {
    update = function(ent, dt)
      local v = ent.Velocity
      local gravx, gravy = Math.getXY(ent.Gravity.direction, ent.Gravity.amount)
      v.x = v.x + gravx
      v.y = v.y + gravy
    end
  }
)