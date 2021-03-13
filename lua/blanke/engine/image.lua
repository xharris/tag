--IMAGE: image
Component("Image") -- imagepath
System(
  All("Image"),
  {
    add = function(ent)
      ent.Image = {
        drawable = Cache.image(ent.Image),
        name = ent.Image
      }
      ent.addChild(ent.Image)
    end,
    update = function(ent)
      if changed(ent.Image, 'name') then 
        reset(ent.Image, 'name')
        ent.Image.drawable = Cache.image(ent.Image.name)
      end 
    end 
  }
)

Animation = {
  animations = {},
  set = function(images, obj)
    if type(images) == "string" then 
      images = {images}
    end

    for _, imgname in ipairs(images) do 
      for aniname, info in pairs(obj) do 
        local name = imgname..'-'..aniname
        Animation.animations[name] = {}
        local ani = Animation.animations[name]

        ani.image = Cache.image(imgname)
        ani.quads = {}
        -- setup quads
        for _, quadinfo in ipairs(info.quads) do 
          table.insert(ani.quads, Cache.quad(imgname, unpack(quadinfo)))
        end 
        -- other default info 
        ani.frames = #ani.quads
        ani.speed = info.speed or 0
      end 

    end
  end
}

local get_animation = function(ani)
  return assert(Animation.animations[ani.image..'-'..ani.name], "Animation {image=\""..ani.image.."\", name=\""..ani.name.."\"} not found")
end

--ANIMATION
Component("Animation", { image="", name="" })
System(
  All("Animation"),
  {
    add = function(ent)
      local ani = ent.Animation
      local info = get_animation(ani)
      ani.t = 0
      ani.drawable = info.image
      ent.addChild(ani)
    end,
    update = function(ent, dt)
      local ani = ent.Animation
      local info = get_animation(ani)
      if not ani.skip_reset and (changed(ent.Animation, 'name') or changed(ent.Animation, 'image')) then 
        reset(ent.Animation, 'name')
        reset(ent.Animation, 'image')
        ani.t = 0
        ani.frame = 1
      end
      ani.drawable = info.image
      ani.t = ani.t + info.speed * dt
      if info.frames > 0 then 
        ani.frame = (floor(ani.t) % info.frames) + 1
        ani.quad = info.quads[ani.frame]
      else 
        ani.frame = 1
        ani.quad = nil
      end 
    end
  }
)

