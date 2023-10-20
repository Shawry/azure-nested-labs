############################################################################################
#
#                           Extend_Lab_Time Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to extend the time for.
#
# Use the Extend_Lab_Time Runbook to prolong the AutoShutdown schedule for a VM. 
# 
# You do NOT need to run the Runbook before starting a VM via the Start_Lab Runbook. 
# The Start_Lab Runbook will extend the Lab time automatically.
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
$OrgCode            = 'nve'
$AllocatedHours     = 4
$BudgetName         = 'budget-monthly-non-prod'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  Grant-NveLabTime -LabName $LabName -OrgCode $OrgCode -AllocatedHours $AllocatedHours -BudgetName $BudgetName

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}