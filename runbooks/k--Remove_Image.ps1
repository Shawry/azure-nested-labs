############################################################################################
#
#                                 Remove_Image Runbook
#
############################################################################################
#
# Parameters:
#
#   PUBLISHER     - Enter the Publisher name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
#                   The Publisher name 'nve' is a reserved name used for the baseline Images.
#
#   OFFER         - Enter the Offer name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
#   SKU           - Enter the SKU name here.
#                   Image Definition name eg: <Publisher>-<Offer>-<Sku>
#
# Use the Remove_Image Runbook to Remove an unwanted Image Definition and all related Image 
# Versions.
# 
# IMPORTANT: This action is irreversible. Do not remove Images without the owner's consent.
#
############################################################################################
#
#
#
############################################################################################
Param(

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
$OrgCode        = 'dev'
$GalleryRgName  = 'rg-nve-prod-ae-001'
$GalleryName    = '<Image_Gallery_Name>'
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\Nve\Nve\Nve.psd1'

  $Params = @{
    Publisher     = $Publisher
    Offer         = $Offer
    SKU           = $SKU
    OrgCode       = $OrgCode
    GalleryName   = $GalleryName
    GalleryRgName = $GalleryRgName
  }
  Remove-NveImage @Params

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}