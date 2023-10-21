############################################################################################
#
#                               Update_Source_Image Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the unique LabName of the Lab that you wish to use as the update 
#                   source.
#
#                   A new Image Version will be captured using this VM, which will replace 
#                   the source Image Definition.
#
# Use the Update_Source_Image Runbook to update an Image Definition with a new Image Version.
#
# IMPORTANT: Only two Image Versions are kept per Image Definition. Any Image Versions older
# than the latest two versions will be deleted. If you need to rollback the image version, 
# seek admin help.
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
$OrgCode        = 'nve'
$BudgetName     = 'budget-monthly-labs'
$GalleryRgName  = 'rg-nve-prod-aue-001'
$GalleryName    = '<Image_Gallery_Name>'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  $Params = @{
    LabName       = $LabName
    OrgCode       = $OrgCode
    BudgetName    = $BudgetName
    GalleryName   = $GalleryName
    GalleryRgName = $GalleryRgName
  }
  Update-NveImage @Params

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}