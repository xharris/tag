function Bullet(fromentity, angle, speed)
  local tx, ty = fromentity.Transform:toLocal(0, 0)
  local vx, vy = Math.getXY(angle, speed)

  return Entity{
    z = -20,
    Transform = { x=tx, y=ty, ox=9, oy=3.5, angle=angle },
    Velocity = { x=vx, y=vy },
    Image = "bullet.png",
    Damage = { },
    Hitbox = { w=5, h=5, ox=2.5, oy=2.5, tag="Bullet", from=fromentity, 
      filter=function(item, other)
        if other.tag == "Bird" then 
          if other.entityid == fromentity.uuid then 
            -- came from the entity that shot the bullet
            return 'cross'
          end
        end
        return true
      end,
      collide=function(item, other, col)
        if col.type == "touch" then 
          Remove(item.entityid, "Hitbox")
          if other.tag == "Bird" then 
            local ent_bird, ent_bullet = Entity.get(other.entityid), Entity.get(item.entityid)
            -- stick the bullet to the bird by converting global coordinates to bird's local coordinates
            local bullx, bully = ent_bullet.Transform:toLocal(0, 0)
            local newx, newy = ent_bird.Transform:toGlobal(col.actualx, col.actualy)
            ent_bullet.Transform.x, ent_bullet.Transform.y = newx, newy
            col.actualx, col.actualy = newx, newy
            ent_bird.addChild(ent_bullet)
            -- lose hp 
            if ent_bird.Health then 
              ent_bird.Health.current = ent_bird.Health.current - ent_bullet.Damage.amt
            end 
            -- knockback
            Knockback.add(ent_bird, bullx, bully, 100)
          end
        end
      end 
    }
  }
end