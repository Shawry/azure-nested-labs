<#
.SYNOPSIS
  The Remove-NveDataDisk function removes a data disk (or disks) from an Azure VM.

.DESCRIPTION
  This function can remove one or more data disks from an Azure VM. The caller must provide the Logical Unit
  Number (LUN) of each disk they want removed.


.NOTES
  Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

  IMPORTANT: The disks are deleted and cannot be recovered.

.LINK
  Module repo located at: TBA

.EXAMPLE
  Remove-NveDataDisk -LabName 'my_lab' -OrgCode 'dni' -LUNs 1,2,5,

  The disks attached to LUNs 1, 2 and 5 will be detached from the VM and deleted.
#>

function Remove-NveDataDisk {
  [CmdletBinding()]
  Param(

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode,

    [Parameter(Mandatory)]
    [UInt16[]]
    $LUNs
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

      # Validate $LUNs
      $Lab.ValidateDataDisks($LUNs)
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

  Commencing removal of DataDisk(s)

$hr

"@
    try {
      $VM = Get-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName
    }
    catch {
      throw "Unable to retrieve the existing VM, cannot add extra data disks."
    }
    
    $Disks = $Lab.DataDisks | Where-Object Lun -in $LUNs

    foreach($Disk in $Disks) {
      Remove-AzVmDataDisk -VM $VM -Name $Disk.Name | Out-Null
      Write-Output ("Changed DataDisk configuration: Removed LUN {0}" -f $Disk.Lun)
    }

    try {
      Update-AzVm -ResourceGroupName $Lab.ResourceGroupName -VM $VM | Out-Null
      Write-Output "DataDisk configuration was successfully updated on the Lab VM"
    }
    catch {
      Write-NveError $_ "Failed to unattach disks from the VM"
    }

    $Failures = New-Object System.Collections.Generic.List[string]

    Write-Output "Cleaning up detached disks:"
    foreach($Disk in $Disks) {
      try {
        Remove-AzDisk -ResourceGroupName $Lab.ResourceGroupName -DiskName $Disk.Name -Force | Out-Null
        Write-Output ("Disk removed: {0}" -f $Disk.Name)
      }
      catch {
        $Failures.Add($Disk.Lun)
      }
    }
    
    if($Failures) {
      throw ("Failed to remove the following disk(s): {0}" -f ($Failures -join ', '))
    }

    Write-Output @"

$hr

  Successfully removed LUN(s): $($LUNs -join ', ') from the Lab
  
$hr

"@
    
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }   
}
