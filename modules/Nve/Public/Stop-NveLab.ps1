<#
.SYNOPSIS
  The Stop-NveLab function stops and deallocates a Lab.

.DESCRIPTION
  This function stops and deallocates the VM resources related to a Lab. 
  This function can be run after the Budget limit is exceeded.
  
.NOTES
  Author: Ryan Shaw

.LINK
  Module repo located at: TBA

.EXAMPLE 
  Stop-NveLab -LabName 'my_lab' -OrgCode 'dev'
#>

function Stop-NveLab {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
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

  Commencing VM deallocation

$hr

"@
    $Params = @{
      ResourceGroupName = $Lab.ResourceGroupName
      ResourceType      = 'Microsoft.Compute/virtualMachines'
      Tag              = @{
        "Org" = $OrgCode
        "Lab" = $Lab.LabName
      }
    }
    $VMResource = Get-AzResource @Params

    if(-Not $VMResource) {
      throw ("Could not find a VM Resource for Lab:'{0}' and Organisational Code:'{1}}' in the ResourceGroup:'{2}'" -f $Lab.LabName, $OrgCode, $Lab.ResourceGroupName)
    }
    
    #region Deallocation
    try {
      $VMStatus = Get-AzVm -VMName $VMResource.Name -Status

      switch($VMStatus.PowerState) {
        'VM starting' { Write-Host ("VM:'{0}' currently starting. Deallocating now" -f $VMResource.Name)}
        'VM running' { Write-Host ("VM:'{0}' running. Deallocating now" -f $VMResource.Name)}
        'VM deallocating' { Write-Host ("VM:'{0}' already deallocating" -f $VMResource.Name)}
        'VM deallocated' { Write-Host ("VM:'{0}' already deallocated" -f $VMResource.Name)}
        'VM stopped' { Write-Host ("VM:'{0}' was stopped (not deallocated). Deallocating now" -f $VMResource.Name)}
        default { Write-Host ("Starting VM:'{0}'" -f $VMResource.Name) }
      }
      Stop-AzVM -ResourceGroupName $VMResource.ResourceGroupName -Name $VMResource.Name -Force | Out-Null
    }
    catch {
      Write-NveError $_ "An error occurred calling Stop-AzVM"
    }

    Write-Output @"

$hr

  VM Deallocation successful

$hr
"@
    #endregion Deallocation
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }   
}