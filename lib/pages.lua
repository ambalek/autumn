-- luacheck: globals params include screen ui_state
local UI = require "ui"
local delays = include("lib/delays")
local settings = include("lib/settings")
local LFO = include("lib/lfo")

local dial_args = {
  size = 15,
  e1 = {
    x = 15,
    y = 6,
  },
  e2 = {
    x = 69,
    y = 24,
  },
  e3 = {
    x = 105,
    y = 24,
  }
}

local function placeholder_dial(e)
  return UI.Dial.new(e.x, e.y, dial_args.size, 0, 0, 1, 0.0001, 0, {}, '', '')
end

local function set_lfo_dial_value(dial, target)
  local value = 0
  local active = false
  for i = 1, LFO.LFO_MAX do
    if params:get("lfo_" .. i .. "_is_active") == 2 and ui_state["lfo" .. i].target == target then
      value = value + ui_state["lfo" .. i][target]
      active = true
    end
  end
  if active then
    dial:set_value(value)
  end
end

local function make_lfo_page(id)
  return {
    title = "LFO " .. id,
    lfo_id = id,
      key2_text = function()
        local param_id = "lfo_" .. id .. "_is_active"
        local active = params:get(param_id)
        if active == 1 then
          return "start"
        else
          return "stop"
        end
      end,
      key2_callback = function()
        local param_id = "lfo_" .. id .. "_is_active"
        local active = params:get(param_id)
        if active == 1 then
          params:set(param_id, 2)
        else
          params:set(param_id, 1)
        end
      end,
    dials = {
      nil,
      UI.Dial.new(
        dial_args.e2.x,
        dial_args.e2.y,
        dial_args.size,
        params:get("lfo_" .. id .. "_rate"),
        0,
        100,
        1,
        0,
        {},
        '',
        'rate'
      ),
      nil
    },
    render = function(lfo)
      lfo:render()
      screen.move(14, 55)
      screen.text(LFO.TARGETS[params:get("lfo_" .. id .. "_target")])
      screen.move(51, 25)
      if ui_state.k1_held then
        screen.text("")
      else
        screen.text("E1: Target")
      end
      screen.move(51, 40)
      if ui_state.k1_held then
        screen.text("E2: Min  E3: Max")
      else
        screen.text("E2: Rate E3: Shape")
      end
    end,
    dial_callbacks = {
      function(d)
        -- shift: None
        if ui_state.k1_held then
          return nil
        else
          -- unshift: Target
          params:delta("lfo_" .. id .. "_target", d)
          return params:get("lfo_" .. id .. "_target")
        end
      end,
      function(d)
        -- shift: Min
        if ui_state.k1_held then
          params:delta("lfo_" .. id .. "_min", d)
          return params:get("lfo_" .. id .. "_min")
        else
          -- unshift: Rate
          params:delta("lfo_" .. id .. "_rate", d)
          return params:get("lfo_" .. id .. "_rate")
        end
      end,
      function(d)
        -- shift: Max
        if ui_state.k1_held then
          params:delta("lfo_" .. id .. "_max", d)
          return params:get("lfo_" .. id .. "_max")
        else
          -- unshift: Shape
          params:delta("lfo_" .. id .. "_shape", d)
          return params:get("lfo_" .. id .. "_shape")
        end
      end
    }
  }
end

local function make_pages()
  return {
    {
      title = "sound",
      dials = {
        placeholder_dial(dial_args.e1),
        UI.Dial.new(
          dial_args.e2.x,
          dial_args.e2.y,
          dial_args.size,
          params:get("pw"),
          0,
          1,
          0.0001,
          0,
          {},
          "",
          "pw"
        ),
        UI.Dial.new(
          dial_args.e3.x,
          dial_args.e3.y,
          dial_args.size,
          params:get("bits"),
          6,
          32,
          1,
          0,
          {},
          "",
          "bits"
        ),
      },
      dial_callbacks = {
        nil,
        function(d)
          params:delta("pw", d)
          return params:get("pw")
        end,
        function(d)
          params:delta("bits", d)
          return params:get("bits")
        end,
      },
      update_dials = function(dials)
        set_lfo_dial_value(dials[2], "pw")
        set_lfo_dial_value(dials[3], "bits")
      end,
    },
    {
      title = "filter",
      dials = {
        placeholder_dial(dial_args.e1),
        UI.Dial.new(
          dial_args.e2.x,
          dial_args.e2.y,
          dial_args.size,
          params:get("cutoff"),
          30,
          20000,
          1,
          0,
          {},
          "",
          "Cutoff"
        ),
        placeholder_dial(dial_args.e3)
      },
      dial_callbacks = {
        nil,
        function(d)
          params:delta("cutoff", d)
          return params:get("cutoff")
        end,
        nil
      }
    },
    {
      title = "envelope",
      dials = {
        placeholder_dial(dial_args.e1),
        UI.Dial.new(
          dial_args.e2.x,
          dial_args.e2.y,
          dial_args.size,
          params:get("attack"),
          0,
          10,
          0.0001,
          0,
          {},
          "",
          "attack"
        ),
        UI.Dial.new(
          dial_args.e3.x,
          dial_args.e3.y,
          dial_args.size,
          params:get("release"),
          0,
          10,
          0.0001,
          0,
          {},
          "",
          "release"
        ),
      },
      dial_callbacks = {
        nil,
        function(d)
          params:delta("attack", d)
          return params:get("attack")
        end,
        function(d)
          params:delta("release", d)
          return params:get("release")
        end
      },
      update_dials = function(dials)
        set_lfo_dial_value(dials[2], "attack")
        set_lfo_dial_value(dials[3], "release")
      end,
    },
    {
      title = "amp",
      dials = {
        placeholder_dial(dial_args.e1),
        UI.Dial.new(
          dial_args.e2.x, dial_args.e2.y,
          dial_args.size,
          params:get("gain"),
          0.0,
          1.0,
          0.0001,
          0,
          {},
          "",
          "gain"
        ),
        UI.Dial.new(
          dial_args.e3.x,
          dial_args.e3.y,
          dial_args.size,
          params:get("pan"),
          -1.0,
          1.0,
          0.0001,
          0,
          {},
          "",
          "pan"
        ),
      },
      dial_callbacks = {
        nil,
        function(d)
          params:delta("gain", d)
          return params:get("gain")
        end,
        function(d)
          params:delta("pan", d)
          return params:get("pan")
        end
      },
      update_dials = function(dials)
        set_lfo_dial_value(dials[3], "pan")
      end,
    },
    {
      title = "short delay",
      key2_text = "reset",
      key2_callback = function()
        delays.clear(1)
      end,
      dials = {
        UI.Dial.new(
          dial_args.e1.x,
          dial_args.e1.y,
          dial_args.size,
          params:get("short_delay_time"),
          0.1,
          10.0,
          0.01,
          0,
          {},
          "",
          "time"
        ),
        UI.Dial.new(
          dial_args.e2.x,
          dial_args.e2.y,
          dial_args.size,
          params:get("short_delay_level"),
          0,
          1,
          0.0001,
          0,
          {},
          "",
          "level"
        ),
        UI.Dial.new(
          dial_args.e3.x,
          dial_args.e3.y,
          dial_args.size,
          params:get("short_delay_feedback"),
          0,
          1,
          0.001,
          0,
          {},
          "",
          "fdbk"
        ),
      },
      dial_callbacks = {
        function(d)
          params:delta("short_delay_time", d)
          return params:get("short_delay_time")
        end,
        function(d)
          params:delta("short_delay_level", d)
          return params:get("short_delay_level")
        end,
        function(d)
          params:delta("short_delay_feedback", d)
          return params:get("short_delay_feedback")
        end
      },
      update_dials = function(dials)
        set_lfo_dial_value(dials[2], "d1_lvl")
        set_lfo_dial_value(dials[3], "d1_fbk")
      end,
    },
    {
      title = "long delay",
      key2_text = "reset",
      key2_callback = function()
        delays.clear(2)
      end,
      dials = {
        UI.Dial.new(
          dial_args.e1.x,
          dial_args.e1.y,
          dial_args.size,
          params:get("long_delay_time"),
          1,
          settings.max_loop_length,
          0.01,
          0,
          {},
          "",
          "time"
        ),
        UI.Dial.new(
          dial_args.e2.x,
          dial_args.e2.y,
          dial_args.size,
          params:get("long_delay_level"),
          0,
          1,
          0.0001,
          0,
          {},
          "",
          "level"
        ),
        UI.Dial.new(
          dial_args.e3.x,
          dial_args.e3.y,
          dial_args.size,
          params:get("long_delay_feedback"),
          0,
          1,
          0.001,
          0,
          {},
          "",
          "fdbk"
        ),
      },
      dial_callbacks = {
        function(d)
          params:delta("long_delay_time", d)
          return params:get("long_delay_time")
        end,
        function(d)
          if ui_state.k1_held then
            params:delta("long_delay_rate", d)
            return params:get("long_delay_level")
          else
            params:delta("long_delay_level", d)
            return params:get("long_delay_level")
          end
        end,
        function(d)
          params:delta("long_delay_feedback", d)
          return params:get("long_delay_feedback")
        end
      },
      update_dials = function(dials)
        set_lfo_dial_value(dials[2], "d2_lvl")
        set_lfo_dial_value(dials[3], "d2_fbk")
      end,
    },
    make_lfo_page(1),
    make_lfo_page(2),
    make_lfo_page(3)
  }
end

return {
  make_pages = make_pages
}