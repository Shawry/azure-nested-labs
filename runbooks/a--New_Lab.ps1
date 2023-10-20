############################################################################################
#
#                                  New_Lab Runbook
#
############################################################################################
#
# Parameters:
#
#   LABNAME       - Enter a Unique LabName that will be used to identify your Lab throughout 
#                   its lifetime. The LABNAME argument must be between 3 and 15 characters 
#                   long. This parameter will only accept letters a-z, digits 0-9, and 
#                   underscores. Hyphens will be converted to underscores.
#
#   SOURCEIMAGE   - This is the Image that your Lab will be provisioned from. 
#                   The SOURCEIMAGE format looks like this: nve-baseline-standard
#             
#                   If you don't have a SOURCEIMAGE just leave it blank and it will default
#                   to the baseline image.      
#             
#   VMSIZE        - Enter the VM Size SKU you wish to use. Select from the VM sizes listed 
#                   below.
#
#                   You do not need to change the VM Size SKU. Levae blank for the default
#                   VM Size.
#
# 
############################################################################################
#
# Detailed below are the supported VM Sizes
#
## ___________________General Purpose ##_________________________________
# Standard_D4s_v5   # 4 x vCPU  | 16 GiB Memory   | 8 x Max data disks
# Standard_D2s_v5   # 2 x vCPU  | 8 GiB Memory    | 4 x Max data disks
# Standard_D8s_v5   # 8 x vCPU  | 32 GiB Memory   | 16 x Max data disks 
# Standard_D16s_v5  # 16 x vCPU | 64 GiB Memory   | 32 x Max data disks
# Standard_D32s_v5  # 32 x vCPU | 128 GiB Memory  | 32 x Max data disks
# Standard_D48s_v5  # 48 x vCPU | 192 GiB Memory  | 32 x Max data disks
# Standard_D64s_v5  # 64 x vCPU | 256 GiB Memory  | 32 x Max data disks
# Standard_D96s_v5  # 96 x vCPU | 384 GiB Memory  | 32 x Max data disks
#
## ___________________Memory Optimized ##________________________________
# Standard_E2s_v5   # 2 x vCPU  | 16 GiB Memory   | 4 x Max data disks
# Standard_E4s_v5   # 4 x vCPU  | 32 GiB Memory   | 8 x Max data disks
# Standard_E8s_v5   # 8 x vCPU  | 64 GiB Memory   | 16 x Max data disks
# Standard_E16s_v5  # 16 x vCPU | 128 GiB Memory  | 32 x Max data disks
# Standard_E20s_v5  # 20 x vCPU | 160 GiB Memory  | 32 x Max data disks
# Standard_E32s_v5  # 32 x vCPU | 256 GiB Memory  | 32 x Max data disks
# Standard_E48s_v5  # 48 x vCPU | 384 GiB Memory  | 32 x Max data disks
# Standard_E64s_v5  # 64 x vCPU | 512 GiB Memory  | 32 x Max data disks
# Standard_E96s_v5  # 96 x vCPU | 672 GiB Memory  | 32 x Max data disks
#
#
############################################################################################
#
<#

How to use the Labs:

  Step 1.
    Provision a new Lab from the baseline Image. This is the default: nve-baseline-standard

  Step 2.
    Add the things you want to your Lab. You can remove the VMs that already exist if you 
    like, they are just a templated example.

  Step 3.
    Use you Lab as required, ensuring you use the Stop_Lab runbook to deallocate your Lab's 
    resources when not in use.

  Step 4.
    Add/Remove Data Disks to your lab as required, using either the Add_Lab_DataDisks or 
    Remove_Lab_DataDisks runbooks.

    Configure you disks as you see fit from within your VM. The baseline configuration uses
    Storage Space pools, so you will need to add any new physical disks to the DataPool and 
    extend both the DataDisk virtual disk size, and the Data volume size to utilise the new 
    storage.

  Step 5.
    If you want to create an Image Definition from your Lab so others can use it, use the 
    Capture_New_Image runbook.

    Give the new Image Definition a descriptive name. 
    eg:
      Publisher:  deployables
      Offer:      fie
      Sku:        secret_server

  Step 6. 
    You can now provision from your Image Definition via the SOURCEIMAGE parameter of the 
    New_Lab runbook.

    Using the example from Step 5 provide the following argument to the SOURCEIMAGE
    parameter for the New_Lab runbook:

    deployables-fie-secret_server

  Step 7.
    If you want to update the Image Definition, use the Update_Source_Image runbook.
    This will recapture the Lab and update the Image Definition.

    *If you want to create a new Image Definition again, repeat from Step 5 using a 
    different <Publisher>-<Offer>-<Sku> definition.

  Step 8.
    If you don't need your Lab any more, use the Remove_Lab runbook to delete the Lab 
    resources.

  Step 9.
    If you dont need your Image Definition any more (ever), then use the Remove_Image 
    runbook.
    
#>
#
############################################################################################
param (

  [Parameter(Mandatory)]
  [string]
  $LabName,

  [Parameter()]
  [string]
  $SourceImage = 'nve-baseline-standard',

  [Parameter()]
  [string]
  $VmSize = 'Standard_D8s_v5'
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$Location           = 'Australia East'
$VnetName           = 'vnet-nve-prod-aue-001'
$VnetRg             = 'rg-net-prod-aue-001'
$SubnetName         = 'snet-nve-prod-aue-001'
$NicNsgName         = 'nsg-nvenicprod-001'
$NicNsgRg           = 'rg-net-prod-aue-001'
$StorageAccountName = 'stnvedevdata001'
$TemplatesContainer = 'templates'
$GalleryRgName      = 'rg-nve-prod-aue-001'
$GalleryName        = 'Image_Gallery'
$Username           = 'labadmin'
$OrgCode            = 'nve'
$AllocatedHours     = 4
$BudgetName         = 'budget-monthly-non-prod'
$BastionName        = 'bas-nve-prod-aue-001'
$BastionRg          = 'rg-net-prod-aue-001'
$AccessGroupId      = 'd52bac22-c43d-468f-9b74-07ed2d3f8f48'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
  
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
  $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  $Params = @{
      OrgCode             = $OrgCode
      LabName             = $LabName      
      Username            = $Username
      VmSize              = $VmSize
      Location            = $Location
      ImageName           = $SourceImage
      GalleryName         = $GalleryName
      GalleryRgName       = $GalleryRgName
      SubnetName          = $SubnetName
      VnetName            = $VnetName
      VnetRg              = $VnetRg
      NicNsgName          = $NicNsgName
      NicNsgRg            = $NicNsgRg
      StorageContext      = $StorageContext
      TemplatesContainer  = $TemplatesContainer
      AllocatedHours      = $AllocatedHours
      BudgetName          = $BudgetName
      BastionName         = $BastionName
      BastionRg           = $BastionRg
      AccessGroupId       = $AccessGroupId
  }
  New-NveLab @Params
  
  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}