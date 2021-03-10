function Wall(x, y, w, h)
  return Entity{
    Transform = { x=x, y=y },
    Hitbox = { w=w, h=h, tag="Wall" }
  }
end