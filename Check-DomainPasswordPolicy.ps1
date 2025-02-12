<#
.SYNOPSIS
  Checks effective domain password policy on a domain-joined Windows machine.

.DESCRIPTION
  This script:
    1. Verifies whether the machine is domain-joined.
    2. Uses 'net accounts /domain' to display basic domain password policy info.
    3. If the ActiveDirectory module is available, queries the domain for:
       - Default domain password policy via Get-ADDefaultDomainPasswordPolicy
         (or uses Get-ADDomain for more details if desired).
#>

[CmdletBinding()]
Param()

# 1) Check if this machine is domain-joined by comparing USERDOMAIN vs COMPUTERNAME
$IsDomainJoined = $env:USERDOMAIN -ne $env:COMPUTERNAME

Write-Host "`n=== Domain Password Policy Check ==="
Write-Host "=====================================`n"

if (-not $IsDomainJoined) {
    Write-Warning "This machine appears NOT to be domain-joined. (UserDomain = $($env:USERDOMAIN), ComputerName = $($env:COMPUTERNAME))"
    Write-Warning "Local password policy might apply instead. Exiting script."
    return
}
else {
    Write-Host "Machine is domain-joined. Checking domain password policy..."
    Write-Host ""
}

# 2) Basic domain-level info with 'net accounts /domain'
Write-Host "1) 'net accounts /domain' output:"
Write-Host "-------------------------------------"
net accounts /domain
Write-Host ""

# 3) Check if the Active Directory module is available, then query deeper domain policy info
Write-Host "2) Attempting to load Active Directory module and query domain policy..."
Write-Host "-----------------------------------------------------------------------"

try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Host "Active Directory module loaded successfully."

    # You can use either Get-ADDefaultDomainPasswordPolicy or Get-ADDomain for policy details.
    # 3A) Using Get-ADDefaultDomainPasswordPolicy
    Write-Host "`n--- Get-ADDefaultDomainPasswordPolicy ---"
    $domainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop
    $domainPasswordPolicy | Format-List

    # 3B) Alternatively, you can also retrieve broader domain info using Get-ADDomain:
    # Write-Host "`n--- Get-ADDomain ---"
    # $domainInfo = Get-ADDomain
    # $domainInfo | Format-List
}
catch {
    Write-Warning "Failed to load Active Directory module or query the domain policy. Error: $($_.Exception.Message)"
    Write-Warning "Possible reasons:"
    Write-Warning " - You do not have RSAT/Active Directory tools installed."
    Write-Warning " - You do not have sufficient domain permissions."
    Write-Warning " - The system cannot reach a domain controller."
    Write-Warning "Fallback is the 'net accounts /domain' info above."
}

Write-Host ""
Write-Host "=================================="
Write-Host "Done! Review the details above."
Write-Host "=================================="
