############################################################################################
#
#                             List_Available_Resources Runbook
#
############################################################################################
#
# Parameters:
#   nil
#
#
# Use the List_Available_Resources Runbook to show what Labs and Images are available.
# 
# 
# 
#
############################################################################################
#
#
#
############################################################################################
Param(
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode        = 'dev'
$GalleryRgName      = 'rg-nve-prod-aue-001'
$GalleryName        = '<Image_Gallery_Name>'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  Get-NveResources -OrgCode $OrgCode -GalleryRgName $GalleryRgName -GalleryName $GalleryName

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}