System(All("FaceMouse"), {
  update = function(ent, dt)
    local entity = ent
    -- you can base the rotation off the position of a different entity
    if ent.FaceMouse.entity then 
      entity = ent.FaceMouse.entity
    end
    local angle = Math.deg(Math.angle(entity.Transform.x, entity.Transform.y, mouse_x, mouse_y)) + 180
    local quadrant = Math.ceil(angle / 90) -- 1:topleft, 2:topright, 3:bottomright, 4:bottomleft 
    ent.FaceMouse.angle = Math.rad(angle - 180)
    ent.FaceMouse.quadrant = quadrant
    ent.FaceMouse.vert = (quadrant == 1 or quadrant == 2) and "up" or "down"
    ent.FaceMouse.horiz = (quadrant == 1 or quadrant == 4) and "left" or "right"
    -- change direction facing
    if ent.FaceMouse.sx then 
      ent.Transform.sx = (ent.FaceMouse.horiz == "left") and -1 or 1
    end 
    if ent.FaceMouse.sy then 
      ent.Transform.sy = (ent.FaceMouse.vert == "up") and -1 or 1
    end 
    -- NOTE would need changes if sx and sy were both true
    if ent.FaceMouse.rotate then
      if (entity.FaceMouse.sx and entity.Transform.sx > 0) then 
        ent.Transform.angle = Math.rad(angle - 180)
      elseif entity.FaceMouse.sy then 
        if entity.Transform.sy < 0 then 
          ent.Transform.angle = Math.rad(-angle - 180)
        else 
          ent.Transform.angle = Math.rad(angle + 180)
        end 
      else
        ent.Transform.angle = Math.rad(-angle)
      end 
    end 
  end
})