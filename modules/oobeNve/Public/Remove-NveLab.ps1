<#
.SYNOPSIS
  The Remove-NveLab function removes the Azure resources related to a Lab.

.DESCRIPTION
  This function removes the Azure resources related to a Lab, including the VM, its attached disks, nic and extension resources.

  The Lab will no longer exist and cannot be recovered.

.NOTES
  Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

  IMPORTANT: The lab will nor be recoverable after this function has completed

.LINK
  Module repo located at: TBA

.EXAMPLE

  Remove-NveLab -LabName 'my_lab' -OrgCode 'dni'

  This will remove the 'my_lab' lab that belongs to the 'dni' organisation.
#>
function Remove-NveLab {

  [CmdletBinding()]

  Param(
    [Parameter(Mandatory)]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $hr = "_________________________________________________________________________________________________________"
    
    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

    Commencing Lab Removal

$hr

"@

    try {
      Write-Output ("Removing resource group:'{0}'" -f $Lab.ResourceGroupName)
      Remove-AzResourceGroup -Name $Lab.ResourceGroupName -Force | Out-Null
    }
    catch {
      Write-NveError $_ "An error occurred trying to remove the Lab"
    }

    Write-Output @"

$hr

  All resources related to the Lab:'$LabName' have been deleted.

$hr
"@
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}