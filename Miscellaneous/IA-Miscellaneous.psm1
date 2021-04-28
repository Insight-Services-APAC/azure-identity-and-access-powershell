# Identity and Access (IA) - Miscellaneous cmdlets
# Author: Chris Dymond
# Date: 28-04-2021
$ErrorActionPreference = "Stop"

function New-IAComplexPassword {
    <#
    .SYNOPSIS
    Create a new complex password string 
  
    .DESCRIPTION
    Returns a complex password containing:

    At least 1 lower case letter
    At least 1 upper case letter
    At least one number; and
    6 non-alpha characters.
 
    .EXAMPLE
    Without parameters the method will generate a random password 16
    characters long with 6 non-alpha characters.

    New-IAComplexPassword

    {V+y_[=)Ev_T+8fn

    New-IAComplexPassword -PasswordLength 20 -NumNonAlphaChars 10

    _*j}/QY!=5T/w^ZYD_y@

    .NOTES
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [ValidateNotNull()]
        [Int]
        $PasswordLength = 16,

        # A validation is done here otherwise it may never meet the criteria for upper, lower, number etc
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        [ValidateScript( { $_ -lt $PasswordLength - 2 })]
        [Int]
        $NumNonAlphaChars = 6
    )
    process {
        # Using the .NET supplied method with customisations.
        Add-Type -AssemblyName 'System.Web'
        $validPassword = $false
        do {
            $generatedPassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $NumNonAlphaChars)
            If ($generatedPassword -cmatch "(?=.*\d)(?=.*[a-z])(?=.*[A-Z])") {
                $validPassword = $True
            }
        } While ($validPassword -eq $false)
        $generatedPassword
    }
}
Export-ModuleMember -Function New-IAComplexPassword
