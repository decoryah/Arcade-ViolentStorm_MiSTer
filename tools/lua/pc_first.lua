-- The frame at which each of a list of code addresses is first fetched by the 68000 (read taps on the program ROM).
--   PCLIST=<hex,hex,...>   addresses (word aligned)     PCFIRST_OUT=<file>   (default pc_first.txt)
--   PCLAST=<frames>        stop after this frame (default 1500)
local mach = manager.machine
local sp   = mach.devices[":maincpu"].spaces["program"]
local KEEP = {}
_G.PFKEEP = KEEP
local out = assert(io.open(os.getenv("PCFIRST_OUT") or "pc_first.txt", "w"))
local LAST = tonumber(os.getenv("PCLAST") or "1500")
local frame = 0
local seen = {}
for tok in string.gmatch(os.getenv("PCLIST") or "", "%x+") do
  local a = tonumber(tok, 16)
  KEEP[#KEEP + 1] = sp:install_read_tap(a, a + 1, "pf" .. tok, function(off, data, mask)
    if not seen[a] then
      seen[a] = true
      out:write(string.format("%06x first fetched in frame %d\n", a, frame)); out:flush()
    end
  end)
end
KEEP.n = emu.add_machine_frame_notifier(function()
  frame = frame + 1
  if frame >= LAST then out:close(); mach:exit() end
end)
