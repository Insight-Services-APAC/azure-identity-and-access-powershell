using namespace System.Collections.Generic

$ErrorActionPreference = "Stop"

Import-Module ExchangeOnlineManagement

$ResultSize = 'Unlimited'

$Sessions = Get-PSSession | Select-Object -Property State, Name
$isConnected = (@($Sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
If ($isConnected -ne "True") {
    Get-PSSession | Remove-PSSession
    Write-Output "$(Get-Date) Creating Exchange Online session"
    Connect-ExchangeOnline
}

<#
    .SYNOPSIS

        @Author: Chris Dymond
    .DESCRIPTION
    To DO:
    1. Discover custom permissions
    2. Get the mailbox sizes
    3. On-Prem vs Cloud Creation
#>



# -ResultSize (default 1000) or use Unlimited

# Get-EXOMailbox
# Elevated Exchange permissions required to retrieve other mailboxes  
# Purpose: To view mailbox objects and attributes, populate property pages,
# or supply mailbox information to other tasks

# Get-EXOMailboxStatistics
# Elevated Exchange permissions required to retrieve other mailboxes  
# Purpose: To return information about a mailbox, such as the size of the mailbox,
# the number of messages it contains, and the last time it was accessed.

# Get-EXORecipient
# No additional permissions required
# Returns all mail-enabled objects (for example, mailboxes, mail users, mail contacts, and
# distribution groups).

Write-Output "$(Get-Date) Result Size: $ResultSize"
Write-Output "$(Get-Date) Getting Exchange Online Recipients"
$exoRecipients = Get-EXORecipient -ResultSize $ResultSize
Write-Output "$(Get-Date) Completed with $($exoRecipients.Count) results."

# RecipientTypeDetails Lists
[List[PSCustomObject]] $DiscoveryMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $DynamicDistributionGroups = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $EquipmentMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $GroupMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $GuestMailUsers = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $LegacyMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $LinkedMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $LinkedRoomMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailContacts = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailForestContacts = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailNonUniversalGroups = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailUniversalDistributionGroups = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailUniversalSecurityGroups = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $MailUsers = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $PublicFolders = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $PublicFolderMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RemoteEquipmentMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RemoteRoomMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RemoteSharedMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RemoteTeamMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RemoteUserMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RoomLists = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $RoomMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $SchedulingMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $SharedMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $TeamMailboxes = [List[PSCustomObject]]::new()
[List[PSCustomObject]] $UserMailboxes = [List[PSCustomObject]]::new()

Write-Output "$(Get-Date) Sorting recipient types"

ForEach ($exoRecipient in $exoRecipients) {
    switch ($exoRecipient.RecipientTypeDetails) {
        "DiscoveryMailbox" { $DiscoveryMailboxes.Add($exoRecipient) }
        "DynamicDistributionGroup" { $DynamicDistributionGroups.Add($exoRecipient) }
        "EquipmentMailbox" { $EquipmentMailboxes.Add($exoRecipient) }
        "GroupMailbox" { $GroupMailboxes.Add($exoRecipient) }
        "GuestMailUser" { $GuestMailUsers.Add($exoRecipient) }
        "LegacyMailbox" { $LegacyMailboxes.Add($exoRecipient) }
        "LinkedMailbox" { $LinkedMailboxes.Add($exoRecipient) }
        "LinkedRoomMailbox" { $LinkedRoomMailboxes.Add($exoRecipient) }
        "MailContact" { $MailContacts.Add($exoRecipient) }
        "MailForestContact" { $MailForestContacts.Add($exoRecipient) }
        "MailNonUniversalGroup" { $MailNonUniversalGroups.Add($exoRecipient) }
        "MailUniversalDistributionGroup" { $MailUniversalDistributionGroups.Add($exoRecipient) }
        "MailUniversalSecurityGroup" { $MailUniversalSecurityGroups.Add($exoRecipient) }
        "MailUser" { $MailUsers.Add($exoRecipient) }
        "PublicFolder" { $PublicFolders.Add($exoRecipient) }
        "PublicFolderMailbox" { $PublicFolderMailboxes.Add($exoRecipients) }
        "RemoteEquipmentMailbox" { $RemoteEquipmentMailboxes.Add($exoRecipient) }
        "RemoteRoomMailbox" { $RemoteRoomMailboxes.Add($exoRecipient) }
        "RemoteSharedMailbox" { $RemoteSharedMailboxes.Add($exoRecipient) }
        "RemoteTeamMailbox" { $RemoteTeamMailboxes.Add($exoRecipient) }
        "RemoteUserMailbox" { $RemoteUserMailboxes.Add($exoRecipient) }
        "RoomList" { $RoomLists.Add($exoRecipient) }
        "RoomMailbox" { $RoomMailboxes.Add($exoRecipient) }
        "SchedulingMailbox" { $SchedulingMailboxes.Add($exoRecipient) }
        "SharedMailbox" { $SharedMailboxes.Add($exoRecipient) }
        "TeamMailbox" { $TeamMailboxes.Add($exoRecipient) }
        "UserMailbox" { $UserMailboxes.Add($exoRecipient) }
    
        Default { Throw "Unexpected RecipientTypeDetail $($exoRecipient.RecipientTypeDetails)" }
    }
}

Write-Output "$(Get-Date) Completed.`n"

Write-Output "DiscoveryMailboxes`t`t$($DiscoveryMailboxes.Count) "
Write-Output "DynamicDistributionGroups`t$($DynamicDistributionGroups.Count)"
Write-Output "EquipmentMailboxes`t`t$($EquipmentMailboxes.Count)"
Write-Output "GroupMailboxes`t`t`t$($GroupMailboxes.Count)"
Write-Output "GuestMailUsers`t`t`t$($GuestMailUsers.Count)"
Write-Output "LegacyMailboxes`t`t`t$($LegacyMailboxes.Count)"
Write-Output "LinkedMailboxes`t`t`t$($LinkedMailboxes.Count)"
Write-Output "LinkedRoomMailboxes`t`t$($LinkedRoomMailboxes.Count)"
Write-Output "MailContacts`t`t`t$($MailContacts.Count)"
Write-Output "MailForestContacts`t`t$($MailForestContacts.Count)"
Write-Output "MailNonUniversalGroups`t`t$($MailNonUniversalGroups.Count)"
Write-Output "MailUniversalDistributionGroups`t$($MailUniversalDistributionGroups.Count)"
Write-Output "MailUniversalSecurityGroups`t$($MailUniversalSecurityGroups.Count)"
Write-Output "MailUsers`t`t`t$($MailUsers.Count)"
Write-Output "PublicFolders`t`t`t$($PublicFolders.Count)"
Write-Output "PublicFolderMailboxes`t`t$($PublicFolderMailboxes.Count)"
Write-Output "RemoteEquipmentMailboxes`t$($RemoteEquipmentMailboxes.Count)"
Write-Output "RemoteRoomMailboxes`t`t$($RemoteRoomMailboxes.Count)"
Write-Output "RemoteSharedMailboxes`t`t$($RemoteSharedMailboxes.Count)"
Write-Output "RemoteTeamMailboxes`t`t$($RemoteTeamMailboxes.Count)"
Write-Output "RemoteUserMailboxes`t`t$($RemoteUserMailboxes.Count)"
Write-Output "RoomLists`t`t`t$($RoomLists.Count)"
Write-Output "RoomMailboxes`t`t`t$($RoomMailboxes.Count)"
Write-Output "SchedulingMailboxes`t`t$($SchedulingMailboxes.Count)"
Write-Output "SharedMailboxes`t`t`t$($SharedMailboxes.Count)"
Write-Output "TeamMailboxes`t`t`t$($TeamMailboxes.Count)"
Write-Output "UserMailboxes`t`t`t$($UserMailboxes.Count)"

Write-Output ""


# Write-Output "Getting UserMailbox sizes"
# $UserMailboxes | ForEach-Object {
#     $Statistics = Get-EXOMailboxStatistics $_.Identity
#     $_ | Add-Member -NotePropertyName TotalItemSize -NotePropertyValue $Statistics.TotalItemSize
# }

# $SharedMailboxes | ForEach-Object {
#     # Return all users with standard full access rights
#     Get-EXOMailboxPermission $_.Identity | Where-Object { $_.User -ne "NT AUTHORITY\SELF" `
#             -and $_.AccessRights -contains 'FullAccess' -and $_.Deny -eq $False `
#             -and $_.InheritanceType -eq 'All' }

#     # Return all trustees with standard SendAs rights
#     Get-EXORecipientPermission $_.Identity | Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" `
#             -and $_.AccessControlType -eq 'Allow' -and $_.AccessRights -contains 'SendAs' }
# }

# $UserMailboxes | ForEach-Object {
#     Get-EXOMailboxPermission $_.Identity | Where-Object { $_.User -ne "NT AUTHORITY\SELF" }
#     Get-EXORecipientPermission $_.Identity | Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" }
# }

# $EmailQuery = 'SMTP:Chris.Dymond@domain.com'

# # Linq Query example - could be placed into function
# # contains or ccontains (for case sensitive etc)
# [Linq.Enumerable]::Where(
#     $UserMailboxes,
#     [Func[PSCustomObject, bool]] { param($x); return $x.EmailAddresses -contains $EmailQuery }
# )