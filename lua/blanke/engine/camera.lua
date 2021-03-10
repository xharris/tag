Component("Camera", { x=0, y=0, name="", follow=false })

local cameras = {}
System("Camera", {
  added = function(ent)
    local cam = ent.Camera  
    cameras[cam.name] = cam
    SetupTransform(cam)
  end,
  update = function(ent, dt)
    local cam = ent.Camera 
    local tx, ty = ent.Transform:toLocal(0, 0)
    cam._transform:setTransformation(
      -(tx - Game.width/2), -(ty - Game.height/2)
    )
  end,
  removed = function(ent)
    cameras[cam.name] = nil
  end
})

Camera = {
  get = function(name)
    return cameras[name]
  end
}