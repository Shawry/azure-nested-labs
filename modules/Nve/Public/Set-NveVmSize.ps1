<#
.SYNOPSIS
  The Set-NveVmSize function will change the VM Size of a lab VM

.DESCRIPTION
  This function will change the VM Size of a lab. The lab will need to be restarted for the change to take affect.

  The caller must ensure the current lab configuration is compatible with the new VM Size SKU

.NOTES
  Author: Ryan Shaw

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error

.LINK
  Module repo located at: TBA

.EXAMPLE
  Set-NveVmSize -LabName 'my_lab' -OrgCode 'nve' -VmSize 'Standard_E32s_v5'

  The 'my_lab' VM under the 'nve' organisation will have its VM Size changed to the 'Standard_E32s_v5' SKU.
#>


function Set-NveVmSize {
  [Cmdletbinding()]
  Param (

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VmSize,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $hr = "_________________________________________________________________________________________________________"

    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)

      # Validate $VmSize
      $Lab.ValidateVmSize($VmSize)
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

  Commencing VM Resize

$hr

"@
    try {
      Write-Output "VM must be deallocated to change the VM Size."
      Stop-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Force | Out-Null
      Write-Output "VM deallocated"
    }
    catch {
      Write-NveError $_ "Unable to deallocate VM in order to change VM Size"
    }

    try {
      $VM = Get-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName
    }
    catch {
      throw "Unable to retrieve the VM after deallocation in order to set the new VM Size."
    }

    Write-Output "Changing VM configuration: VmSize: $VmSize"
    $VM.HardwareProfile.VmSize = $VmSize
    
    try {
      Update-AzVm -ResourceGroupName $Lab.ResourceGroupName -VM $VM | Out-Null
      Write-Output "VM Configuration was successfully update on the Lab VM"
    }
    catch {
      Write-NveError $_ "Unable to update the VM with the new VM Size"
    }

    try {
      Write-Output "Starting Lab VM"
      Start-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName | Out-Null
      Write-Output "VM Started"
    }
    catch {
      Write-NveError $_ "Unable to start the VM after setting the new VM Size"
    }

    Write-Output @"

$hr

  VM Resize successfully completed

$hr

"@
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  } 
}