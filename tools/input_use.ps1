# Which of MAME's input bits does Violent Storm's program use? MAME's port list has a third button for each player and a
# fourth player; the cabinet has two buttons and three players. Runs tools/lua/input_use.lua next to dump_state.lua's
# scripted play, three experiment groups, every run from a clean state (its own cfg / nvram directory), all at once:
#   drop    scripted play, 4000 frames: nothing suppressed (twice: the determinism control), P1 button 1, 2, 3 never pressed
#   char    each of the three characters (cursor moves on the select screen), 2500 frames, P1 button 3 held from frame 600 or not
#   svc     the service menu (test switch on from frame 800), 2400 frames: P1 button 1 / 3, P2 button 3, P3 button 3 held from
#           frame 1500, or nothing
# then tools/cmp_input_use.py <dir> compares the checksums (work\mame\inputs\iu_<group>_<name>.csv).
#   tools/input_use.ps1 [-Work <dir>]
param([string]$Work = 'C:\repos\viostorm-mister\work\mame\inputs')
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
New-Item -ItemType Directory -Force $Work | Out-Null
$runs = @()
foreach ($r in @(@('base1', ''), @('base2', ''), @('b1', 'p1b1'), @('b2', 'p1b2'), @('b3', 'p1b3'))) {
  $runs += @{ name = "drop_$($r[0])"; frames = '4000'; env = @{ SCHEDULE = 'play'; DROP = $r[1] } }
}
foreach ($sel in 0, 1, 2) { foreach ($hold in '', 'p1b3') {
  $runs += @{ name = "char_sel${sel}_" + $(if ($hold) { 'held' } else { 'free' }); frames = '2500'
              env = @{ SCHEDULE = 'play'; SEL = "$sel"; HOLD = $hold } } } }
foreach ($h in '', 'p1b1', 'p1b3', 'p2b3', 'p3b3') {
  $runs += @{ name = "svc_" + $(if ($h) { $h } else { 'none' }); frames = '2400'
              env = @{ SERVICE = '1'; SERVICE_FROM = '800'; HOLD = $h; HOLDFROM = '1500' } }
}
$MaxParallel = 4      # one core each
$jobs = @()
foreach ($r in $runs) {
  while (@($jobs | Where-Object { $_.State -eq 'Running' }).Count -ge $MaxParallel) { Start-Sleep -Seconds 2 }
  $jobs += Start-Job -ArgumentList $r, $tools, $Work -ScriptBlock {
    param($r, $tools, $Work)
    $d = "$Work\$($r.name)"
    New-Item -ItemType Directory -Force "$d\states" | Out-Null
    $env = $r.env + @{ SKIPBOOT = '1'; DUMPFRAMES = $r.frames; DUMPDIR = "$d\states"; RUSCRIPT = "$tools\lua\input_use.lua";
                       OUT = "$Work\iu_$($r.name).csv"; SAMPLE = '25' }
    & "$tools\mame_run.ps1" -Script "$tools\lua\dump_state.lua" -Seconds 600 -Work $d -Env $env | Out-String
  }
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
Write-Output "done: $($runs.Count) runs in $Work; now: python tools/cmp_input_use.py $Work"
