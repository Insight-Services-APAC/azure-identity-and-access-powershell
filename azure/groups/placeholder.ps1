# Groups

# Cloud Only

using namespace System.Collections.Generic

try {
    Get-AzureADCurrentSessionInfo | Out-Null
}
catch [AadNeedAuthenticationException] {
    Connect-AzureAD
}

class Group {
    [string]$DisplayName
    [string]$Mail
    [string]$Type
    [string]$Owners
}

[List[Group]] $GroupList = [List[Group]]::new()

$CloudOnlyGroups = Get-AzureADMSGroup -All $true | Where-Object { $_.OnPremisesSyncEnabled -ne $true }

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


# class ConflictingGroup : Group {
#     [string]$ConflictName
# }

# [List[ConflictingGroup]] $ConflictingGroups = [List[ConflictingGroup]]::new()

# $TreasuryGroupList | ForEach-Object {
#     if ($_.Type -eq 'Microsoft 365') {
#         $MailToCheck = $_.Mail.Replace('@.onmicrosoft.com', '@.onmicrosoft.com' )
        
#         $Query = [Linq.Enumerable]::FirstOrDefault(([Linq.Enumerable]::Where($FinanceGroupList, [Func[Group, bool]] { param($x); return `
#                             $x.Mail -eq $MailToCheck }
#                 )))
#         if ($null -ne $Query) {
#             [ConflictingGroup] $Group = [ConflictingGroup]::new()
#             $Group.DisplayName = $_.DisplayName
#             $Group.Mail = $_.Mail
#             $Group.Type = $_.Type
#             $Group.Owners = $_.Owners
#             $Group.ConflictName = $MailToCheck
#             $ConflictingGroups.Add($Group)
#         }

#     }
# }

# $ConflictingGroups | Sort-Object Displayname | Export-Csv 'ConflictGroups.csv' -NoTypeInformation