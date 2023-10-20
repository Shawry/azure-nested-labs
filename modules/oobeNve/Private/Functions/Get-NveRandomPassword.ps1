<#
.SYNOPSIS
    The Get-NveRandomPassword function gets an automatically generated password (or array of passwords).

.DESCRIPTION
    The Get-NveRandomPassword function gets an automatically generated password (or array of passwords). 
    This password is generated randomly using the Get-Random PowerShell Cmdlet. The password is 17 characters 
    long, contains uppercase and lowercase letters, symbols, and numeric characters.

.PARAMETER Quantity
    Specifies the number of passwords required. Must be of type [uint32]. This parameter is optional. Default = 1

.INPUTS
    This function does not accept pipeline input.

.OUTPUTS
    This function returns the password(s) as a [string[]] object

.EXAMPLE
    Get-NveRandomPassword -Quantity 5

.EXAMPLE
    Get-NveRandomPassword

.NOTES
    Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

    Do not use the Write-Output Cmdlet within this function to output Runbook comments. This function's output is 
    intended to be stored in a $Passwords array within the caller's scope.

.LINK
    Module repo located at: TBA
#>
function Get-NveRandomPassword {

  [CmdletBinding()]
  [OutputType([string])]
  
  param (
    [Parameter()]
    [ValidateCount(1, 1000)]
    [uint32]
    $Quantity = 1
  )
  
  try {
    $Passwords = for($i = 0; $i -lt $Quantity; $i++) {

      $UpperLetters = 1..6 | ForEach-Object { [char](Get-Random -Minimum 65 -Maximum 90) }
      $LowerLetters = 1..6 | ForEach-Object { [char](Get-Random -Minimum 97 -Maximum 122) }
      $Numbers = 1..3 | ForEach-Object { [char](Get-Random -Minimum 48 -Maximum 57) }
      $Symbols = 1..2 | ForEach-Object { [char](Get-Random -Minimum 35 -Maximum 46) }

      $Password = (`
        ($UpperLetters | Select-Object -First 3) `
        + ($LowerLetters | Select-Object -First 3) `
        + $Symbols `
        + ($UpperLetters | Select-Object -Last 3) `
        + ($LowerLetters | Select-Object -Last 3) `
        + $Numbers `
      ) -join ''

      $Password
    }

    $Passwords
  }
  catch {
      Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}