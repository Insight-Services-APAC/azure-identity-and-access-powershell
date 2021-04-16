# Getting service principals that have at least a user or other service principal assignment
# Useful for finding in use SPs
# Chris Dymond

# TODO: CSV Output and proofing

class ServiceAppRoleAssignments {
    [string]$ResourceId
    [string]$ResourceDisplayName
    [string]$ResourceType
    [string]$AssignedUserPrincipalNames
    [string]$AssignedOtherPrincipalNames
    [string]$AssignedPrincipalTypes
}

#[List[ServiceAppRoleAssignments]] $ServicePrincipals = [List[ServiceAppRoleAssignments]]::new()

Get-AzureADServicePrincipal -All $true | Where-Object {$_.AccountEnabled -eq $true}  | ForEach-Object {
    [ServiceAppRoleAssignments] $ServiceAppRoleAssignments = [ServiceAppRoleAssignments]::new()
    $ServiceAppRoleAssignments.ResourceId = $_.ObjectId
    $ServiceAppRoleAssignments.ResourceType = $_.ObjectType
    $ServiceAppRoleAssignments.ResourceDisplayName = $_.DisplayName
    $ServiceAppRoleAssignment = $_ | Get-AzureADServiceAppRoleAssignment 

    $UserPrincipals = $ServiceAppRoleAssignment | Where-Object {$_.PrincipalType -eq 'User'} | Select-Object PrincipalId
    $UserPrincipalNames = @();
    $UserPrincipals | ForEach-Object {
        $UserPrincipalName = Get-AzureADUser -ObjectId $_.PrincipalId | Select-Object UserPrincipalName
        $UserPrincipalNames += $UserPrincipalName
    }
    $ServiceAppRoleAssignments.AssignedOtherPrincipalNames = ($ServiceAppRoleAssignment | Where-Object {$_.PrincipalType -ne 'User'} | Select-Object -ExpandProperty PrincipalDisplayName ) -join ', '
    $ServiceAppRoleAssignments.AssignedUserPrincipalNames = ($UserPrincipalNames | Select-Object -ExpandProperty UserPrincipalName) -join ', '
    $ServiceAppRoleAssignments.AssignedPrincipalTypes = ($ServiceAppRoleAssignment | Select-Object -Unique -ExpandProperty PrincipalType) -join ', '
    if ($ServiceAppRoleAssignments.AssignedUserPrincipalNames -ne '' -or $ServiceAppRoleAssignments.AssignedOtherPrincipalNames -ne '' ) {
        $ServiceAppRoleAssignments
    }
}
