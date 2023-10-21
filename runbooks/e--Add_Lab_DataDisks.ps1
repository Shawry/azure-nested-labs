############################################################################################
#
#                           Add_Lab_DataDisks Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to add Data Disks to.
#
#   QUANTITY      - Enter the number of Data Disks to add. Each disk is 126 GB each.
#
#
# Use the Add_Lab_DataDisks Runbook to add extra Data Disks to an existing Lab
#
# IMPORTANT: You cannot exceed the MaxDataDiskCount for the Lab's VM Size. See below for 
# Max Data Disk values
#            
#
############################################################################################
#
# Detailed below are the supported VM Sizes and their MaxDataDisk values
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
Param(
    [Parameter(Mandatory)]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [UInt16]
    $Quantity
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode  = 'dev'
$DiskSize = 128 # Must be one of: 4,8,16,32,64,128,256,512,1024
$BudgetName = 'budget-monthly-labs'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  Add-NveDataDisk -LabName $LabName -OrgCode $OrgCode -Quantity $Quantity -DiskSize $DiskSize -BudgetName $BudgetName

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}