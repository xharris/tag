Input.set({
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "down", "s" },
  primary = { 'mouse1' },
})

Game{
  background_color = "white",
  window_flags = {
    resizable = true
  },
  load = function()
    Scene.addChild(Bird())
    Entity{
      Transform = { x=Game.width/2, y=Game.height/2 },
      Hitbox = { w=50, h=300 }
    }
  end
}
