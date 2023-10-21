############################################################################################
#
#                              Stop_Lab Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to stop
#
# Use the Stop_Lab Runbook to deallocate the VM resources of your Lab when not in use. 
# This aides in reducing compute costs. 
# 
# It is important to understand that simply shutting down your VM will not deallocate the 
# Azure resources. A VM that is only shut down will still incur compute costs.
#
############################################################################################
#
#
#
############################################################################################
Param(
    [Parameter(Mandatory)]
    [string]
    $LabName
)
$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode        = 'dev'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  Stop-NveLab -LabName $LabName -OrgCode $OrgCode

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}