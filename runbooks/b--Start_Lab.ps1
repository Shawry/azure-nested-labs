############################################################################################
#
#                               Start_Lab Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to start
#
# The Start_Lab runbook will not start if the Subscription Budget limit is reached. You will 
# neeed to wait until the new Budget period before you can use the Labs.
#
############################################################################################
#
#
#
############################################################################################
Param (
  [Parameter(Mandatory)]
  [string]
  $LabName
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode        = 'dev'
$AllocatedHours = 4
$BudgetName         = 'budget-monthly-labs'
$BastionName        = 'bas-nve-labs-aue-001'
$BastionRg          = 'rg-net-labs-aue-001'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))

  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  $Params = @{
    OrgCode         = $OrgCode 
    LabName         = $LabName 
    AllocatedHours  = $AllocatedHours
    BudgetName      = $BudgetName
    BastionName     = $BastionName
    BastionRg       = $BastionRg
  }

  Start-NveLab @Params
  
  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}