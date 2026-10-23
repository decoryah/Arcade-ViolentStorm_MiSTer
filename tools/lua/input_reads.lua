-- Which code reads the input words, and with which access sizes: a read tap on 0x274000-0x274003 (the player words) and
-- 0x278000-0x278003 (coins / service, then the EEPROM and the DIPs); one line per distinct (address, size, PC) with the
-- count and the first frame. PROGBIN=<file> also dumps the 68000 program ROM (the first 0x100000 bytes) for
--   unidasm <file> -arch m68000 -skip 0 -count 0x100000 -basepc 0 -norawbytes
-- to find what the code does with the bits (hardware.md, "Inputs"). Run next to dump_state.lua's scripted play
-- (RUSCRIPT=<this file>; its DUMPFRAMES must be later than PROBEFRAMES: MAME exits there):
--   OUT=<log file> PROBEFRAMES=<frame to write at, default 2900> PROGBIN=<program dump>
local mach = manager.machine
local cpu  = mach.devices[":maincpu"]
local sp   = cpu.spaces["program"]
local out  = assert(io.open(os.getenv("OUT") or "input_reads.txt", "w"))
local screen = mach.screens[":screen"]
local seen, order = {}, {}
local keep = {}
_G.INPUTREADS_KEEP = keep
keep.t = sp:install_read_tap(0x274000, 0x278003, "inputreads", function(off, data, mask)
  if off >= 0x274004 and off < 0x278000 then return end
  local pc = cpu.state["CURPC"].value
  local key = string.format("%06x m%04x pc%06x", off, mask & 0xffff, pc)
  local e = seen[key]
  if not e then
    e = { n = 0, f = screen:frame_number() }
    seen[key] = e
    order[#order + 1] = key
  end
  e.n = e.n + 1
end)
local done = false
keep.n = emu.add_machine_frame_notifier(function()
  if screen:frame_number() == tonumber(os.getenv("PROBEFRAMES") or "2900") and not done then
    done = true
    for _, k in ipairs(order) do
      out:write(string.format("%s count=%d first_frame=%d\n", k, seen[k].n, seen[k].f))
    end
    out:close()
    if os.getenv("PROGBIN") then
      local b = assert(io.open(os.getenv("PROGBIN"), "wb"))
      for a = 0, 0xfffff, 2 do
        local w = sp:read_u16(a)
        b:write(string.char(w >> 8, w & 0xff))
      end
      b:close()
    end
  end
end)
