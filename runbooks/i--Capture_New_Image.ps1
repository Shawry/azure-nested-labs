############################################################################################
#
#                                    Capture_New_Image Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to capture.
#
#   PUBLISHER     - Enter the Publisher name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
#                   The Publisher name 'dni' is a reserved name used for the baseline Images.
#
#   OFFER         - Enter the Offer name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
#   SKU           - Enter the SKU name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
# Use the Capture_New_Image Runbook if you wish to make your Lab available to others through 
# the Azure Compute Gallery. 
#
# IMPORTANT: Ensure your Lab is in a state that it can be captured. The lab should be online.
# This Runbook will Sysprep/Generalize the VM and delete it after the capture is complete. 
#
# You will need to reprovision from the new source Image if you wish to have a working Lab.
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
    $LabName,

    [Parameter(Mandatory)]
    [string]
    $Publisher,

    [Parameter(Mandatory)]
    [string]
    $Offer,

    [Parameter(Mandatory)]
    [string]
    $SKU
)

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode        = 'dni' # Defence 'n' Intel
$GalleryRgName  = 'rg-nve-prod-aue-001'
$GalleryName    = 'Defence_and_Intel_Image_Gallery'
$BudgetName     = 'budget-monthly-defence-non-prod'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\oobeNve\oobeNve\oobeNve.psd1'

  $Params = @{
    LabName     = $LabName
    OrgCode     = $OrgCode
    Publisher   = $Publisher
    Offer       = $Offer
    SKU         = $SKU
    BudgetName  = $BudgetName
    GalleryName = $GalleryName
    GalleryRgName = $GalleryRgName
  }
  New-NveImage @Params

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}