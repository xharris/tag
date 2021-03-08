Bird = function(is_player)
  return Entity{
    Transform = { x=Game.width/2, y=Game.height/2 },
    Input = {},
    Velocity = {},
    FaceMouse = { sx=true },
    Gun = {},
    BirdSprite = {},
    Hitbox = { ox=-16, oy=-16, tag="Bird" }
  }
end