function Bullet(fromentity, angle, speed)
  local tx, ty = fromentity.Transform:toLocal(0, 0)
  local vx, vy = Math.getXY(angle, speed)

  return Entity{
    z = -20,
    Transform = { x=tx, y=ty, ox=9, oy=3.5, angle=angle },
    Velocity = { x=vx, y=vy },
    Image = "bullet.png",
    Hitbox = { w=7, h=7, ox=3.5, oy=3.5, tag="Bullet", from=fromentity, filter=function(item, other)
      if other.tag == "Bird" then 
        if other.entityid == fromentity.uuid then 
          -- came from the entity that shot the bullet
          return 'cross'
        end
      end
      return true
    end }
  }
end