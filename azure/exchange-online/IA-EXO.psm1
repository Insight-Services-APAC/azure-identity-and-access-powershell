using namespace System.Collections.Generic
$ErrorActionPreference = "Stop"
Import-Module ExchangeOnlineManagement

# Identity and Access (IA) - Additional Cmdlets for Exchange Online
# @Author: Chris Dymond

# Import-Module .\IA-EXO.psm1
#
# Get-AzureIAOnMicrosoftRecipients
# $Results = Get-AzureIAOnMicrosoftRecipients
# Disconnect-ExchangeOnline (if required)
#

function Get-AzureIAOnMicrosoftRecipients {
    <#
    .SYNOPSIS
        Returns the list of objects containing '<tenant>.onmicrosoft.com' SMTPs/proxyAddresses
        @Author: Chris Dymond
    .DESCRIPTION
    #>
    [CmdletBinding()]
    [OutputType([List[PSCustomObject]])]
    param
    (

    )
    process {
        $sessions = Get-PSSession | Select-Object -Property State, Name
        $isConnected = (@($sessions) -like '@{State=Opened; Name=ExchangeOnlineInternalSession*').Count -gt 0
        If ($isConnected -ne "True") {
            Get-PSSession | Remove-PSSession
            Write-Output "$(Get-Date) Creating Exchange Online session"
            Connect-ExchangeOnline
        }
        $resultSize = 'Unlimited'
        $exoRecipients = Get-EXORecipient -ResultSize $resultSize
        $onMicrosoftSmtpObjects = [List[PSCustomObject]]::new()

        $onMicrosoftSmtpObjects = [Linq.Enumerable]::ToList(
            [Linq.Enumerable]::Where(
                $exoRecipients, [Func[Object, bool]] { param($x); return $x.EmailAddresses -match 'onmicrosoft.com' }
            )
        )
        $onMicrosoftSmtpObjects
    }
}
Export-ModuleMember -Function Get-AzureIAOnMicrosoftRecipients


