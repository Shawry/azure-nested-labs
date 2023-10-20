############################################################################################
#
#                                 Set_Lab_VmSize Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to change the VM Size of.
#
#   VMSIZE        - Enter the VM Size SKU that you want to change the Lab to.
#
#                   The VMSIZE parameter must be from the list of supported sizes. 
#                   See further below for supported VM Sizes.
#
# Use the Set_Lab_VmSize Runbook to change the VM Size SKU so that you can either increase 
# or decrease the specs of the Lab VM. Nested Virtualisation setups are memory hungry, so 
# the more Guest VMs you add to your Lab the more memory you will need. Likewise with vCPU 
# capacity.
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
Param(
    [Parameter(Mandatory)]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [string]
    $VmSize
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode    = 'nve'
$BudgetName = 'budget-monthly-non-prod'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  Set-NveVmSize -LabName $LabName -OrgCode $OrgCode -VmSize $VmSize -BudgetName $BudgetName

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}