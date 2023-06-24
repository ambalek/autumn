-- luacheck: globals ui_state

local function make_lfo_state()
  return {
    target = nil,
    pw = 0,
    bits = 0,
    attack = 0,
    release = 0,
    pan = 0,
  }
end

ui_state = {
  k1_held = false,
  lfo1 = make_lfo_state(),
  lfo2 = make_lfo_state(),
  lfo3 = make_lfo_state(),
}
