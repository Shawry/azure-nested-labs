class NveLabNameInUseException : System.Exception {
  [string]$LabName
  [string]$OrgCode

  NveLabNameInUseException([string] $LabName, $OrgCode) :
    base("LabName:'$LabName' is not unique. Resource Group:'nve-$OrgCode-$LabName-rg' already exists. Choose a different LabName." ) {
      $this.LabName = $LabName
      $this.OrgCode = $OrgCode
  }

  Info () {
    Write-Host ("LabName:'{0}' is not unique. Resource Group:'nve-{1}-{2}-rg' already exists. Choose a different LabName" -f $this.LabName, $this.OrgCode, $this.LabName)

    $ExistingLabs = Get-AzResourceGroup -Name ("nve-{0}-*" -f $this.OrgCode)
      
    if($ExistingLabs) {
      Write-Host "These Labs already exist:"

      foreach($ExistingLab in $ExistingLabs) {
        Write-Host ("`t {0}" -f $ExistingLab.ResourceGroupName.Split('-')[2])
      }
    }
  }
}

# class NvePreviousVersionDoesNotExistException: System.Exception {
#   [string]$ImageName

#   NvePreviousVersionDoesNotExistException([string] $ImageName) :
#     base("Invalid parameter:'PreviousVersion'. The Image:'$ImageName' only has one version, which is the latest. Do NOT set the PREVIOUSVERSION parameter to use this image.") {
#       $this.ImageName = $ImageName
#   }

#   Info() {
#     Write-Host "Invalid parameter:'PreviousVersion'. The Image:'$($this.ImageName)' only has one version, which is the latest."
#     Write-Host "Do NOT set the PREVIOUSVERSION parameter to use this image."
#   }
# }

class NveVmSizeNotSupportedException: System.Exception {
  [string]$VmSize
  [array]$SupportedSizes

  NveVmSizeNotSupportedException([string] $VmSize, [array] $SupportedSizes) :
    base("The VM size:'$VmSize' is not supported.") {
      $this.VmSize = $VmSize
      $this.SupportedSizes = $SupportedSizes
  }

  Info() {
    Write-Host "`r`nThe VM size:'$($this.VmSize)' is not supported. Choose from one of the following sizes:`r`n"

    foreach($Size in $this.SupportedSizes) {
      Write-Host ("`t {0,-16}`t - Specs: {1,2} x vCPU, {2,3}GB Memory, {3,2} Max Data Disks" -f $Size.Sku, $Size.vCPU, $Size.Memory, $Size.MaxDataDisks)
    }
  }
}

class NveVmSizeNotAvailableInRegionException: System.Exception {
  [string]$VmSize
  [string]$Location
  [array]$VmSizes

  NveVmSizeNotAvailableInRegionException([string] $VmSize, [string] $Location, [array] $VmSizes) :
    base("VM Size:'$VmSize' not found within Region:'$Location'") {
      $this.VmSize = $VmSize
      $this.Location = $Location
      $this.VmSizes = $VmSizes
  }

  Info() {
    Write-Host "The $($this.Location) region supports the following VM sizes:"

    foreach($ApprovedVmSize in $this.VMSizes) {
      Write-Host "`t $($ApprovedVmSize.Name)"
    }
  }
}

class NveLabNotFoundException: System.Exception {
  [string]$OrgCode
  [string]$LabName

  NveLabNotFoundException([string] $OrgCode, [string] $LabName) :
    base("Cannot find a Resource Group of:'nve-$OrgCode-$LabName-rg' using LabName:'$LabName'and Organisational Code:'$OrgCode'") {
      $this.OrgCode = $OrgCode
      $this.LabName = $LabName
  }

  Info() {
    Write-Output ("Cannot find a Resource Group of:'nve-{0}-{1}-rg' using LabName:'{1}'and Organisational Code:'{0}'" -f $this.OrgCode, $this.LabName)

    $ExistingLabs = Get-AzResourceGroup -Name ("nve-{0}-*" -f $this.OrgCode)
    
    if($ExistingLabs) {
      Write-Output "`r`nThese are the Labs that are available:"

      foreach($ExistingLab in $ExistingLabs) {
        Write-Output ("`t {0}" -f $ExistingLab.ResourceGroupName.Split('-')[2]) 
      }
    }
  }
}

class NveDataDiskExceedsMaxException: System.Exception {
  [string] $VmSize
  [string] $Location
  
  NveDataDiskExceedsMaxException([UInt16] $Quantity, [string] $VmSize, [string] $Location) :
    base("Additional $Quantity data disks exceeds the maximum allowed for VmSize: $VmSize") {
      $this.VmSize = $VmSize
      $this.Location = $Location
  }

  Info() {
    $SupportedSizes = Get-AzVmSize -Location $this.Location | Where-Object Name -match '^Standard_[DE]\d*s_v5'

    Write-Host "`r`nDetailed below are the supported VM Sizes and their max data disk values."
    Write-Host "If you need more data disks you should upgrade the VmSize to a suitable SKU first.`r`n"

    foreach($Size in $SupportedSizes) {
      Write-Host ("`t VM Size: {0,-16} - MaxDataDisks: {1,2}, vCPUs: {2,3}, Memory: {3,3}GB" -f $Size.Name, $Size.MaxDataDiskCount, $Size.NumberOfCores, (($Size.MemoryInMB * 1MB) / 1GB))
    }
  }
}

class NveDataDiskNotFoundException: System.Exception {
  [string] $VmName
  [Microsoft.Azure.Management.Compute.Models.DataDisk[]] $DataDisks
  
  NveDataDiskNotFoundException([UInt16] $LUN, [string] $VmName, [Microsoft.Azure.Management.Compute.Models.DataDisk[]] $DataDisks) :
    base("LUN: $LUN not found on VM: $VmName") {
      $this.VmName = $VmName
      $this.DataDisks = $DataDisks
  }

  Info() {
    Write-Host ("`r`nThe VM: {0} has the following DataDisks available:" -f $this.VmName)

    foreach ($Disk in $this.DataDisks) {
      Write-Host ("LUN: {0,-2}" -f $Disk.Lun)
    }

    Write-Host "`r`nConfirm the LUN using Disk Management on the Host VM"
  }
}

class NveInvalidVmSizeException : System.Exception {
  [string] $Location
  [string] $VmSize
  
  NveInvalidVmSizeException([string] $VmSize, [string] $Location) :
    base("The VM Size: $VmSize is not valid for the Azure region: $Location") {
      $this.Location = $Location
      $this.VmSize = $VmSize
  }

  Info() {
    try {
      $SupportedSizes = Get-AzVmSize -Location $this.Location -ea Stop | Where-Object Name -match '^Standard_[DE]\d*s_v5$'

      Write-Host "`r`nYou must use one of the following supported sizes:"

      foreach($Size in $SupportedSizes) {
        Write-Host ("`t VM Size: {0,-16} - MaxDataDisks: {1,2}, vCPUs: {2,3}, Memory: {3,3}GB" -f $Size.Name, $Size.MaxDataDiskCount, $Size.NumberOfCores, (($Size.MemoryInMB * 1MB) / 1GB))
      }
    }
    catch {
      Write-Host ("VM Size: [0} not supported in Azure region: {1}. Unable to show supported sizes. {2}`r`n" -f $this.VmSize, $this.Location, $PSitem)
    }
  }
}

class NveInsufficientDataDiskLuns : System.Exception {
  [UInt16] $DataDiskCount
  [string] $Location
  [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineSize] $NewSize
  
  NveInsufficientDataDiskLuns([Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineSize] $NewSize, [UInt16] $DataDiskCount, [string] $Location) :
    base("The VM Size: $NewSize does not have enough capacity to house the existing $DataDiskCount Data Disks.") {
      $this.DataDiskCount = $DataDiskCount
      $this.NewSize = $NewSize
      $this.Location = $Location
  }

  Info() {
    try {
      $SupportedSizes = Get-AzVmSize -Location $this.Location -ea Stop | Where-Object Name -match '^Standard_[DE]\d*s_v5$' | Where-Object MaxDataDiskCount -ge $this.DataDiskCount
      Write-Host ("`r`nYou must use one of the following supported sizes to house the {0} Data Disks attached to your Lab:`r`n" -f $this.DataDiskCount)

      foreach($Size in $SupportedSizes) {
        Write-Host ("`t VM Size: {0,-16} - MaxDataDisks: {1,2}, vCPUs: {2,3}, Memory: {3,3}GB" -f $Size.Name, $Size.MaxDataDiskCount, $Size.NumberOfCores, (($Size.MemoryInMB * 1MB) / 1GB))
      }
    }
    catch {
      Write-Host ("The VM Size: {0} only has {1} available slots for Data Disks, whereas you need {2}. Unable to show more appropriate sizes. {3}" -f $this.NewSize, $this.NewSize.MaxDataDiskCount, $this.DataDiskCount, $PSitem)
    }
  }
}

class NveImageDefinitionAlreadyExistsException : System.Exception {
  [string] $ImageDefinition
  [string] $GalleryRgName
  [string] $GalleryName
  
  NveImageDefinitionAlreadyExistsException([string] $ImageDefinition, [string] $GalleryRgName, [string] $GalleryName) :
    base("The Image Definition name:'$ImageDefinition' already exists within the '$GalleryName' image gallery") {
      $this.ImageDefinition = $ImageDefinition
      $this.GalleryRgName = $GalleryRgName
      $this.GalleryName = $GalleryName
  }

  Info() {
    
    try {
      $ImageDefinitions = Get-AzGalleryImageDefinition -ResourceGroupName $this.GalleryRgName -GalleryName $this.GalleryName
      Write-Host "`r`nDetailed below are the existing Image Definitions:`r`n"

      foreach ($Image in $ImageDefinitions) {
        Write-Host ("`t Name: {0}-{1}-{2}  | Publisher: {0}, Offer: {1}, SKU: {2}" -f $Image.Identifier.Publisher, $Image.Identifier.Offer, $Image.Identifier.SKU)
      }
    }
    catch {
      Write-Host ("The Image Definition name:'{0}' already exists within the image gallery:'{1}'" -f $this.ImageDefinition, $this.GalleryName)
      Write-Host ("`r`nUnable to show existing Images from Gallery:'{0}' in Resource Group:'{1}'" -f $this.GalleryName, $this.GalleryRgName)
    }
  }
}

class NveImageDefinitionDoesNotExistException : System.Exception {
  [string] $ImageDefinition
  [string] $GalleryRgName
  [string] $GalleryName
  
  NveImageDefinitionDoesNotExistException([string] $ImageDefinition, [string] $GalleryRgName, [string] $GalleryName) :
    base("The Image Definition name:'$ImageDefinition' does not exist within the '$GalleryName' image gallery") {
      $this.ImageDefinition = $ImageDefinition
      $this.GalleryRgName = $GalleryRgName
      $this.GalleryName = $GalleryName
  }

  Info() {
    
    try {
      $ImageDefinitions = Get-AzGalleryImageDefinition -ResourceGroupName $this.GalleryRgName -GalleryName $this.GalleryName
      Write-Host "`r`nDetailed below are the existing Image Definitions:`r`n"

      foreach ($Image in $ImageDefinitions) {
        Write-Host ("`t Name: {0}-{1}-{2}  | Publisher: {0}, Offer: {1}, SKU: {2}" -f $Image.Identifier.Publisher, $Image.Identifier.Offer, $Image.Identifier.SKU)
      }
    }
    catch {
      Write-Host ("The Image Definition name:'{0}' does not exisr within the image gallery:'{1}'" -f $this.ImageDefinition, $this.GalleryName)
      Write-Host ("`r`nUnable to show existing Images from Gallery:'{0}' in Resource Group:'{1}'" -f $this.GalleryName, $this.GalleryRgName)
    }
  }
}

class NveImageDisksExceedsMaxException: System.Exception {
  [string] $VmSize
  [string] $Location
  
  NveImageDisksExceedsMaxException([UInt16] $Quantity, [string] $VmSize, [string] $Location) :
    base("The Image has $Quantity data disks, which exceeds the maximum allowed for VmSize: $VmSize") {
      $this.VmSize = $VmSize
      $this.Location = $Location
  }

  Info() {
    $SupportedSizes = Get-AzVmSize -Location $this.Location | Where-Object Name -match '^Standard_[DE]\d*s_v5'

    Write-Host "`r`nDetailed below are the supported VM Sizes and their max data disk values."
    Write-Host "You must select a suitable VM Size to handle the number of data disks required by your lab.`r`n"

    foreach($Size in $SupportedSizes) {
      Write-Host ("`t VM Size: {0,-16} - MaxDataDisks: {1,2}, vCPUs: {2,3}, Memory: {3,3}GB" -f $Size.Name, $Size.MaxDataDiskCount, $Size.NumberOfCores, (($Size.MemoryInMB * 1MB) / 1GB))
    }
  }
}