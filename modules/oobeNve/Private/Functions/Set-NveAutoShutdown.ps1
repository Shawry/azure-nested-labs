<#
.SYNOPSIS
    The Set-NveAutoShutdown function sets the AutoShutdown schedule for a given Lab.

.DESCRIPTION
    This function enables and sets the time for the Microsoft.DevTestLab/schedules object which controls the AutoShutdown
    policy of each VM in a Class set.


.PARAMETER LabName
    Type: [string]
    The unique Lab Name of the Lab.

.PARAMETER AllocatedHours
    Type: [UInt32]
    The number of hours before the VM will shutdown

.EXAMPLE
    Set-NveAutoShutdown -LabName 'ryans_lab' -AllocatedHours 4

.NOTES
    Author: Ryan Shaw (ryan.shaw@oobe.com.au) | Company: oobe, a Fujitsu company

.LINK
    Azure DevOps repo: https://dev.azure.com/oobe-lab/oobeLab/_git/NVE
#>
function Set-NveAutoShutdown {
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

      [Parameter()]
      [ValidateRange(1,23)]
      [UInt16]
      $AllocatedHours
  )

  $ErrorActionPreference = 'Stop'

  try {
    #region ParameterValidation
    # Validate $LabName
    try {
      $LabName = $LabName.ToLower()
      $OrgCode = $OrgCode.ToLower()
      $RG = Get-AzResourceGroup -Name "nve-$OrgCode-$LabName-rg"
    }
    catch {
      Write-NveError $_ "Cannot find a Resource Group of:'nve-$OrgCode-$LabName-rg' using LabName:'$LabName'and Organisational Code:'$OrgCode'"
    }
    #endregion ParameterValidation
    
    $ShutDownTime = (Get-Date).AddHours($AllocatedHours).ToString('hhmm')

    $Params = @{
      ResourceGroupName = $RG.ResourceGroupName
      ResourceType      = 'Microsoft.DevTestLab/schedules'
      Tag               = @{
        "Org" = $OrgCode
        "Lab" = $LabName
      }
    }
    $Schedule = Get-AzResource @Params

    if(-Not $Schedule) {
      throw "The AutoShutdown Schedule associated to Lab:'$LabName' cannot be found. Cannot continue. Seek admin help to resolve this issue."
    }
    
    $TemplateFile = Export-AzResourceGroup -ResourceGroupName $RG.ResourceGroupName -Resource $Schedule.ResourceId -Path $HOME -Force
    $Template = Get-Content $TemplateFile.Path -Raw | ConvertFrom-Json -Depth 20 -AsHashtable
    $Template.resources.properties.status = 'Enabled'
    $Template.resources.properties.dailyRecurrence.time = $ShutDownTime
    
    $ResourceSplat = @{
      ResourceGroupName   = $RG.ResourceGroupName
      ResourceType        = 'Microsoft.Compute/virtualMachines'
    }
    $VMResource = Get-AzResource @ResourceSplat

    $Params = @{
      "virtualMachines_vm_nve_${OrgCode}_${LabName}_externalid" = $VMResource.Id
      "schedules_shutdown_computevm_vm_nve_${OrgCode}_${LabName}_name" = "shutdown-computevm-vm-nve-${OrgCode}-${LabName}"
    }
    try {
      $Result = New-AzResourceGroupDeployment -ResourceGroupName $RG.ResourceGroupName -TemplateObject $Template -TemplateParameterObject $Params
    }
    catch {
        Write-NveError $_ "An error occurred requesting a new Resource Group Deployment"
    }

    if(-Not ($Result.ProvisioningState -eq 'Succeeded')) {
      throw "Failed to set AutoShutdown schedule. Cannot Continue."
    }

    $ShutdownTime.Insert(2,':')
  }
  catch {
      Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}