<#
.SYNOPSIS
  The Get-NveResources function lists the available VMs and images.

.DESCRIPTION
  This function will check what VMs and images are available under the organisations lab infrastructure
  and display to the caller. This can be used in the case the end user has forgotten what resources they have
  previously setup.

.NOTES
  Author: Ryan Shaw

.LINK
  Module repo located at: TBA

.EXAMPLE
  Get-NveResources -OrgCode 'dev' -GalleryRgName $Gallery.ResourceGroupName -GalleryName $Gallery.Name

  All VMs under the nve organisation code will be listed. All images from within the provided gallery will be listed.
#>

function Get-NveResources {
  [CmdletBinding()]

  Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryRgName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryName
  )

  $ErrorActionPreference = 'Stop'

  try {
    $OrgCode = $OrgCode.ToLower()
    $hr = "_________________________________________________________________________________________________________"

    #region ParameterValidation
    try {
       # Validate $GalleryName, $GalleryRgName
      try {
        $Gallery = Get-AzGallery -Name $GalleryName -ResourceGroupName $GalleryRgName
      }
      catch {
        Write-NveError $_ "The Gallery:'$GalleryName' was not found in Resource Group:'$GalleryRgName'. Seek admin help for this error"
      }
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

    Available Labs

$hr

"@

    $ExistingLabs = Get-AzResourceGroup -Name ("nve-{0}-*" -f $OrgCode)
    if($ExistingLabs) {
      foreach($ExistingLab in $ExistingLabs) {
        Write-Output ("`t {0}" -f $ExistingLab.ResourceGroupName.Split('-')[2])
      }
    }
    else {
      Write-Output "There are currently no available labs. Create a New Lab."
    }
  

  Write-Output @"

$hr

  Available Images

$hr

"@
    $ImageDefinitions = Get-AzGalleryImageDefinition -ResourceGroupName $Gallery.ResourceGroupName -GalleryName $Gallery.Name

    foreach ($Image in $ImageDefinitions) {
      Write-Host ("`t {0}-{1}-{2}" -f $Image.Identifier.Publisher, $Image.Identifier.Offer, $Image.Identifier.SKU)
    }  
  }
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}
