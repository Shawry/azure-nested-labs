############################################################################################
#
#                               Remove_Lab_DataDisks Runbook
#
############################################################################################
#
# Parameters:
#   LABNAME       - Enter the Unique LabName of the Lab you want to remove the Data Disks 
#                   from.
#
#   LUNS          - Enter the LUN, or list of comma separated LUNs for the Data Disks you 
#                   want removed. 
#                   See Disk Management or Server Manager on the Lab VM to get the LUN IDs.
#
# Use the Remove_Lab_DataDisks Runbook to remove Data Disks from an existing Lab VM. 
#
# IMPORTANT: This action is irreversible.
#
############################################################################################
#
#
#
############################################################################################
Param(
    [Parameter(Mandatory)]
    [string]
    $LabName,

    [Parameter(Mandatory)]
    [string]
    $LUNs = 'eg 0,3'
)

# Default value is just an example
if($LUNs -eq 'eg 0,3') { $LUNs = $null }

$ErrorActionPreference = 'Stop'

#region EnvironmentVariables
$OrgCode        = 'dni' # Defence 'n' Intel
#endregion EnvironmentVariables

$hr = "_________________________________________________________________________________________________________"

try {
  Write-Output ("`rScript started at: '{0}'`r$hr`r" -f (Get-Date -f 'o'))
    
  $AzureContext = (Connect-AzAccount -Identity).context
  $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext

  Import-Module 'C:\usr\src\PSModules\oobeNve\oobeNve\oobeNve.psd1'

  # Type cast LUNs string input to list of positive integers
  $LunList = New-Object System.Collections.Generic.List[UInt16]
  $LunArr = $LUNs.split(',').trim()
        
  foreach($Lun in $LunArr) {
    try {
      $LunList.Add($Lun)
    }
    catch {
      throw "Cannot convert LUNs input of:'$Lun' to a positive integer. Check your input and try again. Error: $PSItem"
    }
  }
  
  Remove-NveDataDisk -LabName $LabName -OrgCode $OrgCode -LUNs $LunList

  Write-Output ("`r$hr`rScript completed at: '{0}'" -f (Get-Date -f 'o'))
} 
catch {
    Write-Output "`r$hr`rRunbook execution encountered an error. Check error log for details."
    Write-Output ("`r$hr`rScript failed at: '{0}'" -f (Get-Date -f 'o'))
    Write-Error $PSItem
}