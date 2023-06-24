-- luacheck: globals redraw init include screen util enc params midi key engine softcut audio
local rec_state = { 1, 1 }

local function softcut_delay(voice, time, feedback, rate, level)
  softcut.buffer(voice, voice)
  softcut.level(voice, level)
  softcut.level_slew_time(voice, 0)
  softcut.level_input_cut(1, voice, 1.0)
  softcut.level_input_cut(2, voice, 1.0)
  softcut.pan(voice, 0.0)
  softcut.play(voice, 1)
  softcut.rate(voice, rate)
  softcut.rate_slew_time(voice, 0)
  softcut.loop_start(voice, 0)
  softcut.loop_end(voice, time)
  softcut.loop(voice, 1)
  softcut.fade_time(voice, 0.1)
  softcut.rec(voice, rec_state[voice])
  softcut.rec_level(voice, 1)
  softcut.pre_level(voice, feedback)
  softcut.position(voice, 0)
  softcut.enable(voice, 1)
  softcut.pre_filter_dry(voice, 0)
  softcut.pre_filter_hp(voice, 1.0)
  softcut.pre_filter_fc(voice, 300)
  softcut.pre_filter_rq(voice, 4.0)
end

local function apply_delays()
  softcut_delay(1,
    params:get("short_delay_time"), params:get("short_delay_feedback"), 1.0, params:get("short_delay_level")
  )
  softcut_delay(2,
    params:get("long_delay_time"), params:get("long_delay_feedback"), 1.0, params:get("long_delay_level")
  )
end

local function softcut_setup()
  softcut.reset()
  audio.level_cut(1.0)
  audio.level_adc_cut(1.0)
  audio.level_eng_cut(1.0)
  apply_delays()
end

local function clear(voice)
  softcut.buffer_clear_channel(voice)
end

local function toggle_rec(voice)
  if rec_state[voice] == 1 then
    rec_state[voice] = 0
  else
    rec_state[voice] = 1
  end
  softcut.rec(voice, rec_state[voice])
end

local function is_recording(voice)
  return rec_state[voice] == 1
end

return {
  apply_delays = apply_delays,
  softcut_setup = softcut_setup,
  toggle_rec = toggle_rec,
  is_recording = is_recording,
  clear = clear
}