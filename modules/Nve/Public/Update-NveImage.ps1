<#
.SYNOPSIS
 The Update-NveImage function creates a new version of an image.

.DESCRIPTION
  This function creates a new Image Version of an Image Definition using the VM provided in the $LabName parameter.
  Only the VM's source Image Defintion can be updated, the caller cannot select a different Image Definition.

  The Lab VM will be captured, and then the lab and all associated resources are deleted.

  Each Image Definition will keep only two Image Versions, all older Image Versions are removed.

.NOTES
  Author: Ryan Shaw

  IMPORTANT: After the capture has completed, the lab VM and all of its associated resources are deleted.
  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error.
  
.LINK
  Module repo located at: TBA

.EXAMPLE
  $Params = @{
    LabName       = 'my_lab'
    OrgCode       = 'nve'
    BudgetName    = 'budget-monthly-non-prod'
    GalleryName   = 'Image_Gallery'
    GalleryRgName = 'rg-nve-prod-aue-001'
  }
  Update-NveImage @Params

  The 'my_lab' VM will be captured as a new Image Version on the VM's source Image Definition. 
  No more than two Image Versions are kept, with the oldest being removed first. The 'my_lab' lab resources will be deleted.
#>

function Update-NveImage {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $LabName,

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
    $GalleryName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $hr = "_________________________________________________________________________________________________________"

    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode       
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)

      $Identifier = $Lab.Image -split '-'
      if($Identifier[0] -eq $OrgCode) {
        throw ("You cannot update Image:'{0}', This is a reserved image. Create a new Image instead" -f $Lab.Image)
      }

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

  Commencing Image update

$hr

"@
    try {
      $Params = @{
        GalleryName                 = $GalleryName
        ResourceGroupName           = $GalleryRgName
        GalleryImageDefinitionName  = $Lab.Image
      }
      $ImageVersions = Get-AzGalleryImageVersion @Params
    }
    catch {
      Write-Output "The source image Image Definition of the provided VM no longer exists in the Gallery"
      Write-Output ("Image Definition:{0}, Gallery: {1}" -f $Lab.Image, $GalleryName)
      Write-Output "A new Image Definition will be created"
      
      $Params = @{
        LabName         = $LabName
        OrgCode         = $OrgCode
        Publisher       = $Identifier[0]
        Offer           = $Identifier[1]
        Sku             = $Identifier[2]
        GalleryName     = $GalleryName
        $GalleryRgName  = $GalleryRgName
      }
      New-NveImage @Params
      break;
    }

    try {
      $SortedVersions = $ImageVersions | Foreach-Object {

        [PSCustomObject]@{
          Version = [UInt16]$PSItem.Name.split('.')[0]
          Object = $PSItem
        }
      } | Sort-Object Version -Descending

      $NewVersion = "{0}.0.0" -f ($SortedVersions[0].Version + 1)

      Generalize-NveVm -Lab $Lab

      Write-Output "Image capture commencing (this may take some time)"
      $Params = @{
        ResourceGroupName = $GalleryRgName
        GalleryName       = $GalleryName
        Name              = $NewVersion
        Location          = $Lab.Location
        SourceImageId     = $Lab.ResourceId
        GalleryImageDefinitionName = $Lab.Image
      }
      New-AzGalleryImageVersion @Params | Out-Null
      Write-Output "Image version created. Removing source Lab resources"
    }
    catch {
      Write-NveError $_ "Failed to create new Image Version"
    }
   
    try {
      if($SortedVersions.count -gt 1 ) {
        Write-Output ("Removing oldest Image Version for Image Definition:'{0}' (we only keep two versions)" -f $Lab.Image)
        $Params = @{
          Name = $SortedVersions[-1].Object.Name
          Force = $true
          GalleryName  = $GalleryName
          ResourceGroupName = $GalleryRgName
          GalleryImageDefinitionName = $Lab.Image
        }
        Remove-AzGalleryImageVersion @Params | Out-Null
        Write-Output ("Version:'{0}' successfully removed" -f $SortedVersions[-1].Object.Name)
      }
    }
    catch {
      Write-Warning "Failed to remove old Image Version"
    }

    Remove-NveLab -LabName $Lab.LabName -OrgCode $OrgCode

    Write-Output @"

$hr

  Image creation is complete. To utilise the Image, run the a--New_Lab runbook with $($Lab.Image) as the SOURCEIMAGE parameter.

$hr
"@
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}