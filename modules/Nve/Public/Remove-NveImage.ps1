<#
.SYNOPSIS
  The Remove-NveImage function removes an Image Definition from an Azure Compute Gallery

.DESCRIPTION
  This function will delete all Image Versions associated to the Image Definition and then delete the 
  Image Definition itself.

  The caller provides the <Publisher>-<Offer>-<Sku> name, of which the Publisher argument cannot be the same as the 
  OrgCode parameter provided, as this Publisher name is considered reserved.

.NOTES
  Author: Ryan Shaw

  IMPORTANT: Once the Image Versions are deleted they cannot be recovered.

.LINK
  Module repo located at: TBA

.EXAMPLE
  $Params = @{
    Publisher     = 'org_name'
    Offer         = 'division'
    SKU           = 'lab_name'
    OrgCode       = 'dev'
    GalleryName   = $Gallery.Name
    GalleryRgName = $Gallery.ResourceGroupName
  }
  Remove-NveImage @Params

  This will remove the org_name-division-lab_name Image Defintion and all associated Image Versions.
#>

function Remove-NveImage {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $OrgCode,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Publisher,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Offer,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SKU,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryRgName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $GalleryName,

    [Parameter()]
    [UInt16]
    $Timeout = 900
  )

  $ErrorActionPreference = 'Stop'

  try {
    $OrgCode = $OrgCode.ToLower()
    $Publisher = $Publisher.ToLower()
    $Offer = $Offer.ToLower()
    $SKU = $SKU.ToLower()
    $hr = "_________________________________________________________________________________________________________"

    #region ParameterValidation
    try {
      # Validate not reserved
      if($Publisher -eq $OrgCode) {
        throw "Publisher:'$OrgCode' is invalid. These are reserved Images. You cannot remove a reserved Image. "
      }
  
      # Validate $GalleryName, $GalleryRgName
      try {
        $Gallery = Get-AzGallery -Name $GalleryName -ResourceGroupName $GalleryRgName
      }
      catch {
        Write-NveError $_ "The Gallery:'$GalleryName' was not found in Resource Group:'$GalleryRgName'. Seek admin help for this error"
      }

      # Validate $Publisher, $Offer, $SKU
      $ImageDefinition = "{0}-{1}-{2}" -f $Publisher, $Offer, $SKU
      
      $ImageVersions = Get-AzGalleryImageVersion -ResourceGroupName $GalleryRgName -GalleryName $GalleryName -GalleryImageDefinitionName $ImageDefinition
      if(-Not $ImageVersions) {
        throw [NveImageDefinitionDoesNotExistException]::New($ImageDefinition, $GalleryRgName, $GalleryName)
      }
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

        Write-Output @"

$hr
   
  Commencing Image removal

$hr
        
"@
    if($ImageVersions) {
      Write-Output "Removing Image Versions:"
    }
    foreach($ImageVersion in $ImageVersions) {
      try {
        Write-Output ("Removing version:'{0}'" -f $ImageVersion.Name)
        $Params = @{
          Name = $ImageVersion.Name
          Force = $true
          GalleryName  = $GalleryName
          ResourceGroupName = $GalleryRgName
          GalleryImageDefinitionName = $ImageDefinition
        }
        Remove-AzGalleryImageVersion @Params | Out-Null
        Write-Output "Successfully removed version"
      }
      catch {
        Write-NveError $_ ("Failed to remove version:'{0} for Image Definition:'{1}'" -f $ImageVersion.Name, $ImageDefinition)
      }
    }

    
    if($ImageVersions) {
      Write-Output "Waiting for nested versions to clear before deleting Image Definition"
      
      $Params = @{
        GalleryName                 = $GalleryName
        ResourceGroupName           = $GalleryRgName
        GalleryImageDefinitionName  = $ImageDefinition
      }

      $TimeLapsed = 0
      do {
        $ImageVersions = Get-AzGalleryImageVersion @Params

        if($ImageVersions) {
          
          if($TimeLapsed -ge $Timeout) {
            Write-Output "Timed out waiting for nested Image Versions to clear"
            throw "Timed out waiting for nested Image Versions to clear. Try again later."
          }
          else {
            Write-Output ("Sleeping for 30 secs. Time lapsed: $TimeLapsed secs. Remaining Image Versions:{0}. Timeout due at: $TimeOut secs" -f $ImageVersions.Count)
            $TimeLapsed += 30
            Start-Sleep -Seconds 30
          }
        }
        else {
          # Azure can still be holding onto the nested versions despite Get-AzGalleryImageVersion returning no results
          Start-Sleep -Seconds 30

          Write-Output "Nested versions cleared"
          $VersionsCleared = $true
        }
      }
      until ($VersionsCleared)
    }

    Write-Output "Removing Image Definition:'$ImageDefinition' from Image Gallery"
    try {
      $Params = @{
        Force = $true
        GalleryName  = $GalleryName
        ResourceGroupName = $GalleryRgName
        GalleryImageDefinitionName = $ImageDefinition
      }
      Remove-AzGalleryImageDefinition @Params | Out-Null
      Write-Output "Successfully removed Image Definition"
    }
    catch {
      Write-NveError $_ "Failed to remove Image Definition"
    }

    Write-Output @"

$hr

  Image successfully removed

$hr
"@
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}