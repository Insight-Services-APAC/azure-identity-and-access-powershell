# Identity and Access (IA) - Additional cmdlets for Exchange Online
# Author: Chris Dymond
# Date: 23-04-2021

# TODO: CSV output cmdlet

using namespace System.Collections.Generic
$ErrorActionPreference = "Stop"

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

function Get-IAEXORecipientsOnMicrosoft {
    <#
    .SYNOPSIS
    Returns all recipients with the @tenant.onmicrosoft.com suffix.
    
    .DESCRIPTION
    All recipients matching onmicrosoft.com are returned as a List.
    
    .EXAMPLE
    $Results = Get-IAEXORecipientsOnMicrosoft
    $Results

    ...
    ExternalDirectoryObjectId : ...
    Identity                  : Chris Dymond
    Alias                     : Chris.Dymond
    EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
    DisplayName               : Chris Dymond
    Name                      : Chris Dymond
    PrimarySmtpAddress        : Chris.Dymond@domain.com
    RecipientType             : UserMailbox
    RecipientTypeDetails      : UserMailbox
    ExchangeVersion           : 0.20 (15.0.0.0)
    DistinguishedName         : CN=...
    OrganizationId            : ...
    ...
    
    .NOTES
    
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
Export-ModuleMember -Function Get-IAEXORecipientsOnMicrosoft

class IARecipients {
    [string]$CombinedSizeInGB
    [List[PSCustomObject]]$Recipients = [List[PSCustomObject]]::new()
}

function Get-IAEXORecipientsAsDictionary {
    <#
    .SYNOPSIS
    Retrives all recipients on the connected Exchange Online environment.
    
    .DESCRIPTION
    All returned recipients will be grouped by their type.

    ie. Where Exchange Online contains Room Mailboxes, Mail Users and User Mailboxes;
    You will see an object returned with these keys.
    
    .EXAMPLE
    $Results = Get-IAEXORecipientsAsDictionary
    $Results

    Key                            Value
    ---                            -----
    UserMailbox                    IARecipients
    RoomMailbox                    IARecipients
    MailUsers                      IARecipients

    $Results['UserMailbox']


    CombinedSizeInGB Recipients
    ---------------- ----------
    725.87           {@{ExternalDirectoryObjectId=....


    $Results['UserMailbox'].Recipients

    ...
    ExternalDirectoryObjectId : 
    Identity                  : Chris Dymond
    Alias                     : Chris.Dymond
    EmailAddresses            : {SPO:SIP:SMTP.mail.onmicrosoft.com...}
    DisplayName               : Chris Dymond
    Name                      : Chris Dymond
    PrimarySmtpAddress        : Chris.Dymond@domain.com
    RecipientType             : UserMailbox
    RecipientTypeDetails      : UserMailbox
    ExchangeVersion           : 0.20 (15.0.0.0)
    DistinguishedName         : CN=
    OrganizationId            : 
    TotalItemSize             : 1.243 GB (1,334,578,302 bytes)
    TotalItemSizeInGB         : 1.24
    ...
    
    .NOTES
    
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




