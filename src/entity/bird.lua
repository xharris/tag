function Bird(is_player)
  local components = {
    Transform = { x=Game.width/2, y=Game.height/2 },
    BirdSprite = {},
    Hitbox = { w=24, h=24, ox=12, oy=12, tag="Bird" },
    Velocity = {},
    ZOrder = { vertical=true },
    Health = {},
    Team = true,

    Input = {},
    Movement8 = { max=50 },
  }
  if is_player then
    table.update(components, {
      Movement8 = { max=140 },
      FaceMouse = { sx=true, camera="player" },
      Camera = { name="player" }
    })
    return Entity(components, Gun(ent))
  end
  return Entity(components) 
end