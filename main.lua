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
    ['*'] = 'touch',
    Wall = 'cross'
  }
}

Game{
  background_color = "white",
  window_flags = {
    resizable = true
  },
  load = function()
    local ScnGame = Scene("game")
    ScnGame.addChild(Bird(true))
    
    local objects = {
      Wall = {
        fn = Wall,
        args = { 'x', 'y', 'width', 'height' }
      }
    }

    local map_test = require(Game.res("map", "test"))
    for l, layer in ipairs(map_test.layers) do 
      if layer.type == "objectgroup" then 
        local info = objects[layer.name]
        if info then 
          for o, object in ipairs(layer.objects) do 
            -- gather function args
            local args = {}
            for _, k in ipairs(info.args) do 
              table.insert(args, object[k])
            end
            ScnGame.addChild(info.fn(unpack(args)))
          end
        end
      end
    end 
  end,
  draw = function()
    Scene.draw("game", "player")
  end
}

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