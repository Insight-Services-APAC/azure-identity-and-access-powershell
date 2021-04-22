using namespace System.Collections.Generic
using namespace Microsoft.Open.Azure.AD.CommonLibrary

$ErrorActionPreference = "Stop"

# Draft code, Requires refactor and tidy - Chris Dymond

Import-Module AzureADPreview

try {
    Get-AzureADCurrentSessionInfo | Out-Null
}
catch [AadNeedAuthenticationException] {
    Connect-AzureAD
}

$CloudOnlyADAccounts = Get-AzureADUser -All $True | Where-Object { $_.DirSyncEnabled -ne $true -and $_.UserType -eq 'Member' }

Import-Module ExchangeOnlineManagement

$ResultSize = 'Unlimited'

$Sessions = Get-PSSession | Select-Object -Property State, Name
$isConnected = (@($Sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
If ($isConnected -ne "True") {
    Get-PSSession | Remove-PSSession
    Write-Output "$(Get-Date) Creating Exchange Online session"
    Connect-ExchangeOnline
}

$SharedMailboxes = Get-EXOMailbox -RecipientTypeDetails SharedMailbox -ResultSize $ResultSize
$RoomMailboxes = Get-EXOMailbox -RecipientTypeDetails RoomMailbox -ResultSize $ResultSize
$EquipmentMailboxes = Get-EXOMailbox -RecipientTypeDetails EquipmentMailbox -ResultSize $ResultSize
$UserMailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize $ResultSize

$CloudOnlyUsers = @()
$CloudOnlyUsersWithMailboxes = @()
$CloudOnlySharedMailboxes = @()
$CloudOnlyEquipmentMailboxes = @()
$CloudOnlyRoomMailboxes = @()

$CloudOnlyADAccounts | ForEach-Object {
    $UserMailboxMatched = [Linq.Enumerable]::FirstOrDefault(([Linq.Enumerable]::Where($UserMailboxes, `
                    [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
            )))
    if ($UserMailboxMatched) {
        $CloudOnlyUsersWithMailboxes += $_
        return
    }

    $SharedMailboxMatched = [Linq.Enumerable]::FirstOrDefault(([Linq.Enumerable]::Where($SharedMailboxes, `
                    [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
            )))
    if ($SharedMailboxMatched) {
        $CloudOnlySharedMailboxes += $_
        return
    }

    $RoomMailboxMatched = [Linq.Enumerable]::FirstOrDefault(([Linq.Enumerable]::Where($RoomMailboxes, `
                    [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
            )))
    if ($RoomMailboxMatched) {
        $CloudOnlyRoomMailboxes += $_
        return
    }

    $EquipmentMailboxMatched = [Linq.Enumerable]::FirstOrDefault(([Linq.Enumerable]::Where($EquipmentMailboxes, `
                    [Func[Object, bool]] { param($x); return $x.ExternalDirectoryObjectId -eq $_.ObjectId }
            )))
    if ($EquipmentMailboxMatched) {
        $CloudOnlyEquipmentMailboxes += $_
        return
    }

    $CloudOnlyUsers += $_
}

Write-Output "Total Azure AD Cloud Only Accounts: $($CloudOnlyADAccounts.Count)"
Write-Output "---"
Write-Output "Cloud Only Users: $($CloudOnlyUsers.Count)"
Write-Output "Cloud Only Users With Mailboxes: $($CloudOnlyUsersWithMailboxes.Count)"
Write-Output "Cloud Only Shared Mailboxes: $($CloudOnlySharedMailboxes.Count)"
Write-Output "Cloud Only Equipment Mailboxes: $($CloudOnlyEquipmentMailboxes.Count)"
Write-Output "Cloud Only Room Mailboxes: $($CloudOnlyRoomMailboxes.Count)"

class ReportItem {
    [string]$DisplayName
    [string]$UserPrincipalName
    [string]$Type
}

[List[ReportItem]] $ReportItemList = [List[ReportItem]]::new()

$CloudOnlyUsers | ForEach-Object {
    $ReportItem = [ReportItem]::new()
    $ReportItem.DisplayName = $_.DisplayName
    $ReportItem.UserPrincipalName = $_.UserPrincipalName
    $ReportItem.Type = "User (No Mailbox)"
    $ReportItemList.Add($ReportItem)
}

$CloudOnlyUsersWithMailboxes | ForEach-Object {
    $ReportItem = [ReportItem]::new()
    $ReportItem.DisplayName = $_.DisplayName
    $ReportItem.UserPrincipalName = $_.UserPrincipalName
    $ReportItem.Type = "User"
    $ReportItemList.Add($ReportItem)
}

$CloudOnlySharedMailboxes | ForEach-Object {
    $ReportItem = [ReportItem]::new()
    $ReportItem.DisplayName = $_.DisplayName
    $ReportItem.UserPrincipalName = $_.UserPrincipalName
    $ReportItem.Type = "Shared Mailbox"
    $ReportItemList.Add($ReportItem)
}

$CloudOnlyEquipmentMailboxes | ForEach-Object {
    $ReportItem = [ReportItem]::new()
    $ReportItem.DisplayName = $_.DisplayName
    $ReportItem.UserPrincipalName = $_.UserPrincipalName
    $ReportItem.Type = "Equipment Mailbox"
    $ReportItemList.Add($ReportItem)
}

$CloudOnlyRoomMailboxes | ForEach-Object {
    $ReportItem = [ReportItem]::new()
    $ReportItem.DisplayName = $_.DisplayName
    $ReportItem.UserPrincipalName = $_.UserPrincipalName
    $ReportItem.Type = "Room Mailbox"
    $ReportItemList.Add($ReportItem)
}

$ReportItemList | Export-Csv 'report.csv' -NoTypeInformation

Disconnect-ExchangeOnline -Confirm:$false
Disconnect-AzureAD
