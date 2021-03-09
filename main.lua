Input.set({
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "down", "s" },
  primary = { 'mouse1' },
})

Hitbox.reactions = {
  Bird = {
    Bullet = 'touch',
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
    Bird()
    Bird(true)
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

System(All("Rotate"), {
  update = function(ent, dt)
    ent.Transform.angle = ent.Transform.angle + ent.Rotate * dt
  end
})

System(All("Hitbox"),{
  added = function(ent)
    ent.Hitbox.drawable = function(self)
      if self.tag == "Wall" then 
        Draw.color("black2")
        Draw.rect("fill", self:getRect())
      else 
        Draw.color("gray")
        Draw.rect("line", self:getRect())
      end
    end
  end
})