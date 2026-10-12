-- Every CPU write to the K055550 (0x25c000-0x25c03f) in viostorm_map, with the command it triggers.
-- A command is a write to word 0 with the high byte lane (MAME: K055550_word_w, offset 0 && ACCESSING_BITS_8_15);
-- the line printed for it carries the whole register file as the game has set it up (m_prot_data[0..31]).
--   K550_OUT=<file>      log (default k550_log.txt)
--   K550_FRAMES=<n>      frames to run (default 3000; with RUSCRIPT under dump_state.lua its DUMPFRAMES decides)
--   K550_VERBOSE=1       also log the plain register writes
-- Run it standalone, or chained from tools/lua/dump_state.lua with RUSCRIPT so the scripted inputs play the game.
local mach = manager.machine
local cpu  = mach.devices[":maincpu"]
local sp   = cpu.spaces["program"]
local KEEP = {}
_G.K550KEEP = KEEP
local out  = assert(io.open(os.getenv("K550_OUT") or "k550_log.txt", "w"))
local N    = tonumber(os.getenv("K550_FRAMES") or "0")
local VERB = os.getenv("K550_VERBOSE") == "1"
local f = 0
local cnt = {}

local function regs()
  local t = {}
  for i = 0, 31 do t[#t + 1] = string.format("%04x", sp:read_u16(0x25c000 + i * 2)) end
  return table.concat(t, " ")
end

KEEP.w = sp:install_write_tap(0x25c000, 0x25c03f, "k550", function(off, data, mask)
  local r = (off - 0x25c000) // 2
  if r == 0 and (mask & 0xff00) ~= 0 then
    local cmd = (data >> 8) & 0xff
    cnt[cmd] = (cnt[cmd] or 0) + 1
    out:write(string.format("f%d pc %06x CMD %02x mask %04x data %04x | %s\n", f, cpu.state["CURPC"].value, cmd, mask & 0xffff, data & 0xffff, regs()))
  elseif VERB then
    out:write(string.format("f%d pc %06x w r%02d %04x/%04x\n", f, cpu.state["CURPC"].value, r, data & 0xffff, mask & 0xffff))
  end
end)

KEEP.r = sp:install_read_tap(0x25c000, 0x25c03f, "k550r", function(off, data, mask)
  if VERB then
    out:write(string.format("f%d pc %06x r r%02d %04x\n", f, cpu.state["CURPC"].value, (off - 0x25c000) // 2, data & 0xffff))
  end
end)

local function finish()
  out:write("# command counts:\n")
  for c, n in pairs(cnt) do out:write(string.format("#   %02x  %d\n", c, n)) end
  out:close()
end

KEEP.n = emu.add_machine_frame_notifier(function()
  f = f + 1
  if N > 0 and f >= N then finish(); mach:exit() end
end)
_G.K550FINISH = finish
