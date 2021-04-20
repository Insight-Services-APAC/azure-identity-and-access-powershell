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

    TODO: Refactor, filter on type

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


$RecipientTypeDetails = @(
    'DiscoveryMailbox',
    'DynamicDistributionGroup',
    'EquipmentMailbox',
    'GroupMailbox',
    'GuestMailUser',
    'LegacyMailbox',
    'LinkedMailbox',
    'LinkedRoomMailbox',
    'MailContact',
    'MailForestContact',
    'MailNonUniversalGroup',
    'MailUniversalDistributionGroup',
    'MailUniversalSecurityGroup',
    'MailUser',
    'PublicFolder',
    'PublicFolderMailbox',
    'RemoteEquipmentMailbox',
    'RemoteRoomMailbox',
    'RemoteSharedMailbox'
    'RemoteTeamMailbox',
    'RemoteUserMailbox',
    'RoomList',
    'RoomMailbox',
    'SchedulingMailbox',
    'SharedMailbox',
    'TeamMailbox',
    'UserMailbox'    
)

function AddMailboxSizes([List[PSCustomObject]] $Mailboxes) {
    $Mailboxes | ForEach-Object {
        # Preference lookup on GUID
        if ($_.ExternalDirectoryObjectId) {
            $Statistics = Get-EXOMailboxStatistics -ExchangeGuid $_.ExternalDirectoryObjectId
        }
        else {
            $Statistics = Get-EXOMailboxStatistics -Identity $_.Identity
        }
        
        $bytesStartIndex = $Statistics.TotalItemSize.Value.ToString().IndexOf('(')
        $_ | Add-Member -NotePropertyName TotalItemSize -NotePropertyValue $Statistics.TotalItemSize -Force

        $SizeInGB = [Math]::Round($_.TotalItemSize.Value.ToString().Substring($bytesStartIndex + 1, `
                    $_.TotalItemSize.Value.ToString().Length - $bytesStartIndex - 7).Replace(',', '') / 1GB, 2)

        $_ | Add-Member -NotePropertyName TotalItemSizeInGB -NotePropertyValue $SizeInGB -Force
    }
}

function SumMailboxSizes ([List[PSCustomObject]] $Mailboxes) {
    $TotalSize = 0
    $Mailboxes | ForEach-Object {
        $TotalSize += $_.TotalItemSizeInGB
    }
    $TotalSize
}

$AllRecipientsList = [List[PSCustomObject]]::new()

$exoRecipients | ForEach-Object {
    $AllRecipientsList.Add($_)
}

class ExchangeSummaryItem {
    [string]$Kind
    [int]$TotalObjects
    [string]$TotalSizeInGB
}

$OverviewReport = [List[ExchangeSummaryItem]]::new()


$RecipientTypeDetails | ForEach-Object {
    $esi = [ExchangeSummaryItem]::new()
    $esi.Kind = $_
    $Resources = [Linq.Enumerable]::ToList(([Linq.Enumerable]::Where(
                $AllRecipientsList, [Func[PSCustomObject, bool]] { param($x); return $x.RecipientTypeDetails -eq $_ }
            )))
    $esi.TotalObjects = $Resources.Count

    if ($_ -match 'mailbox') {
        Write-Output "$(Get-Date) Calculating size of $_ objects..."
        AddMailboxSizes $Resources
        $TotalSize = 0
        $Resources | ForEach-Object {
            $TotalSize += $_.TotalItemSizeInGB
        }
        $esi.TotalSizeInGB = $TotalSize
    }
    $OverviewReport.Add($esi)
}

$OverviewReport

$OverviewReport.GetEnumerator() | Export-Csv 'ExchangeOverviewReport.csv' -NoTypeInformation

# $Query = [Linq.Enumerable]::ToList(([Linq.Enumerable]::Where(
#             $AllRecipientsList, [Func[PSCustomObject, bool]] { param($x); return `
#                     $x.EmailAddresses -match '' -and $x.EmailAddresses -notmatch '@' }
#         )))
        
return

function AddMailboxPermissions([List[PSCustomObject]] $Mailboxes) {
    $Mailboxes | ForEach-Object {
        $FullAccessUsers = (Get-EXOMailboxPermission $_.Identity | Where-Object { $_.User -ne "NT AUTHORITY\SELF" `
                    -and $_.AccessRights -contains 'FullAccess' -and $_.Deny -eq $False `
                    -and $_.InheritanceType -eq 'All' } | Select-Object -ExpandProperty User) -join ', '
        $_ | Add-Member -NotePropertyName FullAccessUsers -NotePropertyValue $FullAccessUsers -Force
    
        $SendAsUsers = (Get-EXORecipientPermission $_.Identity | Where-Object { $_.Trustee -ne "NT AUTHORITY\SELF" `
                    -and $_.AccessControlType -eq 'Allow' -and $_.AccessRights -contains 'SendAs' } `
            | Select-Object -ExpandProperty Trustee) -join ', '
        $_ | Add-Member -NotePropertyName SendAsUsers -NotePropertyValue $SendAsUsers -Force
    }
}

Write-Output "Adding Mailbox Permissions"
#AddMailboxPermissions $DiscoveryMailboxes
#ToDo: Others.

# $EmailQuery = 'SMTP:Chris.Dymond@domain.com'

# # Linq Query example - could be placed into function
# # contains or ccontains (for case sensitive etc)
# [Linq.Enumerable]::Where(
#     $UserMailboxes,
#     [Func[PSCustomObject, bool]] { param($x); return $x.EmailAddresses -contains $EmailQuery }
# )

# $UserMailboxes | ForEach-Object {
#     # (86,004,285 bytes)
#     #82.02 MB (86, 004, 285 bytes)
#     $bytesStartIndex = $_.TotalItemSize.Value.ToString().IndexOf('(')

#     [math]::round($_.TotalItemSize.Value.ToString().Substring($bytesStartIndex + 1, `
#                 $_.TotalItemSize.Value.ToString().Length - $bytesStartIndex - 7).Replace(',', '') / 1GB, 2)

    
# }