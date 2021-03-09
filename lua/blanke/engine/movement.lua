--ENTITY: gravity, velocity
Component("Velocity", { x = 0, y = 0 })
System(
  All("Velocity", Not("Hitbox")),
  {
    update = function(ent, dt)
      ent.Transform.x = ent.Transform.x + ent.Velocity.x * dt
      ent.Transform.y = ent.Transform.y + ent.Velocity.y * dt
    end
  }
)

Component("Gravity", { direction = Math.rad(90), amount = 0 })
System(
  All("Gravity", "Velocity"),
  {
    update = function(ent, dt)
      local gravx, gravy = Math.getXY(ent.Gravity.direction, ent.Gravity.amount)
      ent.Velocity.x = ent.Velocity.x + gravx
      ent.Velocity.y = ent.Velocity.y + gravy
    end
  }
)