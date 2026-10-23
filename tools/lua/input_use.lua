-- Does the game's play depend on an input? Run next to dump_state.lua's scripted play (RUSCRIPT=<this file>): after the
-- schedule has set the inputs for a frame, the inputs in DROP are forced off again and those in HOLD forced on (from frame
-- HOLDFROM, default 600), and every SAMPLE frames a checksum of the sprite RAM and of the work RAM goes to OUT as
-- "frame,sprite_sum,wram_sum". The work RAM sum leaves out the raw input bytes: the player structs' first four bytes at
-- 200800 / 200880 / 200900, the program's copies at 2000d0-2000ff and the I/O CHECK screen's at 200a6e-200a77.
--   DROP / HOLD = comma list of: p1b1 p1b2 p1b3 p1up p2b1 p2b3 p3b3 (P<n> button <m>)
--   SEL=<n>     character select: P1's direction and buttons are taken over until frame 700: n cursor moves to the right
--               on the select screen (about frames 380-460), then button 1 confirms at 470: 0 Wade, 1 Boris, 2 Kyle
--   OUT=<csv>  SAMPLE=<frames>  HOLDFROM=<frame>
local mach = manager.machine
local sp   = mach.devices[":maincpu"].spaces["program"]
local screen = mach.screens[":screen"]
local P13, P24 = mach.ioport.ports[":P1_P3"], mach.ioport.ports[":P2_P4"]
local map = {
  p1b1 = P13.fields["P1 Button 1"], p1b2 = P13.fields["P1 Button 2"], p1b3 = P13.fields["P1 Button 3"],
  p1up = P13.fields["P1 Up"], p3b3 = P13.fields["P3 Button 3"],
  p2b1 = P24.fields["P2 Button 1"], p2b3 = P24.fields["P2 Button 3"],
}
local function list(name)
  local t = {}
  for k in string.gmatch(os.getenv(name) or "", "[%w]+") do
    assert(map[k], name .. ": unknown input " .. k)
    t[#t + 1] = map[k]
  end
  return t
end
local drop, hold = list("DROP"), list("HOLD")
local HOLDFROM = tonumber(os.getenv("HOLDFROM") or "600")
local SEL = tonumber(os.getenv("SEL") or "-1")
local SAMPLE = tonumber(os.getenv("SAMPLE") or "25")
local out = assert(io.open(os.getenv("OUT") or "input_use.csv", "w"))
out:write("frame,sprite_sum,wram_sum\n")
local skip = {}
for _, base in ipairs({ 0x200800, 0x200880, 0x200900 }) do skip[base] = true; skip[base + 2] = true end
for a = 0x2000d0, 0x2000fe, 2 do skip[a] = true end
for a = 0x200a6e, 0x200a76, 2 do skip[a] = true end
local rt = P13.fields["P1 Right"]
local keep = {}
_G.INPUTUSE_KEEP = keep
keep.n = emu.add_machine_frame_notifier(function()
  local f = screen:frame_number()
  if SEL >= 0 and f < 700 then
    rt:set_value((f >= 415 and f < 415 + 12 * SEL and (f - 415) % 12 < 3) and 1 or 0)
    P13.fields["P1 Left"]:set_value(0); P13.fields["P1 Up"]:set_value(0); P13.fields["P1 Down"]:set_value(0)
    P13.fields["P1 Button 1"]:set_value((f >= 470 and f < 474) and 1 or 0)
    P13.fields["P1 Button 2"]:set_value(0)
  end
  for _, fld in ipairs(drop) do fld:set_value(0) end
  if f >= HOLDFROM then for _, fld in ipairs(hold) do fld:set_value(1) end end
  if f % SAMPLE == 0 then
    local hs, hw = 0, 0
    for a = 0x210000, 0x210fff, 2 do hs = (hs * 31 + sp:read_u16(a)) & 0xffffffff end
    for a = 0x200000, 0x20ffff, 2 do
      if not skip[a] then hw = (hw * 31 + sp:read_u16(a)) & 0xffffffff end
    end
    out:write(string.format("%d,%08x,%08x\n", f, hs, hw)); out:flush()
  end
end)
