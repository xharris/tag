System(All("DestroyAfterTime"),{
  add = function(ent)
    ent.DestroyAfterTime.t = 0
  end,
  update = function(ent, dt)
    local dat = ent.DestroyAfterTime
    dat.t = dat.t + dt 
    if dat.t > dat.time then 
      Destroy(ent)
    end 
  end
})