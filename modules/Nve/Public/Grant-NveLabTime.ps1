<#
.SYNOPSIS
  The Grant-NveLabTime function extends the time for a lab.

.DESCRIPTION
  This function modifies the VM auto shutdown schedule to be the provided allocated hours from the time the
  function is run. It will not accumulate hours, but rather set the shutdown time X amount of hours from now.

  The timezone used for managing the shutdown schedule is UTC. The shutdown time is converted and displayed 
  for all Australian states and territory timezones.

  This function calls a helper function 'Set-NveAutoShutdown' to set the auto shutdown schedule.

.NOTES
  Author: Ryan Shaw

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error
  
.LINK
  Module repo located at: TBA

.EXAMPLE
  Grant-NveLabTime -LabName 'my_lab' -OrgCode 'dev' -AllocatedHours 4 -BudgetName $BudgetName

  The 'my_lab' VM auto shutdown schedule will be set to shutdown 4 hrs from now, but only providing the
  budget has not exceeded its limit.
#>

function Grant-NveLabTime {

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
    $AllocatedHours,

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
      # Validate $LabName
      try {
        Get-AzResourceGroup -Name "nve-$OrgCode-$LabName-rg" | Out-Null
      }
      catch {
        Write-Output "Cannot find a Resource Group of:'nve-$OrgCode-$LabName-rg' using LabName:'$LabName'and Organisational Code:'$OrgCode'"

        $ExistingLabs = Get-AzResourceGroup -Name nve-$OrgCode-*
        
        if($ExistingLabs) {
          Write-Output "These are the Labs that are available to start:"

          foreach($ExistingLab in $ExistingLabs) {
            Write-Output ("`t - {0}" -f $ExistingLab.Split('-')[2])
          }
        }
        Write-NveError $_ "Cannot find a Resource Group of:'nve-$OrgCode-$LabName-rg' using LabName:'$LabName'and Organisational Code:'$OrgCode'"
      }
    }
    catch {
        Write-NveError $_ "Provided arguments failed input validation"
    }
    #endregion ParameterValidation

    Write-Output @"

$hr

    Commencing adding a $AllocatedHours hr time extension to the Lab

$hr

"@

    $ShutdownTime = Set-NveAutoShutdown -LabName $LabName -OrgCode $OrgCode -AllocatedHours $AllocatedHours

    Write-Output @"

$hr

  Your Lab time has been extended until $ShutdownTime UTC

$hr

  IMPORTANT: Your Lab will automatically shutdown at $ShutdownTime UTC. Detailed below are the equivalent local times:
"@

    Get-NveLocalTimes -UtcTime $ShutDownTime | Format-Table -AutoSize

    Write-Output @"

  If you are still using your Lab, ensure you use the c--Extend_Lab_Time Runboook prior to this time to prevent the shutdown.
  
  The Lab will be extended in $AllocatedHours hr increments.
    
$hr

"@



    Write-Output "`r`nTime extension successful. Time extended by $AllocatedHours hrs"
  } 
  catch {
    if($_.Exception.Info){ $_.Exception.Info() }
    Write-NveError $_ "An error occurred in the $($PSCmdlet.MyInvocation.InvocationName) function"
  }
}