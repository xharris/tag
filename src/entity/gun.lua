function Gun(parent)
  local ent = Entity{
    Image = "gun.png",
    Transform = { x=5, oy=3.5 },
    FaceMouse = { use_parent=true, zorder=1, rotate=true },
    Bullets = { speed=600 }
  }
  return ent
end