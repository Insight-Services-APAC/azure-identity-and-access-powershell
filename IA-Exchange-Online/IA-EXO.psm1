# Identity and Access (IA) - Additional cmdlets for Exchange Online
#
# Import-Module .\IA-EXO.psm1
#
# Author: Chris Dymond
# Date: 23-04-2021

# TODO: CSV output cmdlet

using namespace System.Collections.Generic
$ErrorActionPreference = "Stop"
Import-Module ExchangeOnlineManagement

# Private member functions
function Assert-ExchangeOnlineConnected {
    $sessions = Get-PSSession | Select-Object -Property State, Name
    $isConnected = (@($sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
    If ($isConnected -ne $True) {
        Get-PSSession | Remove-PSSession
        Connect-ExchangeOnline
    }
}

# Exported member functions

function Get-IAEXOOnMicrosoftRecipients {
    <#
    .SYNOPSIS
        Returns the list of objects containing '<tenant>.onmicrosoft.com'
        @Author: Chris Dymond
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([List[PSCustomObject]])]
    param
    (

    )
    process {
        Assert-ExchangeOnlineConnected
        $exoRecipients = Get-EXORecipient -ResultSize Unlimited
        $onMicrosoftSmtpObjects = [List[PSCustomObject]]::new()
        $onMicrosoftSmtpObjects = [Linq.Enumerable]::ToList(
            [Linq.Enumerable]::Where(
                $exoRecipients, [Func[Object, bool]] { param($x); return $x.EmailAddresses -match 'onmicrosoft.com' }
            )
        )
        $onMicrosoftSmtpObjects
    }
}
Export-ModuleMember -Function Get-IAEXOOnMicrosoftRecipients

class IARecipients {
    [string]$CombinedSizeInGB
    [List[PSCustomObject]]$Recipients = [List[PSCustomObject]]::new()
}

function Get-IAEXORecipientsAsDictionary {
    <#
    .SYNOPSIS
        Returns Exchange Online recipients organised by type with mailbox sizes calculated (where applicable)
        Keys of the returned dictionary object refer to the item type ie. UserMailbox, SharedMailbox etc
        @Author: Chris Dymond
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([Dictionary[String, IARecipients]])]
    param
    (

    )
    process {
        Assert-ExchangeOnlineConnected
        $recipientsDictionary = [Dictionary[String, IARecipients]]::new()
        $exoRecipients = Get-EXORecipient -ResultSize Unlimited
        #Adding Mailbox Sizes in GB (where applicable)
        $exoRecipients | ForEach-Object {
            if ($_.RecipientTypeDetails -match 'mailbox') {
                # Preferencing lookup on GUID
                if ($_.ExternalDirectoryObjectId) {
                    $stats = Get-EXOMailboxStatistics -ExchangeGuid $_.ExternalDirectoryObjectId
                }
                else {
                    $stats = Get-EXOMailboxStatistics -Identity $_.Identity
                }
                $bytesStartIndex = $stats.TotalItemSize.Value.ToString().IndexOf('(')
                $_ | Add-Member -NotePropertyName TotalItemSize -NotePropertyValue $stats.TotalItemSize

                $sizeInGB = [Math]::Round($_.TotalItemSize.Value.ToString().Substring($bytesStartIndex + 1, `
                            $_.TotalItemSize.Value.ToString().Length - $bytesStartIndex - 7).Replace(',', '') / 1GB, 2)
                $_ | Add-Member -NotePropertyName TotalItemSizeInGB -NotePropertyValue $sizeInGB
            }
        }
        # Each key refers to the type of object UserMailbox, SharedMailbox etc
        $exoRecipients | ForEach-Object {
            if ($recipientsDictionary.ContainsKey($_.RecipientTypeDetails)) {
                $recipientsDictionary[$_.RecipientTypeDetails].Recipients.Add($_)
            }
            else {
                $recipientGroup = [IARecipients]::new()
                $recipientGroup.Recipients.Add($_)
                $recipientsDictionary.Add($_.RecipientTypeDetails, $recipientGroup)
            }
        }
        # Combine sizes ie. UserMailbox total xGB, SharedMailbox total xGB
        $recipientsDictionary.Keys | ForEach-Object {
            $totalSize = 0
            $recipientsDictionary[$_].Recipients | ForEach-Object {
                $totalSize += $_.TotalItemSizeInGB
            }
            $recipientsDictionary[$_].CombinedSizeInGB = $totalSize
        }
        $recipientsDictionary
    }
}
Export-ModuleMember -Function Get-IAEXORecipientsAsDictionary




