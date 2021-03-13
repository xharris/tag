Component("Camera", { 
  x=0, y=0, sx=1, sy=1, angle=0, ox=0, oy=0,
  viewx=0, viewy=0, w=0, h=0, 
  name=""
})

local cameras = {}
System("Camera", {
  add = function(ent)
    local cam = ent.Camera  
    cameras[cam.name] = cam
    SetupTransform(cam)
  end,
  update = function(ent, dt)
    local cam = ent.Camera 
    cam.x, cam.y = ent.Transform:toLocal(0, 0)
    if cam.w == 0 then cam.w = Game.width end 
    if cam.h == 0 then cam.h = Game.height end 
    local halfw, halfh = cam.w / 2, cam.h / 2
    local tform = cam._transform
    tform:reset()
    tform:translate(halfw + cam.viewx, halfh + cam.viewy)
    tform:scale(cam.sx, cam.sy)
    tform:rotate(cam.angle)
    tform:translate(-floor(cam.x + cam.ox), -floor(cam.y + cam.oy))
  end,
  remove = function(ent)
    cameras[cam.name] = nil
  end
})

Camera = {
  get = function(name)
    return cameras[name]
  end
}