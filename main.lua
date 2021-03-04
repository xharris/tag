local anim_bird_stand = function(suffix, frames) return { name="bird_stand_"..suffix, rows=2, cols=1, frames=frames } end 
local anim_bird_walk = function(suffix, frames) return { name="bird_walk_"..suffix, rows=2, cols=4, frames=frames, speed=10} end

Image.animation("bird_stand_front.png", { anim_bird_stand("front", {1}), anim_bird_stand("front_fill", {2}) })
Image.animation("bird_stand_back.png", { anim_bird_stand("back", {1}), anim_bird_stand("back_fill", {2}) })
Image.animation("bird_walk_front.png", { anim_bird_walk("front", {'1-4'}), anim_bird_walk("front_fill", {'5-8'}) })
Image.animation("bird_walk_back.png", { anim_bird_walk("back", {'1-4'}), anim_bird_walk("back_fill", {'5-8'}) })

Input.set({
  left = { "left", "a" },
  right = { "right", "d" },
  up = { "up", "w" },
  down = { "down", "s" },
  primary = { 'mouse1' },
})

Game{
  background_color = "white",
  load = function()
    Entity.spawn("Bird", { pos = { x, y } })
  end
}
