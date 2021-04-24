# Azure AD

## Groups

### Get-IAAzureADGroup

Returns a list of all groups in Azure AD. A flag denotes those synchronsied from on-premise.

```powershell
    <#
    .SYNOPSIS
    Returns a list of all groups in Azure AD.

    .DESCRIPTION
    Returns the Display Name, Mail (if present), Type (Microsoft 365, Security or Distribution),
    whether the group is synchronised from on-premise and a list of group owners (where defined in Azure)

    .EXAMPLE
    Get-IAAzureADGroups

    DisplayName           : Chris' Security Group
    Mail                  :
    Type                  : Security
    OnPremisesSyncEnabled : True
    Owners                :


    DisplayName           : Chris' M365 Group
    Mail                  : ChrisGroup@domain.onmicrosoft.com
    Type                  : Microsoft 365
    OnPremisesSyncEnabled : False
    Owners                : chris.dymond@domain.com

    .NOTES

    #>
```
