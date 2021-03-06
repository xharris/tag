Component("Input", { left = false, right = false, up = false, down = false, primary = false })

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

System(All("Input", "Velocity"), {
  update = function(ent, dt)
    -- movement
    local vx, vy, v = 0, 0, 140
    if ent.Input.left then vx = vx - v end
    if ent.Input.right then vx = vx + v end 
    if ent.Input.up then vy = vy - v end 
    if ent.Input.down then vy = vy + v end
    ent.Velocity = { x=vx, y=vy }
  end 
})