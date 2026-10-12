-- List every I/O port and its fields (names as MAME's Lua knows them), then exit.
local mach = manager.machine
local n = 0
emu.add_machine_frame_notifier(function()
  n = n + 1
  if n < 2 then return end
  for tag, port in pairs(mach.ioport.ports) do
    local t = {}
    for name, fld in pairs(port.fields) do t[#t + 1] = name end
    table.sort(t)
    print("PORT " .. tag .. ": " .. table.concat(t, " | "))
  end
  mach:exit()
end)
