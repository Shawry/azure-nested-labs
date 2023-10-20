<#
.SYNOPSIS
  The New-NveLab function creates a new Lab.

.DESCRIPTION
  This function creates a Lab based off an Azure Compute Gallery Image. 
  
  A new Resource Group is created for each Lab. The Resource Group looks like this: nve-<OrgCode>-<LabName>-rg.
  The lab VM will have an auto shutdown schedule associated to it, which is configurable using the $AllocatedHours
  parameter.

  See below for details on each parameter.

.PARAMETER OrgCode
  Type: [string]
  An organisational code that separates the resources into distinguishable groups

.PARAMETER LabName
  Type: [string]
  The unique lab name for the Lab. This must be uniqie to the organisation (OrgCode) detailed above.
  This is used to manage the lab throughout its lifetime

.PARAMETER Username 
  Type: [string]
  The username for the admin account to be created on each VM during VM provisioning.

.PARAMETER VmSize  
  Type: [string]
  The VM size that the Lab VMs will be created as. 
  
  Use the following Command to view available sizes: 

    Get-AzVmSize -Location '<intended location>'     

.PARAMETER Location 
  Type: [string]
  The Azure location where the Labs will be created.

  This parameter can either be the display name (eg 'Australia East') or the location code (eg 'australiaeast') 
  The location must be one of the Australian regions. 
  
  Use the following Command to view a list of locations:

    Get-AzLocation | Where-Object DisplayName -match '^Australia\s\w'    

.PARAMETER ImageName 
  Type: [string]
  The Image Defintion name of an Azure Compute Gallery Image. 

  Use the following command to view the available Images: 
    
    Get-AzGalleryImageDefinition -ResourceGroupName $Gallery.ResourceGroupName -GalleryName $Gallery.Name 

.PARAMETER GalleryName 
  Type: [string]
  The Azure Compute Gallery name that stores the various Image Definitions.

  Use the following command to view the list of available galleries:

    Get-AzGallery

.PARAMETER GalleryRgName
  Type: [string]
  The Resource Group where the Azure Compute Gallery provided in the GalleryName parameter is located.

.PARAMETER SubnetName 
  Type: [string]
  The Subnet name where the NICs on each Lab's VM should be added to.

  Use the following command to view a list of available subnets:

    Get-AzVirtualNetwork -Name '<VNet name>' | select Subnets

.PARAMETER VnetName 
  Type: [string]
  The Virtual Network name where the Subnet for the VMs is hosted.

.PARAMETER VnetRg  
  Type: [string]
  The Resource Group where the Virtual Network for hosting the VMs resides.

.PARAMETER NicNsgName 
  Type: [string]
  The Network Security Group used to attach to the VM NICs.

.PARAMETER NicNsgRg 
  Type: [string]
  The Resource Group where the NSG for the NICs is hosted.

.PARAMETER AllocatedHours
  Type: UInt16
  Designated how many hours into the future the auto shutdown schedule is set to.

  Must be between 1 and 23 

.PARAMETER BastionName
  Type: [string]
  Provide the name of the Bastion used to access the lab VMs. The Bastion must be configured correctly
  to access the labs.

.PARAMETER BastionRg
  Type: [string]
  The resource group name of the Bastion detailed above.

.PARAMETER BudgetName
  Type: [string]
  The name of the budget you wish to manage the labs with. If the budget limit is exceeded this runbook will not run.

  The deallocation of VM resources when the budget limit is reached should be handled separately. This module does not
  conduct any action group shutdown tasks. You need to create a separate automation account and runboook for this.

.PARAMETER AccessGroupId
  Type: [string]
  This is the Azure AD group ResourceID that all lab users must belong to. This group is given Reader acces to the various 
  Resource Groups that are created during lab provisioning.

.PARAMETER TemplatesContainer
  Type: [string]
  The storage blob container used to host the ARM templates.

.PARAMETER StorageContext
  Type: [string]    
  The Context property of a PSStorageAccount. Used to access storage account resources, such as storage blob containers.

.EXAMPLE
  
  $StorageContext = New-AzStorageContext -StorageAccountName 'stnveproddata001' -UseConnectedAccount

  $Params = @{
      OrgCode             = 'dni'
      LabName             = 'my_lab'     
      Username            = 'labadmin'
      VmSize              = 'Standard_D8s_v5'
      Location            = 'Australia East'
      ImageName           = 'dni-baseline-standard'
      GalleryName         = 'Defence_and_Intel_Image_Gallery'
      GalleryRgName       = 'rg-nve-prod-aue-001'
      SubnetName          = 'snet-nve-prod-aue-001'
      VnetName            = 'vnet-nve-prod-aue-001'
      VnetRg              = 'rg-net-prod-aue-001'
      NicNsgName          = 'nsg-nvenicprod-001'
      NicNsgRg            = 'rg-net-prod-aue-001'
      StorageContext      = $StorageContext
      TemplatesContainer  = 'templates'
      AllocatedHours      = 4
      BudgetName          = 'budget-monthly-defence-non-prod'
      BastionName         = 'bas-nve-prod-aue-001'
      BastionRg           = 'rg-net-prod-aue-001'
      AccessGroupId       = 'd52bac22-c43d-468f-9b74-07ed2d3f8f48'
  }
  New-NveLab @Params
  
.NOTES
  Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error

.LINK
  Azure DevOps repo: https://dev.azure.com/oobe-lab/oobeLab/_git/NVE
#>
function New-NveLab {

  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateLength(3,15)]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $TemplatesContainer,

    [Parameter(Mandatory)]
    [Microsoft.WindowsAzure.Commands.Storage.AzureStorageContext]
    $StorageContext,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryRgName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ImageName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VmSize,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Location,

    [Parameter(Mandatory)]
    [ValidateLength(3,15)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Username,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SubnetName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VnetName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $VnetRg,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $NicNsgName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $NicNsgRg,

    [Parameter(Mandatory)]
    [ValidateRange(1,23)]
    [UInt16]
    $AllocatedHours,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BastionName,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BastionRg,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AccessGroupId
  )
  $ErrorActionPreference = 'Stop'
  
  try {
    $ShutDownTime = (Get-Date).AddHours($AllocatedHours).ToString('hh:mm')
    $TimeZoneId = 'UTC'
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $SubscriptionId = Get-AzContext | ForEach-Object { $_.Subscription.Id }
    $hr = "_________________________________________________________________________________________________________"
    
    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName
      $Exists = Get-AzResourceGroup -Name "nve-$OrgCode-$LabName-rg" -ea SilentlyContinue
      
      if($Exists) {
        throw [NveLabNameInUseException]::New($LabName, $OrgCode) 
      }

      if($LabName -notmatch '^[a-z0-9_]{1,15}$') {
        Write-Output "The LABNAME argument is invalid. LABNAME must only contain characters a-z, digits 0-9, and underscores"
        throw "The LABNAME argument is invalid. LABNAME must only contain characters a-z, digits 0-9, and underscores"
      }

      # Validate $GalleryName, $GalleryRgName
      try {
        $Gallery = Get-AzGallery -Name $GalleryName -ResourceGroupName $GalleryRgName
      }
      catch {
        Write-NveError $_ "The Gallery:'$GalleryName' was not found in Resource Group:'$GalleryRgName'. Seek admin help for this error"
      }

      # Validate $BastionName, $BastionRg
      try {
        Get-AzBastion -ResourceGroupName $BastionRg -Name $BastionName | Out-Null
      }
      catch {
        Write-Output "An error occurred with the Bastion Resource. Seek admin help for this error"
        Write-NveError $_ "An error occurred with the Bastion Resource. Seek admin help for this error"
      }

      # Validate $ImageName
      try {
        $Params = @{
          ResourceGroupName           = $GalleryRgName
          GalleryName                 = $GalleryName
          GalleryImageDefinitionName  = $ImageName
        }
        Get-AzGalleryImageDefinition @Params | Out-Null
      }
      catch {

        $AvailableImageDefinitions = Get-AzGalleryImageDefinition -ResourceGroupName $GalleryRgName -GalleryName $GalleryName | Select-Object -ExpandProperty Name

        if($AvailableImageDefinitions) {
          Write-Output "Select from one of these Image Definitions:"

          foreach($ImageDefinition in $AvailableImageDefinitions) {
            Write-Output "`t $ImageDefinition"
          }
        } 
        else {
          Write-Host "There are no Image Definitions in the Gallery. Seek admin help to rectify this."
        }
        
        Write-NveError $_ "ImageName:'$ImageName' invalid. Gallery:'$GalleryName' does not contain an Image with this name."
      }
    
      # Validate $VmSize
      $SupportedSizes = @(
        # General Purpose
        @{ Sku = 'Standard_D2s_v5';  vCPU = 2;   Memory = 8;   MaxDataDisks = 4 }
        @{ Sku = 'Standard_D4s_v5';  vCPU = 4;   Memory = 16;  MaxDataDisks = 8 }
        @{ Sku = 'Standard_D8s_v5';  vCPU = 8;   Memory = 32;  MaxDataDisks = 16 }
        @{ Sku = 'Standard_D16s_v5'; vCPU = 16;  Memory = 64;  MaxDataDisks = 32 }
        @{ Sku = 'Standard_D32s_v5'; vCPU = 32;  Memory = 128; MaxDataDisks = 32 }
        @{ Sku = 'Standard_D48s_v5'; vCPU = 48;  Memory = 192; MaxDataDisks = 32 }
        @{ Sku = 'Standard_D64s_v5'; vCPU = 64;  Memory = 256; MaxDataDisks = 32 }
        @{ Sku = 'Standard_D96s_v5'; vCPU = 96;  Memory = 384; MaxDataDisks = 32 }
        # Memory Optimised
        @{ Sku = 'Standard_E2s_v5';  vCPU = 2;   Memory = 16;  MaxDataDisks = 4 }
        @{ Sku = 'Standard_E4s_v5';  vCPU = 4;   Memory = 32;  MaxDataDisks = 8 }
        @{ Sku = 'Standard_E8s_v5';  vCPU = 8;   Memory = 64;  MaxDataDisks = 16 }
        @{ Sku = 'Standard_E16s_v5'; vCPU = 16;  Memory = 128; MaxDataDisks = 32 }
        @{ Sku = 'Standard_E20s_v5'; vCPU = 20;  Memory = 160; MaxDataDisks = 32 }
        @{ Sku = 'Standard_E32s_v5'; vCPU = 32;  Memory = 256; MaxDataDisks = 32 }
        @{ Sku = 'Standard_E48s_v5'; vCPU = 48;  Memory = 384; MaxDataDisks = 32 }
        @{ Sku = 'Standard_E64s_v5'; vCPU = 64;  Memory = 512; MaxDataDisks = 32 }
        @{ Sku = 'Standard_E96s_v5'; vCPU = 96;  Memory = 672; MaxDataDisks = 32 }
      )

      if($VmSize -notin $SupportedSizes.Sku) {
        throw [NveVmSizeNotSupportedException]::New($VmSize, $SupportedSizes)
      }

      $VmSizes = Get-AzVmSize -Location $Location
      if($VmSize -notin $VmSizes.Name) { 
        throw [NveVmSizeNotAvailableInRegionException]::New($VmSize, $Location, $VmSizes)
      }

      # Can the VM Size support the number of DataDisks the Image has
      $LatestImage = Get-AzGalleryImageVersion -ResourceGroupName $GalleryRgName -GalleryName $GalleryName -GalleryImageDefinition $ImageName `
        | Where-Object { $_.PublishingProfile.ExcludeFromLatest -eq $false }  `
        | Sort-Object Name -Descending | Select-Object -First 1

      $DiskCount = $LatestImage.StorageProfile.DataDiskImages.Count
      $VmSizeInfo = $SupportedSizes | Where-Object Sku -eq $VmSize

      if($DiskCount -gt $VmSizeInfo.MaxDataDisks) {
        throw [NveImageDisksExceedsMaxException]::New($DiskCount, $VmSizeInfo.Sku, $Location)
      }
        
      # Validate $Location
      $AusRegions = Get-AzLocation | Where-Object DisplayName -match '^Australia\s\w' | Select-Object DisplayName, Location
      $ValidRegion = $AusRegions | Where-Object { $_.DisplayName -eq $Location -or $_.Location -eq $Location}
      if(-Not $ValidRegion) { 
        throw "Provided Location:'$Location' is not a valid Australian Azure Region. Seek admin help for this error"
      }
      
      # Validate $VnetName, $VnetRg
      try {
        $Vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $VnetRg
      }
      catch {
        Write-NveError $_ "VNet:'$VnetName' not found under Resource Group:'$VnetRg'"
      }

      # Validate $SubnetName
      $Found = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet | Where-Object Name -eq $SubnetName
      if(-Not $Found) { 
        throw "Subnet:'$SubnetName' could not be found in VNet:'$VnetName' under Resource Group:'$VnetRg'"
      }

      # Validate $NicNsgName, $NicNsgRg
      try {
        Get-AzNetworkSecurityGroup -Name $NicNsgName -ResourceGroupName $NicNsgRg | Out-Null
      }
      catch {
        Write-NveError $_ "Cannot find Network Security Group:'$NicNsgName' in Resource Group:'$NicNsgRg'"
      }
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    #region AzDeployment
    Write-Output @"

$hr

  Commencing new Lab creation

$hr

"@
    try {

      # Format the three letter location code from the Location DisplayName
      $LocArr = $ValidRegion.DisplayName -split '\s'
      $LocationCode = ("{0}{1}{2}" -f $LocArr[0].substring(0,2), $LocArr[1].Substring(0,1), ($LocArr[2] ? $LocArr[2].Substring(0,1) : '')).ToLower()

      # Pick the Image version to use
      $ImageReferenceId ="$($Gallery.Id)/images/$ImageName"

      $Params = @{
        ResourceGroupName = $GalleryRgName
        GalleryName = $GalleryName
        GalleryImageDefinitionName = $ImageName
      }
      $LatestVersion = Get-AzGalleryImageVersion @Params | Where-Object { $PSItem.PublishingProfile.ExcludeFromLatest -eq $false } | Sort-Object Name -Descending | Select-Object -First 1 -ExpandProperty Name
      
      # Generate an admin password for the VM
      $Password = Get-NveRandomPassword

      try {
        Get-AzStorageBlobContent -Container $TemplatesContainer -Blob "nve-template.json" -Destination $env:TEMP -Context $StorageContext -Force | Out-Null
      } 
      catch {
        Write-NveError $_ "Could not retrieve the ARM template, which is required to create the VM. Seek admin help for this error"        
      }

      try {
        Write-Output "Deploying template to Azure Resource Manager (this may take some time)"
        $Parameters = @{
          labName           = $LabName
          vmSize            = $VmSize
          location          = $Location
          loc               = $LocationCode
          org               = $OrgCode
          adminPassword     = $Password
          adminUsername     = $Username
          imageReferenceId  = $ImageReferenceId
          shutDownTime      = $ShutDownTime
          timeZoneId        = $TimeZoneId
          subnetName        = $SubnetName
          vnetName          = $VnetName
          vnetRg            = $VnetRg
          nicNsgName        = $NicNsgName
          nicNsgRg          = $NicNsgRg
          imageVersion      = $LatestVersion
          imageName         = $ImageName
          accessGroupId     = $AccessGroupId
        }

        $Params = @{
          Name = ("nve-{0}-{1}-{2}-deployment" -f $OrgCode, $LabName, $LocationCode)
          Location = $Location
          TemplateFile = "{0}\nve-template.json" -f $env:TEMP
          TemplateParameterObject = $Parameters
        }
        $Deployment = New-AzDeployment @Params
        Write-Output "ARM Template deployment successful"

        Write-Output @"

$hr

  Lab Details:

$hr

"@

        [PSCustomObject]@{
          VmName   = "vm-nve-$OrgCode-$LabName"
          IpAddress = $Deployment.Outputs.ipAddress.value
          Computername = "NVE"
          Username = $Username
          Login = ("NVE\{0}" -f $Username)
          Password = $Password
        }

        Write-Output @"

$hr

  IMPORTANT: Your Lab will automatically shutdown at $ShutdownTime UTC. Detailed below are the equivalent local times:
"@

        Get-NveLocalTimes -UtcTime $ShutDownTime | Format-Table -AutoSize

        Write-Output @"

  If you are still using your Lab, ensure you use the c--Extend_Lab_Time Runboook prior to this time to prevent the shutdown.
  
  The Lab will be extended in $AllocatedHours hr increments.
  
$hr

  Connections Methods

$hr
  
  Connect via Bastion RDP (Best Experience):
  ------------------------------------------
  Run the below commands in an Azure CLI shell (version 2.32+)

  az login
  az account set --subscription '$SubscriptionId'
  az network bastion rdp --name '$BastionName' --resource-group '$BastionRg' --target-resource-id '$($Deployment.Outputs.resourceId.value)'

$hr
 
  Connect via Bastion HTTPS:
  --------------------------
  
  Browse VM Resources here: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Compute%2FVirtualMachines

    *Use the Connect feature associated to your VM. Only the Bastion option will work.

$hr
"@       
      } 
      catch {
        Write-NveError $_ "New-AzDeployment call failed."
      }
    }
    catch {
      Write-NveError $_ "Deployment failed"
    }
    #endregion AzDeployment
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}