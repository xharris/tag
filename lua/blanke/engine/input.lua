--INPUT
Input = nil
mouse_x, mouse_y = 0, 0
do
  local name_to_input = {} -- name -> { key1: t/f, mouse1: t/f }
  local input_to_name = {} -- key -> { name1, name2, ... }
  local options = {
    no_repeat = {},
    combo = {}
  }
  local groups = {}
  local pressed = {}
  local released = {}
  local store = {}
  local key_assoc = {
    lalt = "alt",
    ralt = "alt",
    ["return"] = "enter",
    kpenter = "enter",
    lgui = "gui",
    rgui = "gui"
  }

  local joycheck = function(info)
    if not info or not info.joystick then
      return info
    end
    if Joystick.using == 0 then
      return info
    end
    if Joystick.get(Joystick.using):getID() == info.joystick:getID() then
      return info
    end
  end

  local isPressed = function(name)
    if Input.group then
      name = Input.group .. "." .. name
    end
    if
      not (table.hasValue(options.no_repeat, name) and pressed[name] and pressed[name].count > 1) and
        joycheck(pressed[name])
     then
      return pressed[name]
    end
  end

  local isReleased = function(name)
    if Input.group then
      name = Input.group .. "." .. name
    end
    if joycheck(released[name]) then
      return released[name]
    end
  end

  Input =
    callable {
    __call = function(self, name)
      return store[name] or pressed[name] or released[name]
    end,
    group = nil,
    store = function(name, value)
      store[name] = value
    end,
    set = function(inputs, _options)
      _options = _options or {}
      for name, inputs in pairs(inputs) do
        Input.setInput(name, inputs, _options.group)
      end

      if _options.combo then
        table.append(options.combo, _options.combo or {})
      end
      if _options.no_repeat then
        table.append(options.no_repeat, _options.no_repeat or {})
      end

      return nil
    end,
    setInput = function(name, inputs, group)
      if group then
        name = group .. "." .. name
      end
      local input_group_str = name
      name_to_input[name] = {}
      for _, i in ipairs(inputs) do
        name_to_input[name][i] = false
      end
      for _, i in ipairs(inputs) do
        if not input_to_name[i] then
          input_to_name[i] = {}
        end
        if not table.hasValue(input_to_name[i], name) then
          table.insert(input_to_name[i], name)
        end
      end
    end,
    pressed = function(...)
      local ret = {}
      local args = {...}
      local val
      for _, name in ipairs(args) do
        val = isPressed(name)
        if val then
          table.insert(ret, val)
        end
      end
      if #ret > 0 then
        return ret
      end
    end,
    released = function(...)
      local ret = {}
      local args = {...}
      local val
      for _, name in ipairs(args) do
        val = isReleased(name)
        if val then
          table.insert(ret, val)
        end
      end
      if #ret > 0 then
        return ret
      end
    end,
    press = function(key, extra)
      if key_assoc[key] then
        Input.press(key_assoc[key], extra)
      end
      if input_to_name[key] then
        for _, name in ipairs(input_to_name[key]) do
          local n2i = name_to_input[name]
          if not n2i then
            name_to_input[name] = {}
          end
          n2i = name_to_input[name]
          n2i[key] = true
          -- is input pressed now?
          combo = table.hasValue(options.combo, name)
          if (combo and table.every(n2i)) or (not combo and table.some(n2i)) then
            pressed[name] = extra
            pressed[name].count = 1
          end
        end
      end
    end,
    release = function(key, extra)
      if key_assoc[key] then
        Input.release(key_assoc[key], extra)
      end
      if input_to_name[key] then
        for _, name in ipairs(input_to_name[key]) do
          local n2i = name_to_input[name]
          if not n2i then
            name_to_input[name] = {}
          end
          n2i = name_to_input[name]
          n2i[key] = false
          -- is input released now?
          combo = table.hasValue(options.combo, name)
          if pressed[name] and (combo or not table.some(n2i)) then
            pressed[name] = nil
            released[name] = extra
          end
        end
      end
    end,
    keyCheck = function()
      for name, info in pairs(pressed) do
        info.count = info.count + 1
      end
      released = {}
      store["wheel"] = nil
    end

    -- mousePos = function() return love.mouse.getPosition() end;
  }
end