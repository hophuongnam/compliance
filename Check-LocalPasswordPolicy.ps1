<#
.SYNOPSIS
  Gathers local password policy settings on a standalone Windows machine.

.DESCRIPTION
  This script:
    1. Uses 'net accounts' to display basic password and lockout policy info.
    2. Exports the local security policy via 'secedit /export' to an INF file.
    3. Searches the exported policy file for password-related and lockout-related parameters.
#>

[CmdletBinding()]
param()

# Ensure script is run in an elevated PowerShell session
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
      [Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Error "Please run this script as Administrator (elevated PowerShell)."
    return
}

Write-Host "`n=== Local Password Policy Check ==="
Write-Host "======================================`n"

# 1. Basic info with 'net accounts'
Write-Host "1) Basic Password Info via 'net accounts':"
Write-Host "-------------------------------------------"
net accounts
Write-Host ""

# 2. Export local security policy using 'secedit'
Write-Host "2) Exporting Local Security Policy (secedit /export)"
Write-Host "----------------------------------------------------"
$exportPath = Join-Path $env:TEMP "LocalSecurityPolicy.inf"

try {
    secedit /export /cfg $exportPath /quiet
    Write-Host "Local security policy exported to: $exportPath"
} catch {
    Write-Error "Failed to export security policy via secedit: $($_.Exception.Message)"
    return
}

Write-Host ""

# 3. Search the exported .inf file for key password/lockout parameters
Write-Host "3) Relevant Settings from LocalSecurityPolicy.inf:"
Write-Host "-------------------------------------------------"
Write-Host "`n> Searching for lines that mention:"
Write-Host "    - MinimumPasswordLength"
Write-Host "    - MaximumPasswordAge"
Write-Host "    - MinimumPasswordAge"
Write-Host "    - PasswordComplexity"
Write-Host "    - PasswordHistorySize"
Write-Host "    - LockoutBadCount"
Write-Host "    - LockoutDuration"
Write-Host "    - ResetLockoutCount"
Write-Host ""

Select-String -Path $exportPath -Pattern `
    '^MinimumPasswordLength=' , `
    '^MaximumPasswordAge=' , `
    '^MinimumPasswordAge=' , `
    '^PasswordComplexity=' , `
    '^PasswordHistorySize=' , `
    '^LockoutBadCount=' , `
    '^LockoutDuration=' , `
    '^ResetLockoutCount=' |
    ForEach-Object {
        # Just echo the line (you could parse further if needed)
        $_.Line
    }

Write-Host ""
Write-Host "======================================"
Write-Host "Done! Review the details above."
Write-Host "======================================"
