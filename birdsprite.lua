Animation.set({"bird_stand_front.png", "bird_stand_back.png"}, {
  stand = {
    quads = { {0, 0, 32, 32} }
  },
  stand_fill = {
    quads = { {0, 32, 32, 32} }
  }
})
Animation.set({"bird_walk_front.png", "bird_walk_back.png"}, {
  walk = {
    speed = 10,
    quads = { {0, 0, 32, 32}, {32, 0, 32, 32}, {64, 0, 32, 32}, {96, 0, 32, 32} }
  },
  walk_fill = {
    speed = 10,
    quads = { {0, 32, 32, 32}, {32, 32, 32, 32}, {64, 32, 32, 32}, {96, 32, 32, 32} }
  }
})

System(All("BirdSprite"), {
  added = function(ent)
    ent.BirdSprite = {
      outline = Entity{
        Transform = { ox=16, oy=16 },
        Animation = { skip_reset=true, image="bird_stand_front.png", name="stand" },
      },
      fill = Entity{
        Transform = { ox=16, oy=16 },
        Animation = { skip_reset=true, image="bird_stand_front.png", name="stand_fill" },
      }
    }
    ent.addChild(ent.BirdSprite.outline, ent.BirdSprite.fill)
  end 
})

System(All("BirdSprite", "FaceMouse", "Input"), {
  update = function(ent, dt)
    local vert = ent.FaceMouse.vert
    local walk_image = vert == "up" and "bird_walk_back.png" or "bird_walk_front.png"
    local stand_image = vert == "up" and "bird_stand_back.png" or "bird_stand_front.png"
    local image = ent.Input.all and walk_image or stand_image

    if ent.Input.all then 
      ent.BirdSprite.outline.Animation.name = "walk"
      ent.BirdSprite.fill.Animation.name = "walk_fill"
    else       
      ent.BirdSprite.outline.Animation.name = "stand"
      ent.BirdSprite.fill.Animation.name = "stand_fill"
    end
    ent.BirdSprite.outline.Animation.image = image
    ent.BirdSprite.fill.Animation.image = image 
  end
})