<#
.SYNOPSIS
  Checks Windows time synchronization status and identifies the stratum level.
  If stratum = 1, it indicates a direct reference to an atomic/GPS clock (in theory).

.DESCRIPTION
  1. Checks if the Windows Time service (W32Time) is running.
  2. Uses w32tm.exe commands to get the current NTP source, stratum, and peers.
  3. Displays results and indicates if the current source is stratum 1.
#>

Write-Host "=== Windows Time Synchronization Status ===`n"

# 1) Check if Windows Time service is running
$service = Get-Service -Name W32Time -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Host "Windows Time service (W32Time) not found on this system."
    return
}

if ($service.Status -ne 'Running') {
    Write-Host "Windows Time service (W32Time) is not running. Starting it..."
    Start-Service W32Time
    Start-Sleep -Seconds 2  # Give it a moment to start
    Write-Host "Service started."
} else {
    Write-Host "Windows Time service (W32Time) is running."
}

Write-Host

# 2) Query the status using w32tm
#    The output typically looks like:
#      Leap Indicator: 0(no warning)
#      Stratum: 2 (secondary reference - sync from stratum 1 server)
#      ...
#      Source: time.example.org
#      ...
try {
    $statusOutput = w32tm /query /status 2>&1
} catch {
    Write-Host "Error querying w32tm /query /status:"
    Write-Host $_
    return
}

# 3) Parse out the relevant lines
#    We'll look for lines that start with "Stratum:" and "Source:"
$source = $null
$stratum = $null

foreach ($line in $statusOutput) {
    if ($line -match "Source:\s+(.*)") {
        $source = $Matches[1].Trim()
    }
    if ($line -match "Stratum:\s+(\d+)") {
        $stratum = [int]$Matches[1]
    }
}

Write-Host "Current NTP Source : $source"
Write-Host "Current Stratum    : $stratum"

# 4) Check if stratum is 1
if ($stratum -eq 1) {
    Write-Host "`nThe system is synchronized to a stratum-1 source."
    Write-Host "(Often considered an atomic or GPS clock reference.)"
} else {
    Write-Host "`nThe system is NOT synchronized to a stratum-1 source."
    Write-Host "This typically indicates the source is stratum $stratum."
}

Write-Host
Write-Host "=== Additional Peer Information ==="

# Optionally, list peers (useful to see all configured servers).
# w32tm /query /peers output might look like:
#   Peer: time.example.org, State: Active, Stratum: 1
try {
    $peersOutput = w32tm /query /peers 2>&1
    $peersOutput | ForEach-Object { Write-Host $_ }
} catch {
    Write-Host "Error querying peers: " $_
}
