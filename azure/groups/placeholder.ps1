# Groups

# Cloud Only

using namespace System.Collections.Generic

class Group {
    [string]$DisplayName
    [string]$Mail
    [string]$Type
    [string]$Owners
}

[List[Group]] $GroupList = [List[Group]]::new()

$CloudOnlyGroups = Get-AzureADMSGroup -All $true | Where-Object { $_.OnPremisesSyncEnabled -eq $null }

Foreach ($CloudOnlyGroup in $CloudOnlyGroups) {

    [Group] $Group = [Group]::new()

    $Group.Owners = (Get-AzureADGroupOwner -ObjectId $CloudOnlyGroup.Id -All $true | Select-Object -ExpandProperty UserPrincipalName) -join ', '
    
    $Group.DisplayName = $CloudOnlyGroup.DisplayName
    $Group.Mail = $CloudOnlyGroup.Mail

    If ($CloudOnlyGroup.GroupTypes[0] -eq "Unified") {

        $Group.Type = "Microsoft 365"

    }
    elseif ($CloudOnlyGroup.SecurityEnabled  ) {
    
        $Group.Type = "Security"  
    }
    else {
        $Group.Type = "Distribution"

    }

    $GroupList.Add($Group)
    
}

$GroupList | Sort-Object Displayname

$GroupList | Sort-Object Displayname | Export-Csv 'CloudOnlyGroups.csv' -NoTypeInformation

