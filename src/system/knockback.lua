Knockback = {
  add = function(ent, fromx, fromy, pwr)
    local kb, t, v = ent.Knockback, ent.Transform, ent.Velocity
    if not kb then 
      kb = Add(ent, "Knockback")
    end
    local angle = Math.angle(fromx, fromy, t.x, t.y)
    local x, y = Math.getXY(angle, pwr)
    kb.x, kb.y = kb.x + x, kb.y + y

    if v then 
      v.x, v.y = v.x - kb.x, v.y - kb.y 
    end 
  end
}

local abs = math.abs
System(All("Knockback"), {
  update = function(ent, dt)
    local kb, t, v = ent.Knockback, ent.Transform

    if kb.x ~= 0 then 
      kb.x = kb.x * 0.9
      if abs(kb.x) < 1 then kb.x = 0 end
    end
    if kb.y ~= 0 then 
      kb.y = kb.y * 0.9
      if abs(kb.y) < 1 then kb.y = 0 end
    end

    t.x = t.x + kb.x * dt 
    t.y = t.y + kb.y * dt 
  end
})