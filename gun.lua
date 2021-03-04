Entity{
  "Gun",
  image = "gun.png",
  align = "left center",
  pos = { 0, 0 },
  update = function(self)
    if self.bird then 
      self.scalex = self.bird.scalex
      self.pos = {
        self.bird.pos[1] + (6 * self.scalex),
        self.bird.pos[2] + 5
      }
      self.z = self.bird.z + 20 * (self.bird.facing_up and 1 or -1)
      self.angle = Math.angle(self.pos[1], self.pos[2], mouse_x, mouse_y) + (self.bird.facing_left and 135 or 0)
    end 
  end
}