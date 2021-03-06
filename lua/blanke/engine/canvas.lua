CanvasStack = Stack(function() return Canvas() end)

Component("Canvas", { auto_clear=true })
local setup_canvas = function(ent)
  local canv = ent
  if ent.Canvas then canv = ent.Canvas end 
  if canv.auto_clear == nil then
    canv.auto_clear = true 
  end 
  canv.drawable = love.graphics.newCanvas(canv.w or Game.width, canv.h or Game.height)
  if canv.filter then 
    canv.drawable:setFilter(unpack(canv.filter))
  end
  canv.renderTo = function(self, fn)
    if fn then
      local lg = love.graphics
      self.active = true
      lg.push("all")
      lg.setCanvas {self.drawable}
      if self.auto_clear then
        lg.clear(self.auto_clear)
      end
      fn()
      lg.pop()
      self.active = false
    end
  end
  return canv
end

Canvas = function(obj) return setup_canvas(obj or {}) end
System(All("Canvas"), {
  added = function(ent)
    setup_canvas(ent)
    ent.addChild(ent.Canvas)
  end
})