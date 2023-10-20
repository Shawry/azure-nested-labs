<#
.SYNOPSIS
  The New-NveImage function creates an Image from a source VM and stores it in a Azure Compute Gallery

.DESCRIPTION
  This function will sysprep, generalise and capture a lab VM and store the image in an Azure Compute Gallery.

  The caller provides the <Publisher>-<Offer>-<Sku> name, of which the Publisher argument cannot be the same as the 
  OrgCode parameter provided, as this Publisher name is considered reserved.

.NOTES
  Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

  IMPORTANT: After the capture has completed, the lab VM and all of its associated resources are deleted.
  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error

.LINK
  Module repo located at: TBA

.EXAMPLE
  $Params = @{
    LabName     = 'my_lab'
    OrgCode     = 'dni'
    Publisher   = 'deployables'
    Offer       = 'fleet'
    SKU         = 'secret_server'
    BudgetName  = $Budget.Name
    GalleryName = $Gallery.Name
    GalleryRgName = $Gallery.ResourceGroupName
  }
  New-NveImage @Params

  This call will sysprep, generalise, and capture the 'my_lab' lab VM and create a new 'deployables-fleet-secret_server' 
  Image Definition, providing the budget limit has not been exceeded. The lab will be removed after the capture is taken.
#>

function New-NveImage {
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

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $Publisher = $Publisher.ToLower()
    $Offer = $Offer.ToLower()
    $SKU = $SKU.ToLower()
    $hr = "_________________________________________________________________________________________________________"

    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode       
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)

      if($Publisher -eq $OrgCode) {
        throw "You cannot use Publisher:'$OrgCode' for your Image. This is a reserved name"
      }

      # Validate $Publisher, $Offer, $SKU
      $DefinitionFailed = @{}
      $DefinitionFailed.Publisher = $Publisher -notmatch '^[a-z0-9_]{1,15}$'
      $DefinitionFailed.Offer = $Offer -notmatch '^[a-z0-9_]{1,15}$'
      $DefinitionFailed.SKU = $SKU -notmatch '^[a-z0-9_]{1,15}$'

      if($DefinitionFailed.Values -contains $true) {
        $Message = ("`r`nThe following input parameters failed validation: {0}`r`nThese values must only contain letters a-z, numbers 0-9, underscores, and be between 1 and 15 characters long" -f (
         ($DefinitionFailed.GetEnumerator() | Where-Object Value -eq $true | Select-Object -ExpandProperty Name) -join ', '
        ))
        
        Write-Output $Message
        throw $Message
      }

      # Validate $GalleryName, $GalleryRgName
      try {
        $Gallery = Get-AzGallery -Name $GalleryName -ResourceGroupName $GalleryRgName
      }
      catch {
        Write-NveError $_ "The Gallery:'$GalleryName' was not found in Resource Group:'$GalleryRgName'. Seek admin help for this error"
      }

      $ImageDefinition = "{0}-{1}-{2}" -f $Publisher, $Offer, $SKU
      try {
        $DefinitionAlreadyExists = Get-AzGalleryImageDefinition -ResourceGroupName $GalleryRgName -GalleryName $GalleryName -GalleryImageDefinitionName $ImageDefinition
      }
      catch {
        if($PSItem -notmatch 'ErrorCode: ResourceNotFound') {
          throw $PSitem
        }
      }

      if($DefinitionAlreadyExists) {
        throw [NveImageDefinitionAlreadyExistsException]::New($ImageDefinition, $GalleryRgName, $GalleryName)
      }
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

  Commencing Image creation

$hr

"@
    Generalize-NveVm -Lab $Lab

    try {
      $Params = @{
        ResourceGroupName = $GalleryRgName
        GalleryName       = $GalleryName
        Name              = $ImageDefinition
        Publisher         = $Publisher
        Offer             = $Offer
        Sku               = $SKU
        OsType            = 'Windows'
        OsState           = 'Generalized'
        HyperVGeneration  = 'V2'
        Location          = $Lab.Location
      }
      New-AzGalleryImageDefinition @Params | Out-Null
      Write-Output "Image Definition created"

      Write-Output "Image capture commencing (this may take some time)"
      $Params = @{
        ResourceGroupName = $GalleryRgName
        GalleryName       = $GalleryName
        Name              = '1.0.0'
        Location          = $Lab.Location
        SourceImageId     = $Lab.ResourceId
        GalleryImageDefinitionName = $ImageDefinition
      }
      New-AzGalleryImageVersion @Params | Out-Null
      Write-Output "Image version created. Removing source Lab resources"
    }
    catch {
      Write-NveError $_ "Failed to capture Image"
    }

    Remove-NveLab -LabName $Lab.LabName -OrgCode $OrgCode

    Write-Output @"

$hr

  Image creation complete

  To utilise the Image, run the a--New_Lab runbook with $ImageDefinition as the SOURCEIMAGE argument.

$hr
"@
     
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}