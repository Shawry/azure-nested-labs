<#
.SYNOPSIS
  The Start-NveLab function starts a Lab.

.DESCRIPTION
  This function starts a lab VM and sets the auto shutdown schedule according to the $AllocatedHours parameter.
  If the Budget limit is exceeded, this function will not work.

.NOTES
  Author: Ryan Shaw

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error

.LINK
  Module repo located at: TBA

.EXAMPLE
  Start-NveLab -LabName 'my_lab' -OrgCode 'nve' -AllocatedHours 4
#>

function Start-NveLab {
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
      [ValidateRange(1,23)]
      [UInt32]
      $AllocatedHours,

      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]
      $BudgetName,

      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]
      $BastionName,
      
      [Parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [string]
      $BastionRg
  )

  $ErrorActionPreference = 'Stop'

  try {
    $LabName = $LabName.replace('-','_').ToLower()
    $OrgCode = $OrgCode.ToLower()
    $SubscriptionId = Get-AzContext | ForEach-Object { $_.Subscription.Id }
    $hr = "_________________________________________________________________________________________________________"

    Confirm-NveBudget -Name $BudgetName

    #region ParameterValidation
    try {
      # Validate $LabName, $OrgCode
      $Lab = [NveLab]::ValidateExists($LabName, $OrgCode)
    }
    catch {
      Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

  Commencing Lab Start-up

$hr

"@
    $ShutdownTime = Set-NveAutoShutdown -LabName $Lab.LabName -OrgCode $OrgCode -AllocatedHours $AllocatedHours

    $Params = @{
      ResourceGroupName   = $Lab.ResourceGroupName
      ResourceType        = 'Microsoft.Compute/virtualMachines'
      Tag              = @{
        "Org" = $OrgCode
        "Lab" = $Lab.LabName
      }
    }
    $VMResource = Get-AzResource @Params

    if(-Not $VmResource) {
      throw "No VM was found in the resource group:$($Lab.ResourceGroupName). Cannot continue. Seek admin help for this error"
    }

    $VMStatus = Get-AzVM -VMName $VMResource.Name -Status
    switch($VMStatus.PowerState) {
      'VM starting' { Write-Output ("VM:'{0}' already starting" -f $VMResource.Name) }
      'VM running' { Write-Output ("VM:'{0}' already running" -f $VMResource.Name) }
      'VM deallocating' { Write-Output ("VM:'{0}' was deallocating. Starting now" -f $VMResource.Name) }
      'VM deallocated' { Write-Output ("VM:'{0}' was deallocated. Starting now" -f $VMResource.Name) }
      'VM stopped' { Write-Output ("VM:'{0}' was stopped (not deallocated). Starting now" -f $VMResource.Name) }
      default { Write-Output ("Starting VM:'{0}'" -f $VMResource.Name) }
    }

    try {
      Start-AzVM -ResourceGroupName $VMResource.ResourceGroupName -Name $VMResource.Name | Out-Null
    }
    catch {
      Write-NveError $_ "An error occurred calling Start-AzVM"
    }

    Write-Output @"
$hr

  Lab Start-up successful

$hr
    
  IMPORTANT: Your Lab will automatically shutdown at $ShutdownTime UTC. Detailed below are the equivalent local times:
"@

        Get-NveLocalTimes -UtcTime $ShutDownTime | Format-Table -AutoSize

        Write-Output @"

  If you are still using your Lab, ensure you use the c--Extend_Lab_Time Runboook prior to this time to prevent the shutdown.
  
  The Lab will be extended in $AllocatedHours hr increments.
  
$hr

  Connections Methods

$hr
  
  Connect via Bastion RDP (Best Experience):
  ------------------------------------------
  Run the below commands in an Azure CLI shell (version 2.32+)

  az login
  az account set --subscription '$SubscriptionId'
  az network bastion rdp --name '$BastionName' --resource-group '$BastionRg' --target-resource-id '$($Lab.ResourceId)'

$hr
  
  Connect via Bastion HTTPS:
  --------------------------
  
  Browse VM Resources here: https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.Compute%2FVirtualMachines

    *Use the Connect feature associated to your VM. Only the Bastion option will work.

$hr
"@       
  } 
  catch {
      if($_.Exception.Info){ $_.Exception.Info() }
      Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }   
}