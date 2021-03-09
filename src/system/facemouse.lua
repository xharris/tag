System(All("FaceMouse"), {
  update = function(ent, dt)
    local fm = ent.FaceMouse
    local entity = ent
    -- you can base the rotation off the position of a different entity
    if fm.use_parent then 
      entity = ent.parent
    end
    local angle = Math.deg(Math.angle(entity.Transform.x, entity.Transform.y, mouse_x, mouse_y)) + 180
    local quadrant = Math.ceil(angle / 90) -- 1:topleft, 2:topright, 3:bottomright, 4:bottomleft 
    fm.angle = Math.rad(angle - 180)
    fm.quadrant = quadrant
    fm.vert = (quadrant == 1 or quadrant == 2) and "up" or "down"
    fm.horiz = (quadrant == 1 or quadrant == 4) and "left" or "right"
    -- change direction facing
    if fm.sx then 
      ent.Transform.sx = (fm.horiz == "left") and -1 or 1
    end 
    if fm.sy then 
      ent.Transform.sy = (fm.vert == "up") and -1 or 1
    end 
    -- NOTE would need changes if sx and sy were both true
    if fm.rotate then
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
    -- z ordering for parent/child
    if fm.entity and fm.zorder then 
      ent.z = fm.vert == "up" and fm.zorder or -fm.zorder
    end
  end
})