############################################################################################
#
#                                 Reset_Lab_Password Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab that you wish to reset the labadmin 
#                   credentials for.
#                                    
#
# Use the Reset_Lab_Password Runbook to reset the labadmin credentials for a given Lab.
#
#
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
$OrgCode     = 'dni' # Defence 'n' Intel
$Username    = 'labadmin'
$BastionName = 'bas-nve-prod-aue-001'
$BastionRg   = 'rg-net-prod-aue-001'
$BudgetName  = 'budget-monthly-defence-non-prod'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\oobeNve\oobeNve\oobeNve.psd1'

  $Params = @{
    OrgCode     = $OrgCode
    LabName     = $LabName
    Username    = $Username
    BastionName = $BastionName
    BudgetName  = $BudgetName
    BastionRg   = $BastionRg
  }
  Reset-NveLabPassword @Params

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}