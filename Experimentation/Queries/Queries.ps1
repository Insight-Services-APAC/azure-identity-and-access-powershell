using namespace System.Collections.Generic

Import-Module ..\..\IA.psd1 -Force

$ErrorActionPreference = 'Stop'

$groups = Get-IAAzureADGroupsAsList -IncludeMembers:$true
$groupsWithGuests = $groups | Where-Object { $_.Users -match '#EXT#' }
$groupsWithGuests | ForEach-Object {
    $GuestUpnList = [List[String]]::new()
    for ($i = 0; $i -lt $_.Users.Count; $i++) {
        if ($_.Users[$i] -match '#EXT#') {
            # Mail is not always populated
            # chris.dymond_something.com.au#EXT#@x.onmicrosoft.com
            # chris_dymond_something.com.au#EXT#@x.onmicrosoft.com
            $sb = [System.Text.StringBuilder]::new()
            $sb.Append($_.Users[$i].Split('#')[0]) | Out-Null
            $sb[$_.Users[$i].Split('#')[0].LastIndexOf('_')] = '@'
            $GuestUpnList.Add($sb.ToString())
        }
    }
    $_.Users = $GuestUpnList
}
$groupsWithGuests | ForEach-Object {
    $_ | Select-Object DisplayName, Mail, `
    @{name = "ProxyAddresses"; expression = { $_.ProxyAddresses -join ', ' } }, `
    @{name = "Type"; expression = { $_.Type -join ', ' } }, `
        OnPremisesSyncEnabled, 
    @{name = "Owners"; expression = { $_.Owners -join ', ' } }, `
    @{name = "GuestMembers"; expression = { $_.Users -join ', ' } }
} | Export-Csv "GroupsWithGuestsFiltered$($(Get-Date).ToLocalTime().ToString('yyyyMMddTHHmmss')).csv" -NoTypeInformation
