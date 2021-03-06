--DRAW
Draw = nil
do
  local clamp = Math.clamp
  local hex2rgb = function(hex)
    assert(type(hex) == "string", "hex2rgb: expected string, got " .. type(hex) .. " (" .. hex .. ")")
    hex = hex:gsub("#", "")
    if (string.len(hex) == 3) then
      return {
        tonumber("0x" .. hex:sub(1, 1)) * 17 / 255,
        tonumber("0x" .. hex:sub(2, 2)) * 17 / 255,
        tonumber("0x" .. hex:sub(3, 3)) * 17 / 255
      }
    elseif (string.len(hex) == 6) then
      return {
        tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255
      }
    end
  end

  local fonts = {} -- { 'path+size': [ Font, Text ] }

  local getFont = function(path, size)
    size = size or 12
    local key = path .. "+" .. size
    if fonts[key] then
      return fonts[key]
    end

    local fnt = love.graphics.newFont(Game.res("font", path), size)
    local txt = love.graphics.newText(fnt)

    assert(fnt, "Font not found: '" .. path .. "'")

    local font = {fnt, txt}
    fonts[key] = font
    return font
  end

  local setText = function(text, limit, align)
    if not Draw.text then
      return false
    end
    if not text then
      text = "|"
    end
    if limit or align then
      Draw.text:setf(text or "", limit or Game.width, align or "left")
    else
      Draw.text:set(text or "")
    end
    return true
  end

  local DEF_FONT = "04B_03.ttf"
  local last_font

  Draw =
    callable {
    crop_used = false,
    font = nil,
    text = nil,
    __call = function(self, instructions)
      for _, instr in ipairs(instructions) do
        name, args = instr[1], table.slice(instr, 2)
        assert(Draw[name], "bad draw instruction '" .. name .. "'")
        local good, err = pcall(Draw[name], unpack(args))
        if not good then
          error("Error: Draw." .. name .. "(" .. tbl_to_str(args) .. ")\n" .. err, 3)
        end
      end
    end,
    setFont = function(path, size)
      path = path or last_font or DEF_FONT
      last_font = path
      local info = getFont(path, size)

      Draw.font = info[1]
      Draw.text = info[2]

      love.graphics.setFont(Draw.font)
    end,
    setFontSize = function(size)
      Draw.setFont(last_font, size)
    end,
    textWidth = function(...)
      if setText(...) then
        return Draw.text:getWidth()
      end
    end,
    textHeight = function(...)
      if setText(...) then
        return Draw.text:getHeight()
      end
    end,
    textSize = function(...)
      if setText(...) then
        return Draw.text:getDimensions()
      end
    end,
    addImageFont = function(path, glyphs, ...)
      path = Game.res("image", path)
      if fonts[path] then
        return fonts[path]
      end
      local font = love.graphics.newImageFont(path, glphs, ...)
      fonts[path] = font
      return font
    end,
    setImageFont = function(path)
      path = Game.res("image", path)
      local font = fonts[path]
      assert(font, "ImageFont not found: '" .. path .. "'")
      love.graphics.setFont(font)
    end,
    print = function(txt, x, y, limit, align, r, ...)
      if setText(txt, limit, align) then
        x = x or 0
        y = y or 0
        love.graphics.draw(Draw.text, x, y, r or 0, ...)
      end
    end,
    parseColor = memoize(
      function(...)
        local r, g, b, a = ...
        if r == nil or r == true then
          -- no color given
          r, g, b, a = 1, 1, 1, 1
          return r, g, b, a
        end
        if type(r) == "table" then
          r, g, b, a = r[1], r[2], r[3], r[4]
        end
        local c = Color[r]
        if c then
          -- color string
          r, g, b, a = c[1], c[2], c[3], g
        elseif type(r) == "string" and r:starts("#") then
          -- hex string
          r, g, b = unpack(hex2rgb(r))
        end

        if not a then
          a = 1
        end
        -- convert and clamp to [0,1]
        if r > 1 then
          r = clamp(floor(r) / 255, 0, 1)
        end
        if g > 1 then
          g = clamp(floor(g) / 255, 0, 1)
        end
        if b > 1 then
          b = clamp(floor(b) / 255, 0, 1)
        end
        if a > 1 then
          a = clamp(floor(a) / 255, 0, 1)
        end

        return r, g, b, a
      end
    ),
    color = function(...)
      return love.graphics.setColor(Draw.parseColor(...))
    end,
    getBlendMode = function()
      return love.graphics.getBlendMode()
    end,
    setBlendMode = function(...)
      love.graphics.setBlendMode(...)
    end,
    crop = function(x, y, w, h)
      love.graphics.setScissor(x, y, w, h)
      -- stencilFn = () -> Draw.rect('fill',x,y,w,h)
      -- love.graphics.stencil(stencilFn,"replace",1)
      -- love.graphics.setStencilTest("greater",0)
      -- Draw.crop_used = true
    end,
    rotate = function(r)
      love.graphics.rotate(r)
    end,
    translate = function(x, y)
      love.graphics.translate(floor(x), floor(y))
    end,
    reset = function(only)
      local lg = love.graphics
      if only == "color" or not only then
        lg.setColor(1, 1, 1, 1)
        lg.setLineWidth(1)
      end
      if only == "transform" or not only then
        lg.origin()
      end
      if (only == "crop" or not only) and Draw.crop_used then
        Draw.crop_used = false
        lg.setScissor()
      -- lg.setStencilTest()
      end
    end,
    push = function()
      love.graphics.push("all")
    end,
    pop = function()
      Draw.reset("crop")
      love.graphics.pop()
    end,
    stack = function(fn)
      local lg = love.graphics
      lg.push("all")
      fn()
      lg.pop()
    end,
    newTransform = function()
      return love.math.newTransform()
    end,
    clear = function(...)
      love.graphics.clear(Draw.parseColor(...))
    end
  }

  local draw_functions = {
    "arc",
    "circle",
    "ellipse",
    "line",
    "points",
    "polygon",
    "rectangle",
     --'print','printf',
    "discard",
    "origin",
    "scale",
    "shear",
    "transformPoint",
    "setLineWidth",
    "setLineJoin",
    "setPointSize",
    "applyTransform",
    "replaceTransform"
  }
  local draw_aliases = {
    polygon = "poly",
    rectangle = "rect",
    setLineWidth = "lineWidth",
    setLineJoin = "lineJoin",
    setPointSize = "pointSize",
    points = "point",
    setFont = "font",
    setFontSize = "fontSize"
  }
  for _, fn in ipairs(draw_functions) do
    Draw[fn] = function(...)
      return love.graphics[fn](...)
    end
  end
  for old, new in pairs(draw_aliases) do
    Draw[new] = Draw[old]
  end
end
--COLOR
Color = {
  red = {244, 67, 54},
  pink = {240, 98, 146},
  purple = {156, 39, 176},
  deeppurple = {103, 58, 183},
  indigo = {63, 81, 181},
  blue = {33, 150, 243},
  lightblue = {3, 169, 244},
  cyan = {0, 188, 212},
  teal = {0, 150, 136},
  green = {76, 175, 80},
  lightgreen = {139, 195, 74},
  lime = {205, 220, 57},
  yellow = {255, 235, 59},
  amber = {255, 193, 7},
  orange = {255, 152, 0},
  deeporange = {255, 87, 34},
  brown = {121, 85, 72},
  grey = {158, 158, 158},
  gray = {158, 158, 158},
  bluegray = {96, 125, 139},
  white = {255, 255, 255},
  white2 = {250, 250, 250},
  black = {0, 0, 0},
  black2 = {33, 33, 33},
  transparent = {255, 255, 255, 0}
}