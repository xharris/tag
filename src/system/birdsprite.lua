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
  add = function(ent)
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
    local fm, bs = ent.FaceMouse, ent.BirdSprite
    local walk_image = fm.vert == "up" and "bird_walk_back.png" or "bird_walk_front.png"
    local stand_image = fm.vert == "up" and "bird_stand_back.png" or "bird_stand_front.png"
    local image = ent.Input.all and walk_image or stand_image

    if ent.Input.all then 
      bs.outline.Animation.name = "walk"
      bs.fill.Animation.name = "walk_fill"
    else       
      bs.outline.Animation.name = "stand"
      bs.fill.Animation.name = "stand_fill"
    end
    bs.outline.Animation.image = image
    bs.fill.Animation.image = image
  end
})

System(All("BirdSprite", "Team"), {
  update = function(ent, dt)
    local bs, team = ent.BirdSprite, ent.Team 
    local a = 1
    bs.fill.Draw.color = {Team.colors[team],a}
    ent.Draw.color = {1,1,1,a}
  end
})