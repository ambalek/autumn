-- luacheck: globals screen util clock params softcut engine include ui_state
local LFO_SINE = 1
local LFO_SQUARE = 2
local LFO_SH = 3
local LFO_MAX = 3
local LFO_RESOLUTION = 100
local LFO_TIMER_INTERVAL = (math.pi * 2) / LFO_RESOLUTION
local LFO_RATE_MAX = 100
local LFO_TOTAL_TIME = 2 * math.pi
local LFO_BITS_BASE = 8
local LFO_BITS_MAX = 24

local LFO = {
  lfos = {},
  last_attack_value = 0,
  last_release_value = 0,
  LFO_MAX = LFO_MAX,
}

LFO.__index = LFO

LFO.SHAPES = {
 "Sine",
 "Square",
 "S+H"
}

LFO.TARGETS = { "d1_lvl", "d2_lvl", "d1_fbk", "d2_fbk", "pw", "attack", "release", "bits", "pan" }

LFO.LFO_RATE_MAX = LFO_RATE_MAX

local LFO_TARGET_DELAY_1_LEVEL = 1
local LFO_TARGET_DELAY_2_LEVEL = 2
local LFO_TARGET_DELAY_1_FEEDBACK = 3
local LFO_TARGET_DELAY_2_FEEDBACK = 4
local LFO_TARGET_PW = 5
local LFO_TARGET_ATTACK = 6
local LFO_TARGET_RELEASE = 7
local LFO_TARGET_BITS = 8
local LFO_TARGET_PAN = 9

function LFO.new(params_id)
  local lfo = {}
  setmetatable(lfo, LFO)
  lfo.params_id = params_id
  lfo.time = 0
  lfo.current_value = {
    time = 0,
    value = 0
  }
  lfo.timer_countdown = 0
  return lfo
end

function LFO.init()
  params:add_separator("lfo")
  for i = 1, LFO_MAX do
    params:add_option(
      "lfo_" .. i .. "_target",
      "lfo " .. i .. " target",
      LFO.TARGETS,
      LFO_TARGET_PW
    )
    params:set_action("lfo_" .. i .. "_target", function(value)
      ui_state["lfo" .. i].target = LFO.TARGETS[value]
    end)
    ui_state["lfo" .. i].target = LFO.TARGETS[params:get("lfo_" .. i .. "_target")]
    params:add_number("lfo_" .. i .. "_rate", "lfo " .. i .. " rate", 1, LFO_RATE_MAX, 90)
    params:add_option("lfo_" .. i .. "_shape", "lfo " .. i .. " shape", LFO.SHAPES, LFO_SINE)
    params:add_taper("lfo_" .. i .. "_min", "lfo " .. i .. " min", 0, 1, 0.4, 0.01)
    params:add_taper("lfo_" .. i .. "_max", "lfo " .. i .. " max", 0, 1, 0.6, 0.01)
    local active = 1
    if i == 1 then
      active = 2
    end
    params:add_option("lfo_" .. i .. "_is_active", "lfo " .. i .. " is_active", { "No", "Yes" }, active)

    local lfo = LFO.new(i)

    params:set_action("lfo_" .. i .. "_rate", function()
      lfo:generate_preview()
    end)

    params:set_action("lfo_" .. i .. "_shape", function()
      lfo:generate_preview()
    end)

    params:set_action("lfo_" .. i .. "_min", function()
      lfo:generate_preview()
    end)

    params:set_action("lfo_" .. i .. "_max", function()
      lfo:generate_preview()
    end)

    lfo:generate_preview()
    table.insert(LFO.lfos, lfo)
    lfo:start()
  end
end

function LFO.start_all()
  for i = 1, LFO_MAX do
    local lfo = LFO.lfos[i]
    lfo:start()
  end
end

function LFO:target()
  return params:get("lfo_" .. self.params_id .. "_target")
end

function LFO:rate()
  return params:get("lfo_" .. self.params_id .. "_rate")
end

function LFO:shape()
  return params:get("lfo_" .. self.params_id .. "_shape")
end

function LFO:min()
  return params:get("lfo_" .. self.params_id .. "_min")
end

function LFO:max()
  return params:get("lfo_" .. self.params_id .. "_max")
end

function LFO:is_active()
  return params:get("lfo_" .. self.params_id .. "_is_active") == 2
end

function LFO:set_is_active(is_active)
  local is_active_index = 1
  if is_active then
    is_active_index = 2
  end
  params:set("lfo_" .. self.params_id .. "_is_active", is_active_index)
end

function LFO:toggle()
  self:set_is_active(not self:is_active())
  if self:is_active() then
    self:start()
  else
    self:stop()
  end
end

function LFO:update()
  self.time = self.time + 1
  if self.time > #self.data then
    self.time = 1
  end
  if self.data[self.time] then
    self.current_value = self.data[self.time]
  end
end

function LFO:generate_sine()
  local range = (self:max() - self:min())
  local time = 0
  while true do
    time = time + LFO_TIMER_INTERVAL
    if time > LFO_TOTAL_TIME then
      return
    end
    local value = math.sin(time)
    table.insert(self.data, { time = time, value = value * range })
  end
end

function LFO:generate_square()
  local time = 0
  local range = (self:max() - self:min())
  local p = math.pi * 2
  local value
  while true do
    time = time + LFO_TIMER_INTERVAL
    if time > LFO_TOTAL_TIME then
      return
    end
    if time % p < p / 2 then
      value = 1
    else
      value = -1
    end
    table.insert(self.data, { time = time, value = value * range })
  end
end

function LFO:generate_sh()
  local time = 0
  local range = (self:max() - self:min())
  local p = 20
  local value = math.random()
  while true do
    time = time + LFO_TIMER_INTERVAL
    if time > LFO_TOTAL_TIME then
      return
    end
    if math.floor(time * 100) % math.floor(p) == 0 then
      value = math.random()
    end
    table.insert(self.data, { time = time, value = value * range })
  end
end

function LFO:generate_preview()
  self.data = {}
  if self:shape() == LFO_SINE then
    self:generate_sine()
  elseif self:shape() == LFO_SQUARE then
    self:generate_square()
  elseif self:shape() == LFO_SH then
    self:generate_sh()
  end
end

local function scale_range(value, new_min, new_max)
  local min = -1
  local max = 1
  return math.floor((
    (
      (value - min)
      * (new_max - new_min)
      / (max - min)
    )
    + new_min
  ) + 0.5)
end

function LFO:apply_action()
  local target = self:target()
  local value = self.current_value.value
  -- value range = -1 to 1
  if target == LFO_TARGET_DELAY_1_LEVEL then
    local d1_lvl = util.clamp(params:get("short_delay_level") + value, 0, 1)
    softcut.level(1, d1_lvl)
    ui_state["lfo" .. self.params_id].d1_lvl = d1_lvl
  elseif target == LFO_TARGET_DELAY_2_LEVEL then
    local d2_lvl = util.clamp(value + params:get("long_delay_level"), 0, 1)
    softcut.level(2, d2_lvl)
    ui_state["lfo" .. self.params_id].d2_lvl = d2_lvl
  elseif target == LFO_TARGET_DELAY_1_FEEDBACK then
    local d1_fbk = util.clamp(value + params:get("short_delay_feedback"), 0, 1)
    softcut.level(2, d1_fbk)
    ui_state["lfo" .. self.params_id].d1_fbk = d1_fbk
  elseif target == LFO_TARGET_DELAY_2_FEEDBACK then
    local d2_fbk = util.clamp(value + params:get("long_delay_feedback"), 0, 1)
    softcut.level(2, d2_fbk)
    ui_state["lfo" .. self.params_id].d2_fbk = d2_fbk
  elseif target == LFO_TARGET_PW then
    -- Pivot around the params pw value because value will be negative (-1 to 1)
    local pw = util.clamp(((value) / 2) + params:get("pw"), 0, 1)
    ui_state["lfo" .. self.params_id].pw = pw
    -- TODO: Why can engine.pw be nil during init?
    if engine.pw ~= nil then
      engine.pw(pw)
    end
  elseif target == LFO_TARGET_ATTACK then
    local attack = (value / 2) + 1
    LFO.last_attack_value = attack
    ui_state["lfo" .. self.params_id].attack = attack
  elseif target == LFO_TARGET_RELEASE then
    local release = (value / 2) + 1
    LFO.last_release_value = release
    ui_state["lfo" .. self.params_id].release = release
  elseif target == LFO_TARGET_BITS then
    local bits = scale_range(value + params:get("bits"), LFO_BITS_BASE, LFO_BITS_MAX)
    ui_state["lfo" .. self.params_id].bits = bits
    if engine.bits ~= nil then
      engine.bits(bits)
    end
  elseif target == LFO_TARGET_PAN then
    local pan = util.clamp(value + params:get("pan"), -1, 1)
    ui_state["lfo" .. self.params_id].pan = pan
    if engine.pan ~= nil then
      engine.pan(pan)
    end
  end
end

function LFO:start()
  self.clock = clock.run(function()
    while true do
      if self.timer_countdown == 0 then
        self.timer_countdown = LFO_RATE_MAX - self:rate() + 1
        if self:is_active() then
          self:update()
          self:apply_action()
        end
      end
      self.timer_countdown = self.timer_countdown - 1
      clock.sync(1 / 128)
    end
  end)
end

function LFO:stop()
  clock.cancel(self.clock)
end

function LFO:render()
  local x_offset = 0
  local y_offset = 25
  local y_scale = 10
  local x_scale = 7
  screen.line_width(2)
  for x = 1, #self.data do
    screen.pixel((self.data[x].time * x_scale) + x_offset, (self.data[x].value * y_scale) + y_offset)
    screen.level(2)
    screen.fill()
  end
  screen.pixel((self.current_value.time * x_scale) + x_offset, (self.current_value.value * y_scale) + y_offset)
  screen.level(10)
  screen.fill()
  screen.stroke()
  -- Draw the shift key, because LFOs have shift functions
  screen.level(2)
  screen.circle(5, 13, 3)
  screen.fill()
  screen.close()
  screen.level(10)
end

return LFO