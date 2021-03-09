System(All("Input"), {
  order = 'pre',
  update = function(ent, dt)
    ent.Input = {
      left = Input.pressed("left"),
      right = Input.pressed("right"),
      up = Input.pressed("up"),
      down = Input.pressed("down"),
      all = Input.pressed("left", "right", "up", "down")
    }
  end 
})

System(All("Input", "Velocity", "Movement8"), {
  update = function(ent, dt)
    local m8, v = ent.Movement8, ent.Velocity
    -- movement
    local vx, vy, max = 0, 0, m8.max
    if ent.Input.left then vx = vx - max end
    if ent.Input.right then vx = vx + max end 
    if ent.Input.up then vy = vy - max end 
    if ent.Input.down then vy = vy + max end
    v.x = vx
    v.y = vy
  end 
})