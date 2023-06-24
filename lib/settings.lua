-- luacheck: globals params engine softcut include
local settings = {
  max_loop_length = 50
}

local function setup_params()
  params:add_separator("sound")
  params:add_taper("pw", "pulse width", 0, 1, 0.6, 0.01)
  params:set_action("pw", function(value)
    engine.pw(value)
  end)
  params:add_number("bits", "bits", 6, 32, 13)
  params:set_action("bits", function(value)
    engine.bits(value)
  end)

  params:add_separator("envelope")
  params:add_taper("attack", "attack", 0, 10, 0.0, 0.0001, "seconds")
  params:set_action("attack", function(value)
    engine.attack(value)
  end)
  params:add_taper("release", "release", 0, 10, 0.75, 0.0001, "seconds")
  params:set_action("release", function(value)
    engine.release(value)
  end)

  params:add_separator("filter")
  params:add_taper("cutoff", "cutoff", 30, 20000, 1000)
  params:set_action("cutoff", function(value)
    engine.cutoff(value)
  end)

  params:add_separator("amp")
  params:add_taper("gain", "gain", 0.0, 1.0, 0.5, 0.0001)
  params:set_action("gain", function(value)
    engine.amp(value)
  end)
  params:add_taper("pan", "pan", -1.0, 1.0, 0.0, 0.0001)
  params:set_action("pan", function(value)
    engine.pan(value)
  end)

  params:add_separator("time and delays")
  params:add_taper("short_delay_time", "short delay", 0.1, 10.0, 1, 0.01, "sec")
  params:set_action("short_delay_time", function(value) softcut.loop_end(1, value) end)
  params:add_taper("short_delay_level", "short delay gain", 0, 1, 0.4, 0.01, "")
  params:set_action("short_delay_level", function(value) softcut.level(1, value) end)
  params:add_taper("short_delay_feedback", "short delay feedback", 0, 1, 0.5, 0.01)
  params:set_action("short_delay_feedback", function(value)
    softcut.pre_level(1, value)
  end)
  params:add_taper("long_delay_time", "long delay", 1, settings.max_loop_length, 10, 0.1, "sec")
  params:set_action("long_delay_time", function(value) softcut.loop_end(2, value) end)
  params:add_taper("long_delay_level", "long delay gain", 0, 1, 0.6, 0.01, "")
  params:set_action("long_delay_level", function(value) softcut.level(2, value) end)
  params:add_taper("long_delay_feedback", "long delay feedback", 0, 1, 0.5, 0.01)
  params:set_action("long_delay_feedback", function(value)
    softcut.pre_level(1, value)
  end)
end

settings.setup_params = setup_params

return settings