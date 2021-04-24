# Introduction

This area intends to be a reference for assessing O365 licensing.

License type applied checks [inherited vs direct assignment] (pending)

ToDo: grouping service plan variations

# Getting Licensed Users

```powershell
$LicensedUsers = [System.Collections.Generic.Dictionary[string, Microsoft.Open.AzureAD.Model.DirectoryObject]]::new()
Get-AzureAdUser | ForEach-Object {
    $licensed = $False
    For ($i = 0; $i -le ($_.AssignedLicenses | Measure-Object).Count; $i++) 
    {
        If ( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True)
        {
             $licensed = $true
        } 
    }
    If ( $licensed -eq $true)
    {
         $LicensedUsers.Add($_.UserPrincipalName,$_)
    }
}
```

# Getting Licensing Patterns

A License Pattern consists of the unique combination of license and any disabled services.

A tenant may have many licensing patterns where licenses have been assigned manually.

i.e. An admin may assign the license 'Office 365 E3' with varying services for certain users. This results in licensing feature skew and a high number of licensing patterns. 

```powershell
$LicensePatterns = [System.Collections.Generic.Dictionary[string, int]]::new()
$LicensedUsers = [System.Collections.Generic.Dictionary[string, Microsoft.Open.AzureAD.Model.DirectoryObject]]::new()
Get-AzureAdUser -All $true | ForEach-Object {
    $Licensed = $False
    For ($i = 0; $i -le ($_.AssignedLicenses | Measure-Object).Count; $i++) {
        If ( [string]::IsNullOrEmpty(  $_.AssignedLicenses[$i].SkuId ) -ne $True) {
            $Licensed = $true
        } 
    }
    If ( $Licensed -eq $true) {
        $LicensedUsers.Add($_.UserPrincipalName, $_)
        ForEach ($License in $_.AssignedLicenses) {
            $LicensePattern = $License.SkuId
            if ($License.DisabledPlans) {
                $LicensePattern += ' DisabledPlans'
                $License.DisabledPlans = $License.DisabledPlans | Sort-Object
                $License.DisabledPLans | ForEach-Object { $LicensePattern += ';' + $_ }
            }
            $existingLicensePattern = $null
            if ($LicensePatterns.TryGetValue($LicensePattern, [ref] $existingLicensePattern) -eq $false) {
                $LicensePatterns.Add($LicensePattern, 1)
            }
            else {
                $CurrentCount = $LicensePatterns[$LicensePattern]
                $LicensePatterns[$LicensePattern] = $CurrentCount + 1
            }
        }
    }
}
```

# Get Tenant Licensing Details

Includes friendly names. I have compiled these from Microsoft Docs and licensing (as discovered).

```powershell
function Get-TenantLicensingDetails {
    <#
    .SYNOPSIS
        Returns licensing details and their friendly names.

        @Author: Chris Dymond
    .DESCRIPTION

    #>
    [CmdletBinding()]
    [OutputType([Object[]])]
    param
    (
    )
    process {
        $Licenses = Get-AzureADSubscribedSku | Select-Object -Property Sku*, `
        @{N = 'SkuFriendlyName'; E = { '' } }, `
        @{N = 'Total'; E = { $_.PrepaidUnits.'Enabled' } }, `
        @{N = 'Assigned'; E = { $_.ConsumedUnits } }, `
        @{N = 'Available'; E = { $_.PrepaidUnits.'Enabled' - $_.ConsumedUnits } }, `
        @{N = 'Suspended'; E = { $_.PrepaidUnits.'Suspended' } }, `
        @{N = 'Warning'; E = { $_.PrepaidUnits.'Warning' } }

        $SkuFriendlyNames = [System.Collections.Generic.Dictionary[string, string]]::new()
        $SkuFriendlyNames.Add('0c266dff-15dd-4b49-8397-2bb16070ed52', 'Audio Conferencing')
        $SkuFriendlyNames.Add('2b9c8e7c-319c-43a2-a2a0-48c5c6161de7', 'Azure Active Directory Basic')
        $SkuFriendlyNames.Add('078d2b04-f1bd-4111-bbd4-b4b1b354cef4', 'Azure Active Directory Premium P1')
        $SkuFriendlyNames.Add('84a661c4-e949-4bd2-a560-ed7766fcaf2b', 'Azure Active Directory Premium P2')
        $SkuFriendlyNames.Add('c52ea49f-fe5d-4e95-93ba-1de91d380f89', 'Azure Information Protection Plan 1')
        $SkuFriendlyNames.Add('ea126fc5-a19e-42e2-a731-da9d437bffcf', 'Dynamics 365 Customer Engagement Plan Enterprise Edition')
        $SkuFriendlyNames.Add('749742bf-0d37-4158-a120-33567104deeb', 'Dynamics 365 For Customer Service Enterprise Edition')
        $SkuFriendlyNames.Add('cc13a803-544e-4464-b4e4-6d6169a138fa', 'Dynamics 365 For Financials Business Edition')
        $SkuFriendlyNames.Add('8edc2cf8-6438-4fa9-b6e3-aa1660c640cc', 'Dynamics 365 For Sales and Customer Service Enterprise Edition')
        $SkuFriendlyNames.Add('1e1a282c-9c54-43a2-9310-98ef728faace', 'Dynamics 365 For Sales Enterprise Edition')
        $SkuFriendlyNames.Add('8e7a3d30-d97d-43ab-837c-d7701cef83dc', 'Dynamics 365 For Team Members Enterprise Edition')
        $SkuFriendlyNames.Add('ccba3cfe-71ef-423a-bd87-b6df3dce59a9', 'Dynamics 365 UNF OPS Plan Ent Edition')
        $SkuFriendlyNames.Add('efccb6f7-5641-4e0e-bd10-b4976e1bf68e', 'Enterprise Mobility + Security E3')
        $SkuFriendlyNames.Add('b05e124f-c7cc-45a0-a6aa-8cf78c946968', 'Enterprise Mobility + Security E5')
        $SkuFriendlyNames.Add('4b9405b0-7788-4568-add1-99614e613b69', 'Exchange Online (Plan 1)')
        $SkuFriendlyNames.Add('19ec0d23-8335-4cbd-94ac-6050e30712fa', 'Exchange Online (Plan 2)')
        $SkuFriendlyNames.Add('ee02fd1b-340e-4a4b-b355-4a514e4c8943', 'Exchange Online Archiving For Exchange Online')
        $SkuFriendlyNames.Add('90b5e015-709a-4b8b-b08e-3200f994494c', 'Exchange Online Archiving For Exchange Server')
        $SkuFriendlyNames.Add('7fc0182e-d107-4556-8329-7caaa511197b', 'Exchange Online Essentials')
        $SkuFriendlyNames.Add('e8f81a67-bd96-4074-b108-cf193eb9433b', 'Exchange Online Essentials')
        $SkuFriendlyNames.Add('80b2d799-d2ba-4d2a-8842-fb0d0f3a4b82', 'Exchange Online KIOSK')
        $SkuFriendlyNames.Add('cb0a98a8-11bc-494c-83d9-c1b1ac65327e', 'Exchange Online POP')
        $SkuFriendlyNames.Add('061f9ace-7d42-4136-88ac-31dc755f143f', 'Intune')
        $SkuFriendlyNames.Add('b17653a4-2443-4e8c-a550-18249dda78bb', 'Microsoft 365 A1')
        $SkuFriendlyNames.Add('4b590615-0888-425a-a965-b3bf7789848d', 'Microsoft 365 A3 for Faculty')
        $SkuFriendlyNames.Add('7cfd9a2b-e110-4c39-bf20-c6a3f36a3121', 'Microsoft 365 A3 for Students')
        $SkuFriendlyNames.Add('e97c048c-37a4-45fb-ab50-922fbf07a370', 'Microsoft 365 A5 for Faculty')
        $SkuFriendlyNames.Add('46c119d4-0379-4a9d-85e4-97c66d3f909e', 'Microsoft 365 A5 for Students')
        $SkuFriendlyNames.Add('cdd28e44-67e3-425e-be4c-737fab2899d3', 'Microsoft 365 Apps For Business')
        $SkuFriendlyNames.Add('b214fe43-f5a3-4703-beeb-fa97188220fc', 'Microsoft 365 Apps For Business')
        $SkuFriendlyNames.Add('c2273bd0-dff7-4215-9ef5-2c7bcfb06425', 'Microsoft 365 Apps For Enterprise')
        $SkuFriendlyNames.Add('3b555118-da6a-4418-894f-7df1e2096870', 'Microsoft 365 Business Basic')
        $SkuFriendlyNames.Add('dab7782a-93b1-4074-8bb1-0e61318bea0b', 'Microsoft 365 Business Basic')
        $SkuFriendlyNames.Add('f245ecc8-75af-4f8e-b61f-27d8114de5f3', 'Microsoft 365 Business Standard')
        $SkuFriendlyNames.Add('ac5cef5d-921b-4f97-9ef3-c99076e5470f', 'Microsoft 365 Business Standard')
        $SkuFriendlyNames.Add('cbdc14ab-d96c-4c30-b9f4-6ada7cdc1d46', 'Microsoft 365 Business Premium')
        $SkuFriendlyNames.Add('05e9a617-0261-4cee-bb44-138d3ef5d965', 'Microsoft 365 E3')
        $SkuFriendlyNames.Add('06ebc4ee-1bb5-47dd-8120-11324bc54e06', 'Microsoft 365 E5')
        $SkuFriendlyNames.Add('d61d61cc-f992-433f-a577-5bd016037eeb', 'Microsoft 365 E3_USGOV_DOD')
        $SkuFriendlyNames.Add('ca9d1dd9-dfe9-4fef-b97c-9bc1ea3c3658', 'Microsoft 365 E3_USGOV_GCCHIGH')
        $SkuFriendlyNames.Add('184efa21-98c3-4e5d-95ab-d07053a96e67', 'Microsoft 365 E5 Compliance')
        $SkuFriendlyNames.Add('26124093-3d78-432b-b5dc-48bf992543d5', 'Microsoft 365 E5 Security')
        $SkuFriendlyNames.Add('44ac31e7-2999-4304-ad94-c948886741d4', 'Microsoft 365 E5 Security for EMS E5')
        $SkuFriendlyNames.Add('66b55226-6b4f-492c-910c-a3b7a3c9d993', 'Microsoft 365 F1')
        $SkuFriendlyNames.Add('111046dd-295b-4d6d-9724-d52ac90bd1f2', 'Microsoft Defender Advanced Threat Protection')
        $SkuFriendlyNames.Add('906af65a-2970-46d5-9b58-4e9aa50f0657', 'Microsoft Dynamics CRM Online Basic')
        $SkuFriendlyNames.Add('d17b27af-3f49-4822-99f9-56a661538792', 'Microsoft Dynamics CRM Online')
        $SkuFriendlyNames.Add('ba9a34de-4489-469d-879c-0f0f145321cd', 'Microsoft Imagine Academy')
        $SkuFriendlyNames.Add('a4585165-0533-458a-97e3-c400570268c4', 'Office 365 A5 for faculty')
        $SkuFriendlyNames.Add('ee656612-49fa-43e5-b67e-cb1fdf7699df', 'Office 365 A5 for students')
        $SkuFriendlyNames.Add('1b1b1f7a-8355-43b6-829f-336cfccb744c', 'Office 365 Advanced Compliance')
        $SkuFriendlyNames.Add('4ef96642-f096-40de-a3e9-d83fb2f90211', 'Office 365 Advanced Threat Protection (Plan 1)')
        $SkuFriendlyNames.Add('18181a46-0d4e-45cd-891e-60aabd171b4e', 'Office 365 E1')
        $SkuFriendlyNames.Add('6634e0ce-1a9f-428c-a498-f84ec7b8aa2e', 'Office 365 E2')
        $SkuFriendlyNames.Add('6fd2c87f-b296-42f0-b197-1e91e994b900', 'Office 365 E3')
        $SkuFriendlyNames.Add('189a915c-fe4f-4ffa-bde4-85b9628d07a0', 'Office 365 E3 DEVELOPER')
        $SkuFriendlyNames.Add('b107e5a3-3e60-4c0d-a184-a7e4395eb44c', 'Office 365 E3_USGOV_DOD')
        $SkuFriendlyNames.Add('aea38a85-9bd5-4981-aa00-616b411205bf', 'Office 365 E3_USGOV_GCCHIGH')
        $SkuFriendlyNames.Add('1392051d-0cb9-4b7a-88d5-621fee5e8711', 'Office 365 E4')
        $SkuFriendlyNames.Add('c7df2760-2c81-4ef7-b578-5b5392b571df', 'Office 365 E5')
        $SkuFriendlyNames.Add('26d45bd9-adf1-46cd-a9e1-51e9a5524128', 'Office 365 E5 Without Audio Conferencing')
        $SkuFriendlyNames.Add('4b585984-651b-448a-9e53-3b10f069cf7f', 'Office 365 F1')
        $SkuFriendlyNames.Add('04a7fb0d-32e0-4241-b4f5-3f7618cd1162', 'Office 365 Midsize Business')
        $SkuFriendlyNames.Add('bd09678e-b83c-4d3f-aaba-3dad4abd128b', 'Office 365 Small Business')
        $SkuFriendlyNames.Add('fc14ec4a-4169-49a4-a51e-2c852931814b', 'Office 365 Small Business Premium')
        $SkuFriendlyNames.Add('e6778190-713e-4e4f-9119-8b8238de25df', 'OneDrive For Business (Plan 1)')
        $SkuFriendlyNames.Add('ed01faf2-1d88-4947-ae91-45ca18703a96', 'OneDrive For Business (Plan 2)')
        $SkuFriendlyNames.Add('b30411f5-fea1-4a59-9ad9-3db7c7ead579', 'Power Apps Per User Plan')
        $SkuFriendlyNames.Add('45bc2c81-6072-436a-9b0b-3b12eefbc402', 'Power BI For Office 365 Add-On')
        $SkuFriendlyNames.Add('f8a1db68-be16-40ed-86d5-cb42ce701560', 'Power BI Pro')
        $SkuFriendlyNames.Add('a10d5e58-74da-4312-95c8-76be4e5b75a0', 'Project For Office 365')
        $SkuFriendlyNames.Add('776df282-9fc0-4862-99e2-70e561b9909e', 'Project Online Essentials')
        $SkuFriendlyNames.Add('09015f9f-377f-4538-bbb5-f75ceb09358a', 'Project Online Premium')
        $SkuFriendlyNames.Add('2db84718-652c-47a7-860c-f10d8abbdae3', 'Project Online Premium Without Project Client')
        $SkuFriendlyNames.Add('53818b1b-4a27-454b-8896-0dba576410e6', 'Project Plan 3')
        $SkuFriendlyNames.Add('f82a60b8-1ee3-4cfb-a4fe-1c6a53c2656c', 'Project Online With Project For Office 365')
        $SkuFriendlyNames.Add('1fc08a02-8b3d-43b9-831e-f76859e04e1a', 'SharePoint Online (Plan 1)')
        $SkuFriendlyNames.Add('a9732ec9-17d9-494c-a51c-d6b45b384dcb', 'SharePoint Online (Plan 2)')
        $SkuFriendlyNames.Add('e43b5b99-8dfb-405f-9987-dc307f34bcbd', 'Skype For Business Cloud PBX')
        $SkuFriendlyNames.Add('b8b749f8-a4ef-4887-9539-c95b1eaa5db7', 'Skype For Business Online (Plan 1)')
        $SkuFriendlyNames.Add('d42c793f-6c78-4f43-92ca-e8f6a02b035f', 'Skype For Business Online (Plan 2)')
        $SkuFriendlyNames.Add('d3b4fe1f-9992-4930-8acb-ca6ec609365e', 'Microsoft 365 Domestic and International Calling Plan')
        $SkuFriendlyNames.Add('0dab259f-bf13-4952-b7f8-7db8f131b28d', 'Skype For Business PSTN Domestic Calling')
        $SkuFriendlyNames.Add('54a152dc-90de-4996-93d2-bc47e670fc06', 'Skype For Business PSTN Domestic Calling (120 Minutes)')
        $SkuFriendlyNames.Add('4b244418-9658-4451-a2b8-b5e2b364e9bd', 'Visio Plan 1')
        $SkuFriendlyNames.Add('c5928f49-12ba-48f7-ada3-0d743a3601d5', 'Visio Plan 2')
        $SkuFriendlyNames.Add('cb10e6cd-9da4-4992-867b-67546b1db821', 'Windows 10 Enterprise E3')
        $SkuFriendlyNames.Add('488ba24a-39a9-4473-8ee5-19291e71b002', 'Windows 10 Enterprise E5')
        $SkuFriendlyNames.Add('74fbf1bb-47c6-4796-9623-77dc7371723b', 'Microsoft Teams Trial')
        $SkuFriendlyNames.Add('f30db892-07e9-47e9-837c-80727f46fd3d', 'Microsoft Power Automate Free')
        $SkuFriendlyNames.Add('a403ebcc-fae0-4ca2-8c8c-7a907fd6c235', 'Power BI (free)')
        $SkuFriendlyNames.Add('dcb1a3ae-b33f-4487-846a-a640262fadf4', 'Microsoft Power Apps Plan 2 Trial')
        $SkuFriendlyNames.Add('bc946dac-7877-4271-b2f7-99d2db13cd2c', 'Forms Pro Trial')
        $SkuFriendlyNames.Add('440eaaa8-b3e0-484b-a8be-62870b9ba70a', 'Microsoft 365 Phone System - Virtual User')
        $SkuFriendlyNames.Add('e2ae107b-a571-426f-9367-6d4c8f1390ba', 'Microsoft Forms Pro USL')
        $SkuFriendlyNames.Add('1f2f344a-700d-42c9-9427-5cea1d5d7ba6', 'Microsoft Stream Trial')
        $SkuFriendlyNames.Add('de3312e1-c7b0-46e6-a7c3-a515ff90bc86', 'Telstra Calling for Office 365')
        $SkuFriendlyNames.Add('710779e8-3d4a-4c88-adb9-386c958d1fdf', 'Microsoft Teams Exploratory')
        $SkuFriendlyNames.Add('3dd6cf57-d688-4eed-ba52-9e40b5468c3e', 'Microsoft Defender for Office 365 (Plan 2)')

        foreach ($License in $Licenses) {
            $SkuFriendlyName = $null
            if ($SkuFriendlyNames.TryGetValue($License.SkuId, [ref] $SkuFriendlyName) -eq $false) {
                Write-Debug "Unknown SkuId: $SkuId"
            }
            else {
                $License.SkuFriendlyName = $SkuFriendlyName
            }
        }

        $Licenses
    }
}
```
