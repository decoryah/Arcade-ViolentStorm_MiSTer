# Run MAME 0.289 on a Violent Storm set with one of tools/lua/*.lua as the autoboot script.
#   tools/mame_run.ps1 -Script dump_state.lua -Env @{DUMPFRAMES='100,300'; DUMPDIR='C:\...\states'} [-Machine viostorm] [-Seconds 900]
# MAME and the ROMs are the owner's (see docs/hardware.md "Tools"); the working files go under work/mame.
param(
  [Parameter(Mandatory = $true)][string]$Script,
  [hashtable]$Env = @{},
  [string]$Machine = 'viostorm',
  [int]$Seconds = 1800,
  [string]$Mame = 'C:\repos\taitol-mister\mister\tools\mame\mame.exe',
  [string]$RomPath = 'R:\Games\Arcade\MAME 0.289 ROMs (merged)',
  [string]$Work = 'C:\repos\viostorm-mister\work\mame',
  [string]$SnapDir = ''
)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$lua = if (Test-Path $Script) { (Resolve-Path $Script).Path } else { Join-Path $here "lua\$Script" }
New-Item -ItemType Directory -Force "$Work\cfg", "$Work\nvram" | Out-Null
if (-not $SnapDir) { $SnapDir = "$Work\snap" }
New-Item -ItemType Directory -Force $SnapDir | Out-Null
foreach ($k in $Env.Keys) { Set-Item -Path "Env:$k" -Value ([string]$Env[$k]) }
try {
  & $Mame $Machine -rompath $RomPath -video none -sound none -nothrottle -skip_gameinfo -window `
    -cfg_directory "$Work\cfg" -nvram_directory "$Work\nvram" -snapshot_directory $SnapDir `
    -autoboot_script $lua -seconds_to_run $Seconds 2>&1 | Select-Object -Last 5
} finally {
  foreach ($k in $Env.Keys) { Remove-Item -Path "Env:$k" -ErrorAction SilentlyContinue }
}
