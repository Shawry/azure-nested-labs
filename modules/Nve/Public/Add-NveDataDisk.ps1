<#
.SYNOPSIS
  The Add-NveDataDisk function adds a disk (or disks) to an Azure VM

.DESCRIPTION
  This function will attach new Premium_SSD disks to a VM. The must be enough available LUNs on the VM for
  quantity of disks provided or this functin will throw an exception.

  The disk sizes supported align to the premium managed disks standard SKU sizes. The maximum size allowed is 1024GB
  due to the limitation of the Azure Compute Gallery.

.NOTES
  Author: Ryan Shaw

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error

.LINK
  Module repo located at: TBA

.EXAMPLE
  Add-NveDataDisk -LabName 'my_lab' -OrgCode 'dev' -Quantity 3 -DiskSize 128

  This will find the lab named 'my_lab' under the organisation 'nve' then create and attach 3 x 128GB data disks to it.
#>

function Add-NveDataDisk {
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
    [UInt16]
    $Quantity,

    [Parameter(Mandatory)]
    [ValidateSet(4,8,16,32,64,128,256,512,1024)]
    [UInt16]
    $DiskSize,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $AvailableLuns = New-Object System.Collections.Generic.List[UInt32]
    $hr = "_________________________________________________________________________________________________________"

    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)

      # Validate $Quantity
      $Lab.ValidateExtraDataDisks($Quantity)
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

  Commencing adding DataDisks to Lab

$hr

"@
    try {
      $VM = Get-AzVm -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName
    }
    catch {
      throw "Unable to retrieve the existing VM, cannot add extra data disks."
    }
    
    0..($Lab.MaxDataDiskCount - 1) | Where-Object { $_ -notin $Lab.DataDisks.Lun } | Foreach-Object { $AvailableLuns.Add($_) }

    1..$Quantity | Foreach-Object {

      $Lun = $AvailableLuns[0]

      Add-AzVMDataDisk -VM $VM -Caching None -DiskSizeInGB $DiskSize -CreateOption Empty -StorageAccountType Premium_LRS -Lun $Lun | Out-Null
      Write-Output "Changed DataDisk configuration: Added $DiskSize GB DataDisk to LUN: $Lun"
      $AvailableLuns.Remove($Lun) | Out-Null
    }

    try {
      Update-AzVm -ResourceGroupName $Lab.ResourceGroupName -VM $VM | Out-Null
      Write-Output "DataDisk configuration was successfully updated on the Lab VM"
    }
    catch {
      Write-Output "Failed to update the VM with the new DataDisk additions"
      Write-NveError $_ "Failed to update the VM with the new DataDisk additions"
    }
    
    Write-Output @"

$hr

  Successfully added $Quantity DataDisk(s) to the Lab

  You will still need to bring the disk(s) online and format them from inside you Lab VM.
  Use Disk Management/DiskPart/etc for this.

$hr
"@
    
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }   
}
