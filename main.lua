Input.set({
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "down", "s" },
  primary = { 'mouse1' },
})

Hitbox.reactions = {
  Bird = {
    Bullet = 'cross',
    Wall = 'slide'
  },
  Wall = {
    ['*'] = 'touch'
  }
}

Game{
  background_color = "white",
  window_flags = {
    resizable = true
  },
  load = function()
    Bird()
    Entity{
      Transform = { x=Game.width*3/4, y=Game.height/2 },
      Hitbox = { w=50, h=300, tag="Wall" }
    }
    Entity{
      Transform = { x=Game.width*1/4, y=Game.height/2 },
      Hitbox = { w=50, h=300, tag="Wall" }
    }
  end
}
