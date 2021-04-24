# On-Premise User Snippets

[Removing apostrophes and spacing](#ConvertTo-StringWithoutApostropheOrSpace)

[Finding an available username](#New-Username)

[Generating a complex password](#New-ComplexPassword)

[Getting an available email address](#New-Mail)

# ConvertTo-StringWithoutApostropheOrSpace

```powershell
function ConvertTo-StringWithoutApostropheOrSpace {
    <#
    .SYNOPSIS
        Removal of apostrophe character and empty space

        @Author: Chris Dymond
    .DESCRIPTION
        Removes apostrophe "'" and empty space " "
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [String] $InputString
    )
    process {
        $InputString.Replace("'", "").Replace(' ', '')
    }
}
```

# New-Username

```powershell
function New-Username {
    <#
    .SYNOPSIS
        Get an available username (sAMAccountName) from Firstname and Surname values.

        @Author: Chris Dymond
    .DESCRIPTION
        Uses the first initial of the firstname concatenated with the last name up to 20 chars.
        Uniqueness is given by appending a digit.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Firstname,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Surname
    )
    process {
        $Username = $Firstname.Substring(0, 1) + $Surname
        if ($Username.Length -gt 20) {
            $Username = $Username.Substring(0, 20)
        }
        $i = 1
        while (Get-ADUser -Filter "sAMAccountName -eq '$Username'") {
            $i++
            if ($Username.Length -eq 20) {
                $Username = $Username.Substring(0, 20 - $i.ToString().Length) + $i
            }
            else {
                $Username = $Username + $i
            }
        }
        $Username.ToLower()
    }
}
```

# New-ComplexPassword

```powershell
function New-ComplexPassword {
    <#
    .SYNOPSIS
        Complex password generation

        @Author: Chris Dymond
    .DESCRIPTION
        Returns a a complex password containing:
            Lower case letters
            Upper case letters
            Numbers
            Special characters
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNull()]
        [Int]
        $PasswordLength,

        # A validation is done here otherwise it may never meet the criteria for upper,lower etc
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateScript( { $_ -lt $PasswordLength - 2 })]
        [Int]
        $NumNonAlphaChars
    )
    process {
        # Using the .NET supplied method with customisations.
        Add-Type -AssemblyName 'System.Web'
        $ValidPassword = $false
        do {
            $GeneratedPassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $NumNonAlphaChars)
            If ($GeneratedPassword -cmatch "(?=.*\d)(?=.*[a-z])(?=.*[A-Z])") {
                $ValidPassword = $True
            }
        } While ($ValidPassword -eq $false)
        $GeneratedPassword
    }
}
```

# New-Mail

```powershell
function New-Mail {
    <#
    .SYNOPSIS
        Get an available email (mail) from a prefix and email suffix

        The suffix parameter must include '@'

        @Author: Chris Dymond
    .DESCRIPTION
        Uniqueness is given by appending a digit.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Prefix,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Suffix
    )
    process {
        $MaximumMailLength = 254 # 2 chars are reserved for '<', '>'
        $Mail = $Prefix + $Suffix
        if ($Mail.Length -gt $MaximumMailLength) {
            $CharsRemaining = $MaximumMailLength - $Suffix.Length
            $Mail = $Prefix.Substring(0, $CharsRemaining) + $Suffix
        }
        $i = 1
        while (Get-ADUser -Filter "proxyAddresses -eq 'smtp:$Mail' -or mail -eq '$Mail'") {
            $i++

            $Mail = $Prefix + $i + $Suffix
            if ($Mail.Length -gt $MaximumMailLength) {
                $CharsRemaining = $MaximumMailLength - $Suffix.Length
                $Mail = $Prefix.Substring(0, $CharsRemaining - $i.ToString().Length) + $i + $Suffix
            }
        }
        $Mail
    }
}
```
