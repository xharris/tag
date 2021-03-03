Image.animation("bird_stand_front.png")
Image.animation("bird_stand_back.png")
Image.animation("bird_walk_front.png", { { rows=1, cols=4, speed=10 } })
Image.animation("bird_walk_back.png", { { rows=1, cols=4, speed=10 } })

Input.set({
  left = { "left", "a", "gp.dpleft" },
  right = { "right", "d", "gp.dpright" },
  up = { "up", "w", "gp.dpup" },
  down = { "down", "s", "gp.dpdown" },
  primary = { 'mouse1' },
})

Game{
  background_color = "white",
  load = function()
    Entity.spawn("Bird", { pos = { Game.width/2, Game.height/2 } })
  end
}
