############################################################################################
#
#                                 Stop_All_VMs Runbook
#
############################################################################################
#
# 
#   This Runbook is triggered once the Subscription level budget limit is reached.
#   All Lab VMs will be deallocated immediately. 
#   The VMs will not be able to start again until the next budget cycle.
#  
#
############################################################################################
#
#
#
############################################################################################
Param (
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)

$ErrorActionPreference = 'Stop'

$hr = "_________________________________________________________________________________________________________"

$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
  $ErrorActionPreference = "stop"

  # Gather budget details
  # if ($WebhookData) {
  #   # Get the data object from WebhookData
  #   $WebhookBody = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
  #   $Data = $WebhookBody.Data
  # }
  
  $FailedVMs = New-Object System.Collections.Generic.List[pscustomobject]
 
  Write-Output "Commencing VM Shutdown`r$hr`r"

  $VMs = Get-AzVM -Status | Where-Object PowerState -ne 'VM deallocated'

  if($VMs) {
    foreach($VM in $VMs) {
      Write-Output ("Stopping VM:'{0}'" -f $VM.Name)
      
      try {
        $Failed = Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force | Where-Object Status -ne 'Succeeded'

        if($Failed) {
          $FailedVMs.Add([PSCustomObject]@{
            Name = $VM.Name
            ResourceGroupName = $VM.ResourceGroupName
            Location = $VM.Location
            PreviousState = $VM.PowerState
            State = $Failed.Status
          })
        }
        else {
          Write-Output ("VM: {0} successfully deallocated" -f $VM.Name )
        }
      }
      catch {
        $FailedVMs.Add([PSCustomObject]@{
          Name = $VM.Name
          ResourceGroupName = $VM.ResourceGroupName
          Location = $VM.Location
          PreviousState = $VM.PowerState
          State = 'UnhandledException'
        })
      }
    }

    if($FailedVMs) {
      foreach($VM in $FailedVMs) {
        Write-Warning ("VM Failed. Name:{0}. RG:{1}. loation:{2}. Current State:{3}. Previous State: {4}. " `
          -f $VM.Name, $VM.ResourceGroupName, $VM.Location, $VM.State, $VM.PreviousState)
      }
    }
  }
  else {
    Write-Output "`rNo VMs currently running"
  }
  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}

# {
#   "schemaId": "AIP Budget Notification",
#   "data": {
#       "SubscriptionName": "",
#       "SubscriptionId": "",
#       "EnrollmentNumber": "",
#       "DepartmentName": "",
#       "AccountName": "",
#       "BillingAccountId": "",
#       "BillingProfileId": "",
#       "InvoiceSectionId": "",
#       "ResourceGroup": "",
#       "SpendingAmount": "",
#       "BudgetStartDate": "",
#       "Budget": "",
#       "Unit": "",
#       "BudgetCreator": "",
#       "BudgetName": "",
#       "BudgetType": "",
#       "NotificationThresholdAmount": ""
#   }
# }