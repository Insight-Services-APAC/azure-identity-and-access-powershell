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
        Connect-ExchangeOnline | Out-Null
    }
}

# Exported member functions

# class IAEXORemovedSIPAddressesOnMailboxResult {
#     [string]$UserPrincipalName
#     [List[string]]$RemovedSIPAddresses = [List[string]]::new()
#     [List[string]]$ResultingEmailAddresses = [List[string]]::new()
# }

# function Remove-IAEXOCustomSIPAddressesFromMailbox {
#     <#
#     .SYNOPSIS

#     This function assumes the primary SMTP has already been reverted to @tenant.onmicrosoft.com
    
#     .DESCRIPTION
    
    
#     .EXAMPLE


    
#     .NOTES
    
#     #>
#     [CmdletBinding()]
#     [OutputType([IAEXORemovedSIPAddressesOnMailboxResult])]
#     param
#     (
#         [Parameter(
#             Mandatory = $true,
#             ValueFromPipelineByPropertyName = $true,
#             Position = 0)]
#         [String] $UserPrincipalName
#     )
#     process {
#         Assert-ExchangeOnlineConnected
#         $exoMailbox = Get-EXOMailbox -UserPrincipalName $UserPrincipalName
#         [List[string]]$emailAddresses = $exoMailbox | Select-Object -ExpandProperty EmailAddresses
#         $identity = $exoMailbox | Select-Object -ExpandProperty Identity
#         $removedSIPAddresses = @()
#         $emailAddressesToApply = @()
#         $emailAddresses | ForEach-Object {
#             if ($_ -match 'sip:' -and $_ -notmatch 'onmicrosoft.com') {
#                 $removedSIPAddresses += $_ 
#             }
#             else {
#                 $emailAddressesToApply += $_
#             }
#         }
#         $result = [IAEXORemovedSIPAddressesOnMailboxResult]::new()
#         $result.UserPrincipalName = $UserPrincipalName
#         $result.RemovedSIPAddresses = $removedSIPAddresses
#         $result.ResultingEmailAddresses = $emailAddressesToApply
#         if ($removedCustomEmailAddresses.Count -gt 0) {

#             $emailAddressesToApply += 'SIP:' + $exoMailbox.PrimarySmtpAddress
            
#             #Set-Mailbox -Identity $identity -EmailAddresses $emailAddressesToApply
#             # Note that AzureAd will take a little while to sync this to its Email attribute (returning the account to @something.onmicrosoft.com)
#         }
#         $result
#     }
# }
# Export-ModuleMember -Function Remove-IAEXOCustomSIPAddressesFromMailbox

class IAEXOAddedEmailAddressesGroupResult {
    [string]$Identity
    [List[string]]$AddedEmailAddresses = [List[string]]::new()
    [List[string]]$ResultingEmailAddresses = [List[string]]::new()
}

function Add-IAEXOEmailAddressesToGroup {
    <#
    .SYNOPSIS

    
    .DESCRIPTION
    
    
    .EXAMPLE
    

    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([IAEXOAddedEmailAddressesGroupResult])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $Identity,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [List[String]] $EmailAddressList
    )
    process {
        Assert-ExchangeOnlineConnected
        $exoGroup = Get-DistributionGroup -Identity $Identity
        # A cast here prevents a single result turning into single string (which would mess up comparisons later)
        [List[string]]$emailAddresses = $exoGroup | Select-Object -ExpandProperty EmailAddresses

        $identity = $exoGroup | Select-Object -ExpandProperty Identity

        $result = [IAEXOAddedEmailAddressesGroupResult]::new()
        $result.Identity = $Identity

        [List[string]]$newEmailAddresses = [List[string]]::new()
        # Filter out addresses already there

        $EmailAddressList | ForEach-Object {
            if (($emailAddresses -cmatch $_).Count -eq 0) {
                $newEmailAddresses.Add($_)
            }
        }

        $result.AddedEmailAddresses = $newEmailAddresses

        if ($newEmailAddresses.Count -gt 0) {
            # Where a primary email address was provided, convert the current primary to a secondary
            if (($newEmailAddresses -cmatch 'SMTP:').Count -gt 0) {
                $emailAddresses = $emailAddresses -replace 'SMTP:', 'smtp:'
                # if the new primary already matches an existing secondary address then remove it
                $newPrimary = $newEmailAddresses -cmatch 'SMTP:'
                $possibleSecondary = 'smtp:' + $newPrimary.Substring(5, $newPrimary[0].Length - 5)
                $emailAddresses = $emailAddresses -cnotmatch $possibleSecondary
            }
            $emailAddresses += $newEmailAddresses
            $emailAddresses = $emailAddresses | Select-Object -Unique
            Set-DistributionGroup -Identity $Identity -EmailAddresses $emailAddresses
        }
        $result.ResultingEmailAddresses = $emailAddresses
        $result
    }
}
Export-ModuleMember -Function Add-IAEXOEmailAddressesToGroup 



class IAEXOAddedEmailAddressesMailboxResult {
    [string]$UserPrincipalName
    [List[string]]$AddedEmailAddresses = [List[string]]::new()
    [List[string]]$ResultingEmailAddresses = [List[string]]::new()
}

function Add-IAEXOEmailAddressesToMailbox {
    <#
    .SYNOPSIS
    Add email address to a mailbox (existing addresses are preserved)
    
    .DESCRIPTION
    
    
    .EXAMPLE
    
    Add-IAEXOEmailAddressesToMailbox -UserPrincipalName chris.dymond@tenant.onmicrosoft.com @('smtp:zz.test.cloud.user@somewhere.com', 'SMTP:zz.testclouduser@somewhere', ...)

    # In this example the addresses are already there so they do not appear under 'AddedEmailAddresses'

    UserPrincipalName                      AddedEmailAddresses ResultingEmailAddresses
    -----------------                      ------------------- -----------------------
    chris.dymond@tenant.onmicrosoft.com    {}                  {smtp:zz.test.cloud.user@somewhere.com', 'SMTP:zz.testclouduser@somewhere'}

    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([IAEXOAddedEmailAddressesMailboxResult])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $UserPrincipalName,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [List[String]] $EmailAddressList
    )
    process {
        Assert-ExchangeOnlineConnected
        $exoMailbox = Get-EXOMailbox -UserPrincipalName $UserPrincipalName
        [List[string]]$emailAddresses = $exoMailbox | Select-Object -ExpandProperty EmailAddresses
        $identity = $exoMailbox | Select-Object -ExpandProperty Identity

        $result = [IAEXOAddedEmailAddressesMailboxResult]::new()
        $result.UserPrincipalName = $UserPrincipalName

        $newEmailAddresses = [List[String]]::new()
        # Filter out addresses already there
        $EmailAddressList | ForEach-Object {
            if (($emailAddresses -cmatch $_).Count -eq 0) {
                $newEmailAddresses.Add($_)
            }
        }

        $result.AddedEmailAddresses = $newEmailAddresses

        if ($newEmailAddresses.Count -gt 0) {
            # Where a primary email address was provided, convert the current primary to a secondary
            if (($newEmailAddresses -cmatch 'SMTP:').Count -gt 0) {
                $emailAddresses = $emailAddresses -replace 'SMTP:', 'smtp:'
                # if the new primary already matches an existing secondary address then remove it
                $newPrimary = $newEmailAddresses -cmatch 'SMTP:'
                $possibleSecondary = 'smtp:' + $newPrimary.Substring(5, $newPrimary[0].Length - 5)
                $emailAddresses = $emailAddresses -cnotmatch $possibleSecondary
            }
            $emailAddresses += $newEmailAddresses
            $emailAddresses = $emailAddresses | Select-Object -Unique
            Set-Mailbox -Identity $identity -EmailAddresses $emailAddresses
        }
        $result.ResultingEmailAddresses = $emailAddresses
        $result
    }
}
Export-ModuleMember -Function Add-IAEXOEmailAddressesToMailbox 

class IAEXORemovedEmailAddressesOnDistributionResult {
    [string]$Identity
    [List[string]]$RemovedCustomEmailAddresses = [List[string]]::new()
    [List[string]]$ResultingEmailAddresses = [List[string]]::new()
}

function Remove-IAEXOCustomEmailAddressesFromDistribution {
    <#
    .SYNOPSIS

    
    .DESCRIPTION
    
    
    .EXAMPLE


    
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([IAEXORemovedEmailAddressesOnDistributionResult])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $Identity
    )
    process {
        Assert-ExchangeOnlineConnected
        $exoGroup = Get-DistributionGroup -Identity $Identity
        [List[string]]$emailAddresses = $exoGroup | Select-Object -ExpandProperty EmailAddresses
        $identity = $exoGroup | Select-Object -ExpandProperty Identity
        $removedCustomEmailAddresses = @()
        $emailAddressesToApply = @()
        $emailAddresses | ForEach-Object {
            if ($_ -match 'smtp:' -and $_ -notmatch 'onmicrosoft.com') {
                $removedCustomEmailAddresses += $_ 
            }
            else {
                $emailAddressesToApply += $_
            }
        }
        $result = [IAEXORemovedEmailAddressesOnDistributionResult]::new()
        $result.Identity = $Identity
        $result.RemovedCustomEmailAddresses = $removedCustomEmailAddresses
        $result.ResultingEmailAddresses = $emailAddressesToApply
        if ($removedCustomEmailAddresses.Count -gt 0) {
            if (($emailAddressesToApply -cmatch 'SMTP:').Count -eq 0) {
                # If there's no longer a primary smtp, add the first smtp instance as primary
                $firstSmtpInstance = (($emailAddressesToApply -cmatch 'smtp:')[0])
                $emailAddressesToApply += $firstSmtpInstance -creplace 'smtp:', 'SMTP:'
                $emailAddressesToApply = $emailAddressesToApply -cnotmatch $firstSmtpInstance # returns the list without the secondary address that was changed
                $result.ResultingEmailAddresses = $emailAddressesToApply
            }
            Set-DistributionGroup -Identity $identity -EmailAddresses $emailAddressesToApply
            # Note that AzureAd will take a little while to sync this to its Email attribute (returning the account to @something.onmicrosoft.com)
        }
        $result
    }
}
Export-ModuleMember -Function Remove-IAEXOCustomEmailAddressesFromDistribution


class IAEXORemovedEmailAddressesOnMailboxResult {
    [string]$UserPrincipalName
    [List[string]]$RemovedCustomEmailAddresses = [List[string]]::new()
    [List[string]]$ResultingEmailAddresses = [List[string]]::new()
}

function Remove-IAEXOCustomEmailAddressesFromMailbox {
    <#
    .SYNOPSIS
    Removes all custom domains from a mailbox recipient's email addresses
    
    .DESCRIPTION
    
    
    .EXAMPLE

    Remove-IAEXOCustomEmailAddressesFromMailbox -UserPrincipalName chris.dymond@tenant.onmicrosoft.com

    UserPrincipalName                      RemovedCustomEmailAddresses  RemainingEmailAddresses
    -----------------                      ---------------------------  -----------------------
    chris.dymond@tenant.onmicrosoft.com    {chris.dymond@somewhere.com} {SMTP:chris.dymond@tenant.onmicrosoft.com, ...}
    
    .NOTES
    
    #>
    [CmdletBinding()]
    [OutputType([IAEXORemovedEmailAddressesOnMailboxResult])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $UserPrincipalName
    )
    process {
        Assert-ExchangeOnlineConnected

        $exoMailbox = Get-EXOMailbox -UserPrincipalName $UserPrincipalName
        [List[string]]$emailAddresses = $exoMailbox | Select-Object -ExpandProperty EmailAddresses
        $identity = $exoMailbox | Select-Object -ExpandProperty Identity
        $removedCustomEmailAddresses = @()
        $emailAddressesToApply = @()
        $emailAddresses | ForEach-Object {
            if ($_ -match 'smtp:' -and $_ -notmatch 'onmicrosoft.com') {
                $removedCustomEmailAddresses += $_ 
            }
            else {
                $emailAddressesToApply += $_
            }
        }
        $result = [IAEXORemovedEmailAddressesOnMailboxResult]::new()
        $result.UserPrincipalName = $UserPrincipalName
        $result.RemovedCustomEmailAddresses = $removedCustomEmailAddresses
        $result.ResultingEmailAddresses = $emailAddressesToApply
        if ($removedCustomEmailAddresses.Count -gt 0) {
            if (($emailAddressesToApply -cmatch 'SMTP:').Count -eq 0) {
                # If there's no longer a primary smtp, add the first smtp instance as primary
                $firstSmtpInstance = (($emailAddressesToApply -cmatch 'smtp:')[0])
                $emailAddressesToApply += $firstSmtpInstance -creplace 'smtp:', 'SMTP:'
                $emailAddressesToApply = $emailAddressesToApply -cnotmatch $firstSmtpInstance # returns the list without the secondary address that was changed
                $result.ResultingEmailAddresses = $emailAddressesToApply
            }
            Set-Mailbox -Identity $identity -EmailAddresses $emailAddressesToApply
            # Note that AzureAd will take a little while to sync this to its Email attribute (returning the account to @something.onmicrosoft.com)
        }
        $result
    }
}
Export-ModuleMember -Function Remove-IAEXOCustomEmailAddressesFromMailbox

function Get-IAEXORecipientsOnMicrosoftAsList {
    <#
    .SYNOPSIS
    Returns all recipients with the @tenant.onmicrosoft.com suffix.
    
    .DESCRIPTION
    All recipients matching onmicrosoft.com are returned as a List.
    
    .EXAMPLE
    $Results = Get-IAEXORecipientsOnMicrosoftAsList
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
Export-ModuleMember -Function Get-IAEXORecipientsOnMicrosoftAsList

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




