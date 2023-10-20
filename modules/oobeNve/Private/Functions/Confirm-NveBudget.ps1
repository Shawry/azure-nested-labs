function Confirm-NveBudget {

  Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name
  )

  $ErrorActionPreference = 'Stop'

  try {
    $Budget = Get-AzConsumptionBudget -Name $Name
  }
  catch {
    Write-NveError $_ "Failed to get Budget details. Runbook execution cannot continue. Seek admin help for this error"
  }

  if($Budget.CurrentSpend.Amount -ge $Budget.Amount) {

    Write-Output "The budget limit has been exceeded for the current budget cycle. Budget: $($Budget.Name)"
    Write-Output "No Labs can be provisioned/started/extended once the limit is reached."
    Write-Output "The new budget cycle starts on $($Budget.TimePeriod.EndDate), at which time you will be able to use the Labs again."
    throw "The budget limit has been exceeded for the current budget cycle."
  }
}