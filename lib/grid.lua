-- luacheck: globals grid engine params util clock softcut include Hid
local MusicUtil = require "musicutil"
local delays = include("lib/delays")
local scale_name = "Chromatic"
local root_note_number = 24
local octaves = 6
local scale_length = #MusicUtil.generate_scale(root_note_number, scale_name, 1) - 1
local scale = MusicUtil.generate_scale(root_note_number, scale_name, octaves)
local scale_lookup = {}
local SHORT_DELAY_GRID_X = 2
local LONG_DELAY_GRID_X = 3
local SHORT_DELAY_REC_GRID_X = 2
local LONG_DELAY_REC_GRID_X = 3
local clock1 = nil
local clock2 = nil
local grid_velocity = 0

local function has_grid()
  local g = grid.connect()
  if g.device == nil then
    return false
  end
  return true
end

local function show_velocity()
  print("show_velocity")
  if not has_grid() then return end
  local g = grid.connect()
  print("Showing velocity")
  for y = 1, g.device.rows do
    local grid_col = 0
    if y >= grid_velocity then
      grid_col = 5
    end
    print("g led: " .. y .. " grid_col: " .. grid_col)
    g:led(1, y, grid_col)
  end
end

local function init_grid()
  if not has_grid() then return end
  local g = grid.connect()
  local SHORT_DELAY_GRID_Y = g.device.rows
  local LONG_DELAY_GRID_Y = g.device.rows
  local SHORT_DELAY_REC_GRID_Y = g.device.rows - 1
  local LONG_DELAY_REC_GRID_Y = g.device.rows - 1
  local grid_notes_start_x = 5
  local grid_notes_start_y = 2
  local nn = 1

  grid_velocity = math.ceil(g.device.rows / 2)

  g:all(0)

  -- TODO: I know this won't work with smaller grids
  for y = grid_notes_start_y, grid_notes_start_y + octaves - 1 do
    scale_lookup[y] = {}
    for x = grid_notes_start_x, grid_notes_start_x + scale_length - 1 do
      if scale[nn] ~= nil then
        local grid_col = 2
        if nn % scale_length == 1 then -- C
          grid_col = 15
        elseif x - grid_notes_start_x == 2 then -- D
          grid_col = 6
        elseif x - grid_notes_start_x == 4 then -- E
          grid_col = 6
        elseif x - grid_notes_start_x == 5 then -- F
          grid_col = 6
        elseif x - grid_notes_start_x == 7 then -- G
          grid_col = 9
        elseif x - grid_notes_start_x == 9 then -- A
          grid_col = 6
        elseif x - grid_notes_start_x == 11 then -- B
          grid_col = 6
        end
        g:led(x, y, grid_col)
        scale_lookup[y][x] = {
          note = scale[nn],
          col = grid_col
        }
      end
      nn = nn + 1
    end
  end

  g:refresh()
  show_velocity()
  g:refresh()

  function g.key(x, y, z)
    print("key pressed, z:" .. z .. " x: " .. x .. " y: " .. y)
    if z == 1 and scale_lookup[y] ~= nil and scale_lookup[y][x] ~= nil then
      local note = scale_lookup[y][x].note
      local velocity = (g.device.rows - grid_velocity + 1) / g.device.rows
      engine.amp(util.clamp(velocity * params:get("gain"), 0.0, 1.0))
      engine.hz(MusicUtil.note_num_to_freq(note))
      -- TODO: Add UI
      print("Playing note: " .. note .. " / " .. MusicUtil.note_num_to_name(note))
    end
    -- set velocity
    if z == 1 and x == 1 then
      grid_velocity = y
      show_velocity()
    end
    -- clear delays
    if z == 1 and x == SHORT_DELAY_GRID_X and y == SHORT_DELAY_GRID_Y then
      delays.clear(1)
    end
    if z == 1 and x == LONG_DELAY_GRID_X and y == LONG_DELAY_GRID_Y then
      delays.clear(2)
    end
    -- toggle delay recording
    if z == 1 and x == SHORT_DELAY_REC_GRID_X and y == SHORT_DELAY_REC_GRID_Y then
      delays.toggle_rec(1)
    end
    if z == 1 and x == LONG_DELAY_REC_GRID_X and y == LONG_DELAY_REC_GRID_Y then
      delays.toggle_rec(2)
    end
    g:refresh()
  end
end

-- Delay rate pulse for the delay clear button
local function init()
  if not has_grid() then return end
  local g = grid.connect()
  local SHORT_DELAY_REC_GRID_Y = g.device.rows - 1
  local LONG_DELAY_REC_GRID_Y = g.device.rows - 1
  local SHORT_DELAY_GRID_Y = g.device.rows
  local LONG_DELAY_GRID_Y = g.device.rows

  init_grid()

  if clock1 ~= nil then
    clock.cancel(clock1)
  end

  if clock2 ~= nil then
    clock.cancel(clock2)
  end

  -- Delay 1
  clock1 = clock.run(
    function()
      local brightness = 0
      local inc = 1
      local steps = 10
      while true do
        clock.sleep(((params:get("short_delay_time") / steps)) / 2)
        brightness = brightness + inc
        if brightness == steps then
          inc = -1
        elseif brightness == 0 then
          inc = 1
        end
        if delays.is_recording(1) then
          g:led(SHORT_DELAY_REC_GRID_X, SHORT_DELAY_REC_GRID_Y, math.floor(brightness / 2))
        end
        g:led(SHORT_DELAY_GRID_X, SHORT_DELAY_GRID_Y, brightness)
        g:refresh()
      end
    end
  )
  -- Delay 2
  clock2 = clock.run(
    function()
      local brightness = 0
      local inc = 1
      local steps = 10
      while true do
        clock.sleep(((params:get("long_delay_time") / steps)) / 2)
        brightness = brightness + inc
        if brightness == steps then
          inc = -1
        elseif brightness == 0 then
          inc = 1
        end
        if delays.is_recording(2) then
          g:led(LONG_DELAY_REC_GRID_X, LONG_DELAY_REC_GRID_Y, math.floor(brightness / 2))
        end
        g:led(LONG_DELAY_GRID_X, LONG_DELAY_GRID_Y, brightness)
        g:refresh()
      end
    end
  )
end

function grid.add()
  init()
end

return {
  init = init
}