class NveLab {
  [string] $LabName
  [string] $OrgCode
  [string] $ResourceGroupName
  [string] $VmName
  [string] $ResourceId
  [string] $Computername
  [string] $VmSize
  [string] $Image
  [string] $ImageReferenceId
  [string] $Version
  [Microsoft.Azure.Management.Compute.Models.DataDisk[]] $DataDisks
  [UInt16] $DataDiskCount
  [string] $IpAddress
  [string] $Location
  [string] $AdminUsername
  [string] $vCPU
  [string] $Memory
  [string] $MaxDataDiskCount

  NveLab([string] $LabName, [string] $OrgCode) {

    $this.ResourceGroupName = "nve-$OrgCode-$LabName-rg"
    $this.VmName = "vm-nve-$OrgCode-$LabName"

    try {
      $VM = Get-AzVm $this.VmName -ResourceGroupName $this.ResourceGroupName -ea Stop
    }
    catch {
      throw [NveLabNotFoundException]::New($OrgCode, $LabName)
    }

    $this.SetDetails($VM)
  }

  static [NveLab] ValidateExists ([string] $LabName, [string] $OrgCode) {

    return [NveLab]::New($LabName, $OrgCode)
  }

  [Void] SetDetails([Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM) {
    
    $this.ResourceId = $VM.Id
    $this.LabName = $VM.Tags.Lab
    $this.OrgCode = $VM.Tags.Org
    $this.Image = $VM.Tags.Image
    $this.Version = $VM.Tags.Version
    $this.Computername = $VM.OsProfile.Computername
    $this.VmSize = $VM.HardwareProfile.VmSize
    $this.Location = $VM.Location
    $this.AdminUsername = $VM.OsProfile.AdminUsername
    $this.DataDisks = $VM.StorageProfile.DataDisks
    $this.DataDiskCount = $VM.StorageProfile.DataDisks | Measure-Object | Select-Object -ExpandProperty Count

    $Id = $VM.StorageProfile.ImageReference.id
    # The leaf of the ImageReferenceId will be different if the version number was chosen explicitly on VM creation
    # ie:   /subscriptions/xxx-xxx-xxx/resourceGroups/LAB-RG/providers/Microsoft.Compute/galleries/image_gallery/images/nve-xxx-standard
    # vs    /subscriptions/xxx-xxx-xxx/resourceGroups/LAB-RG/providers/Microsoft.Compute/galleries/image_gallery/images/nve-xxx-standard/versions/1.2.0
    $this.ImageReferenceId = ( ($Id.split('/')[-1]) -match '^\d*\.\d*\.\d*$') ? $Id : ("{0}/versions/{1}" -f $Id, $VM.Tags.Version)

    try {
      $this.IpAddress = (Get-AzNetworkInterface -ResourceId $VM.NetworkProfile.NetworkInterfaces[0].id).ipconfigurations[0].privateIpAddress
    }
    catch {
      Write-NveError $_ ("IpAddress could not be found for VM:{0}." -f $VM.Name)
    }

    try {
      $VmSizeInfo = Get-AzVmSize -Location $this.Location | Where-Object Name -eq $this.VmSize
      $this.vCPU = $VmSizeInfo.NumberOfCores
      $this.Memory = ($VmSizeInfo.MemoryInMB * 1MB) / 1GB
      $this.MaxDataDiskCount = $VmSizeInfo.MaxDataDiskCount
    }
    catch {
      throw "Unable to retrieve VM Size info. Cannot validate Lab settings"
    }
  }

  [Void] ValidateDataDisks ([UInt16[]] $LUNs) {
    foreach($LUN in $LUNs) {
      if($LUN -notin $this.DataDisks.Lun) {
        throw [NveDataDiskNotFoundException]::New($LUN, $this.VmName, $this.DataDisks)
      }
    }
  }

  [Void] ValidateExtraDataDisks ([UInt16] $Quantity) {

    if(($this.DataDiskCount + $Quantity) -gt $this.MaxDataDiskCount) {
      throw [NveDataDiskExceedsMaxException]::New($Quantity, $this.VmSize, $this.Location) 
    }
  }

  [Void] ValidateVmSize ([string] $VmSize) {
    $NewSize = Get-AzVmSize -Location $this.Location | Where-Object Name -eq $VmSize

    if($VmSize -eq $this.VmSize) {
      Write-Host "Current VM Size is already $VmSize. Choose a different size"
      throw "Current VM Size is already $VmSize. Choose a different size"
    }

    if(-Not $NewSize) {
      throw [NveInvalidVmSizeException]::New($VmSize, $this.Location)
    }

    if($NewSize.MaxDataDiskCount -lt $this.DataDiskCount) {
      throw [NveInsufficientDataDiskLuns]::New($NewSize, $this.DataDiskCount, $this.Location)
    }
  }
}