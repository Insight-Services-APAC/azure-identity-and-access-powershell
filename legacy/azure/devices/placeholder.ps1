$AllDevices = Get-AzureADDevice -All $true

$HybridJoined = $AllDevices | `
    Where-Object { $_.DeviceTrustType -eq 'ServerAd' } | Select-Object *

$Registered = $AllDevices | `
    Where-Object { $_.DeviceTrustType -eq 'Workplace' } | Select-Object *

Write-Output "All Devices: $($AllDevices.Count)"
Write-Output "Hybrid Joined: $($HybridJoined.Count)" 
Write-Output "Azure AD Registered: $($Registered.Count)"   

$WindowsRegistered = $Registered | Where-Object { $_.DeviceOSType -eq 'Windows' }
$AndroidRegistered = $Registered | Where-Object { $_.DeviceOSType -eq 'Android' }
$AppleRegistered = $Registered | Where-Object { $_.DeviceOSType -eq 'iOS' }

Write-Output "Windows Registered: $($WindowsRegistered.Count)"
Write-Output "Android Registered: $($AndroidRegistered.Count)"
Write-Output "iOS Registered: $($AppleRegistered.Count)"

