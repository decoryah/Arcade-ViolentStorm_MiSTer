-- Print MAME's screen configuration for the running set: the raster the driver ends up with, found from the
-- time the frame takes to reach each line (time_until_pos), as the lines past the real total wrap.
local scr = manager.machine.screens[":screen"]
local function secs(t) if type(t) == "number" then return t end return t:as_double() end
local n = 0
emu.add_machine_frame_notifier(function()
  n = n + 1
  if n == 3 then
    local t0 = secs(scr:time_until_pos(0, 0))
    local out = {}
    for _, v in ipairs({16, 24, 100, 200, 240, 248, 255, 256, 257, 263, 264, 270}) do
      local ok, t = pcall(function() return secs(scr:time_until_pos(v, 0)) end)
      out[#out+1] = string.format("v%d=%.1fus", v, ok and (t * 1e6) or -1)
    end
    print(string.format("TIMES(to pos, us, from now; to 0,0 = %.1f) %s", t0 * 1e6, table.concat(out, " ")))
    local hs = {}
    for _, h in ipairs({0, 100, 383, 384, 400, 511, 512, 600}) do
      local ok, t = pcall(function() return secs(scr:time_until_pos(60, h)) end)
      hs[#hs+1] = string.format("h%d=%.2fus", h, ok and (t * 1e6) or -1)
    end
    print("HTIMES(line 60) " .. table.concat(hs, " "))
  end
  if n >= 4 then manager.machine:exit() end
end)
