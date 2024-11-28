# Function to get and display local password policy
function Display-PasswordPolicyStandalone {
    Write-Host "Fetching Local Password Policy..." -ForegroundColor Cyan

    # Retrieve password policy using secedit
    $tempFile = "$env:temp\seceditOutput.txt"
    secedit /export /cfg $tempFile | Out-Null
    $policy = Get-Content $tempFile
    Remove-Item $tempFile -Force

    # Parse password policy
    $minPasswordLength = ($policy -match "MinimumPasswordLength\s*=\s*(\d+)" | Out-Null; $Matches[1])
    $complexityRequirement = ($policy -match "PasswordComplexity\s*=\s*(\d+)" | Out-Null; $Matches[1])
    $maxPasswordAge = ($policy -match "MaximumPasswordAge\s*=\s*(\d+)" | Out-Null; $Matches[1])
    $minPasswordAge = ($policy -match "MinimumPasswordAge\s*=\s*(\d+)" | Out-Null; $Matches[1])

    # Display the policies
    Write-Host "Password Policy Details:" -ForegroundColor Yellow
    Write-Host "---------------------------------"
    Write-Host "Minimum Password Length        : $minPasswordLength"
    Write-Host "Password Complexity Required   : $complexityRequirement"
    Write-Host "Minimum Password Age (days)    : $minPasswordAge"
    Write-Host "Maximum Password Age (days)    : $maxPasswordAge"
    Write-Host "---------------------------------"
}

# Run the function
Display-PasswordPolicyStandalone