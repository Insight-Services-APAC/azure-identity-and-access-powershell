Import-Module ..\IA.psd1 -Force

# On-prem users with mailboxes
Write-Host -ForegroundColor Yellow 'Getting all users synced from on-premise with mailboxes...' -NoNewline
$OnPremUsersWithMailboxes = Get-IAAzureADUsersAsList | Where-Object { $_.Type -eq 'User' -and $_.OnPremisesSyncEnabled -eq $true }
Write-Host -ForegroundColor Yellow "Done! ($($OnPremUsersWithMailboxes.Count) objects were returned)"
$FileName = "IdsForOnPremUsersWithMailbox_$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv"
Write-Host -ForegroundColor Yellow "Exporting to $Filename..." -NoNewline
$OnPremUsersWithMailboxes | ForEach-Object {
    $_ | Select-Object ObjectId
} | Export-Csv $FileName -NoTypeInformation
Write-Host -ForegroundColor Yellow 'Done!'

