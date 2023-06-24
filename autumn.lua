-- Autumn (v0.0.2)
--
-- A simple synth playable with
-- MIDI or the grid,
-- featuring two delays and LFOs
--
-- written by ambalek for
-- the norns community

-- luacheck: globals redraw init include screen util enc params midi key engine softcut audio clock ui_state
engine.name = 'AutumnStandalone'

include("lib/ui.state")
local MusicUtil = require "musicutil"
local delays = include("lib/delays")
local pages = include("lib/pages")
local settings = include("lib/settings")
local LFO = include("lib/lfo")
local AutumnGrid = include("lib/grid")

settings.setup_params()
LFO.init()

local current_page = 1
local autumn_pages = pages.make_pages()
screen.aa(1)

function redraw()
  local page = autumn_pages[current_page]
  local dials = page.dials
  screen.clear()
  screen.fill()
  screen.level(15)
  for i = 1, #dials do
    if dials[i] ~= nil then
      dials[i]:redraw()
    end
  end
  if page.render ~= nil then
    page.render(LFO.lfos[page.lfo_id])
  end
  -- button text 1
  if page.key2_text ~= nil and page.dials[1] ~= nil then
    screen.level(2)
    screen.circle(5, 13, 3)
    screen.fill()
    screen.close()
  end
  -- button text 2
  screen.level(2)
  screen.circle(60, 51, 3)
  screen.fill()
  screen.close()
  screen.move(51, 61)
  screen.level(10)
  if ui_state.k1_held then
    if type(page.key2_text) == "function" then
      screen.text(page.key2_text())
    else
      screen.text(page.key2_text or " ")
    end
  else
    screen.text("prev")
  end
  if page.update_dials ~= nil then
    page.update_dials(dials)
  end
  -- button text 3
  screen.level(2)
  screen.circle(96, 51, 3)
  screen.fill()
  screen.close()
  screen.move(88, 61)
  screen.level(10)
  screen.text("next")
  -- page title
  screen.move(128, 8)
  screen.text_right(page.title)
  screen.close()
  screen.update()
end

function enc(n, d)
  local page = autumn_pages[current_page]
  if page.dial_callbacks[n] ~= nil then
    local value = page.dial_callbacks[n](d)
    if page.dials[n] ~= nil then
      page.dials[n]:set_value(value)
    end
  end
  redraw()
end

function key(n, z)
  if z == 1 and n == 1 then
    ui_state.k1_held = true
  elseif z == 0 and n == 1 then
    ui_state.k1_held = false
  elseif n == 2 and z == 0 then
    if ui_state.k1_held then
      if autumn_pages[current_page].key2_callback ~= nil then
        autumn_pages[current_page].key2_callback()
      end
    else
      current_page = util.wrap(current_page - 1, 1, #autumn_pages)
    end
  elseif n == 3 and z == 0 then
    current_page = util.wrap(current_page + 1, 1, #autumn_pages)
  end
  redraw()
end

local function handle_midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "note_on" then
    local note = msg.note
    local velocity = msg.vel / 128
    engine.amp(util.clamp(velocity * params:get("gain"), 0.0, 1.0))
    engine.hz(MusicUtil.note_num_to_freq(note))
  end
end

function init()
  -- Set up MIDI input
  midi.add(1, "all")
  midi.event = handle_midi_event
  -- Set up delays, engines, LFOs, and the grid
  delays.softcut_setup()
  engine.attack(params:get("attack"))
  engine.release(params:get("release"))
  engine.pw(params:get("pw"))
  engine.bits(params:get("bits"))
  engine.cutoff(params:get("cutoff"))
  engine.gain(0.5)
  params:default()
  LFO.start_all()
  AutumnGrid.init()
  -- cause the dials to be set based on the current params
  for i = 1, #autumn_pages do
    local page = autumn_pages[i]
    for j = 1, #page.dial_callbacks do
      if page.dial_callbacks[j] ~= nil then
        local value = page.dial_callbacks[j](0)
        if page.dials[j] ~= nil then
          page.dials[j]:set_value(value)
        end
      end
    end
  end
  -- screen refresh timer
  clock.run(
    function()
      while true do
        clock.sleep(1 / 30)
        redraw()
      end
    end
  )
end