using namespace System.Collections.Generic

# Return all Exchange objects referencing @<tenant>.onmicrosoft.com

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

# These objects may contain @<tenant>.onmicrosoft.com proxyAddresses
$RecipientTypeDetails = @(
    'DiscoveryMailbox',
    'EquipmentMailbox',
    'GroupMailbox',
    'LegacyMailbox',
    'LinkedMailbox',
    'LinkedRoomMailbox',
    'MailUser', # Will also assign @<tenant>.onmicrosoft addresses
    'PublicFolderMailbox',
    'RemoteEquipmentMailbox',
    'RemoteRoomMailbox',
    'RemoteSharedMailbox'
    'RemoteTeamMailbox',
    'RemoteUserMailbox',
    'RoomMailbox',
    'SchedulingMailbox',
    'SharedMailbox',
    'TeamMailbox',
    'UserMailbox'    
)

$OnMicrosoftSmtpObjects = [List[PSCustomObject]]::new()

$RecipientTypeDetails | ForEach-Object {
    $Recipients = Get-EXORecipient -ResultSize $ResultSize -RecipientTypeDetails $_
    $Recipients | ForEach-Object {
        $OnMicrosoftSmtpObjects.Add($_)
    }
}

