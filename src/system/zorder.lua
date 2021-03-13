System(All("ZOrder"), {
  update = function(ent, dt)
    if ent.ZOrder.vertical then 
      ent.z = ent.Transform.y 
    end
  end
})