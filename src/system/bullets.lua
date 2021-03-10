System(All("Bullets", "FaceMouse"), {
  update = function(ent, dt)
    local fm, bul = ent.FaceMouse, ent.Bullets
    -- shooting 
    if Input.released("primary") then 
      Scene(ent).addChild(Bullet(ent.parent, fm.angle, bul.speed))
    end 
  end
})
