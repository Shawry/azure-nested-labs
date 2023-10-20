<#
.SYNOPSIS
  The Reset-NveLabPassword function will reset the provided admin accounts credentials on a VM

.DESCRIPTION
  This function will unlock and reset the password on the account name provided with the $Username parameter.
  If the user does not exist it will be created.

  The account password will be returned in plain text.

.NOTES
  Author: Ryan Shaw (ryan.shaw@oobe.com.au) | oobe, a Fujitsu company

  IMPORTANT: This function will only run if Confirm-NveBudget (called at the start) does not throw a terminating error
  WARNING: The account password will be returned in plain text.

.LINK
  Module repo located at: TBA

.EXAMPLE
  $Params = @{
    OrgCode     = 'dni'
    LabName     = 'my_lab'
    Username    = 'labadmin'
    BastionName = 'bas-nve-prod-aue-001'
    BastionRg   = 'rg-net-prod-aue-001'
  }
  Reset-NveLabPassword @Params

  The 'labadmin' account will be reset on the 'my_lab' lab under the 'dni' organisation
#>


function Reset-NveLabPassword {
  
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
    $Username,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BastionName,
    
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BastionRg,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $BudgetName
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

    try {
      $PowerState = Get-AzVM -ResourceGroupName $Lab.ResourceGroupName -Name $Lab.VmName -Status |
        Select-Object -ExpandProperty Statuses | Where-Object Code -match '^PowerState' | Select-Object -ExpandProperty DisplayStatus
    }
    catch {
      Write-NveError $_ "Unable to get the VM state"
    }
    
    if($PowerState -ne 'VM running') {
      Write-Output "Lab not running. Current state: $PowerState. Ensure the Lab is started first."
      throw "Lab not running. Current state: $PowerState. Ensure the Lab is started first."
    }

    $Password = Get-NveRandomPassword
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)

    try {
      $Params = @{
          ResourceGroupName = $Lab.ResourceGroupName
          Location = $Lab.Location
          VMName = $Lab.VmName
          Name = "VmAccessAgent"
          Credential = $Credential
          TypeHandlerVersion = "2.4"
      }
      Set-AzVMAccessExtension @Params | Out-Null
    }
    catch {
      Write-NveError $_ "Setting password via VM Access Extension failed."
    }
    
    Write-Output @"

$hr

  Lab Details:

$hr

"@

    [PSCustomObject]@{
      IpAddress = $Lab.IpAddress
      Computername = $Lab.ComputerName
      Username = $Lab.AdminUsername
      VmName   = $Lab.VmName
      Login = ("NVE\{0}" -f $Lab.AdminUsername)
      Password = $Password
    }

    Write-Output @"
  
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