# Enable LSA Protection
Write-Host "Enabling LSA Protection..." -ForegroundColor Green

# Define LSA registry path and value
$lsaRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$lsaRegistryValueName = "RunAsPPL"
$lsaRegistryValue = 1

# Check if the LSA registry key exists
if (-not (Test-Path $lsaRegistryPath)) {
    Write-Host "Creating registry path for LSA: $lsaRegistryPath" -ForegroundColor Yellow
    New-Item -Path $lsaRegistryPath -Force
}

# Set the registry value to enable LSA Protection
Set-ItemProperty -Path $lsaRegistryPath -Name $lsaRegistryValueName -Value $lsaRegistryValue -Force

Write-Host "LSA Protection enabled." -ForegroundColor Green

# Disable LLMNR
Write-Host "Disabling LLMNR..." -ForegroundColor Green

# Define LLMNR registry path and value
$llmnrRegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
$llmnrRegistryValueName = "EnableMulticast"
$llmnrRegistryValue = 0

# Check if the LLMNR registry key exists
if (-not (Test-Path $llmnrRegistryPath)) {
    Write-Host "Creating registry path for LLMNR: $llmnrRegistryPath" -ForegroundColor Yellow
    New-Item -Path $llmnrRegistryPath -Force
}

# Set the registry value to disable LLMNR
Set-ItemProperty -Path $llmnrRegistryPath -Name $llmnrRegistryValueName -Value $llmnrRegistryValue -Force

Write-Host "LLMNR disabled." -ForegroundColor Green

Write-Host "Both LSA Protection and LLMNR settings have been applied. A reboot is required for the changes to take effect." -ForegroundColor Cyan
