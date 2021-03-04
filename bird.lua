Entity{
  "Bird", 
  image = "bird_stand_back",
  align = "center",
  pos = { 0, 0 },
  vel = { 0, 0 },
  added = function(self)
    self.gun = Entity.spawn("Gun", { bird=self })
    self.fill = Entity.spawn("BirdFill", { bird=self, color="red" })
  end,
  update = function(self)
    -- movement
    local vx, vy, v = 0, 0, 140
    if Input.pressed("left") then vx = vx - v end
    if Input.pressed("right") then vx = vx + v end 
    if Input.pressed("up") then vy = vy - v end 
    if Input.pressed("down") then vy = vy + v end 
    self.vel = { vx, vy }
    -- face towards mouse
    local angle = Math.deg(Math.angle(self.pos[1], self.pos[2], mouse_x, mouse_y)) + 180
    local quadrant = Math.ceil(angle / 90) -- 1:topleft, 2:topright, 3:bottomright, 4:bottomleft
    self.facing_up = quadrant == 1 or quadrant == 2
    self.facing_left = quadrant == 1 or quadrant == 4
    
    self.scalex = self.facing_left and -1 or 1 
    if Input.pressed("left", "right", "up", "down") then 
      self.image.name = self.facing_up and "bird_walk_back" or "bird_walk_front"
    else 
      self.image.name = self.facing_up and "bird_stand_back" or "bird_stand_front"
    end
    self.quadrant = quadrant
    self.z = self.pos[2]
    
    -- synchronize fill
    self.fill.pos = self.pos
    self.fill.scalex = self.scalex
    self.fill.image.name = self.image.name.."_fill"
    self.fill.z = self.z - 1
  end
}

Entity{
  "BirdFill",
  image = "bird_stand_back_fill",
  pos = { 0, 0 },
  color = 'red',
  align = "center"
}