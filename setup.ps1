$Context = Get-AzContext

## Automation Account Resource Group
$Params = @{
  Name = "rg-nve-labs-ae-001"
  Location = "australiaeast"
}
$ResourceGroup = New-AzResourceGroup @Params
if($ResourceGroup) { Write-Output "successfully created resource group: $($ResourceGroup.ResourceGroupName)" }

## User Assigned ID for the Automation Account
$Params = @{
  ResourceGroupName = $ResourceGroup.ResourceGroupName
  Name = "uai-nve-labs-001"
  Location = $ResourceGroup.Location
}
$UserAssignedIdentity = New-AzUserAssignedIdentity @Params
if($UserAssignedIdentity) { Write-Output "successfully created user assigned identity: $($UserAssignedIdentity.Name)" }

## Automation Account
$Params = @{
  Name = "aa-nve-labs-001"
  Location = $ResourceGroup.Location
  ResourceGroupName = $ResourceGroup.ResourceGroupName
  AssignUserIdentity = $UserAssignedIdentity.Id
}
$AutomationAccount = New-AzAutomationAccount @Params
if($AutomationAccount) { Write-Output "successfully created automation account: $($AutomationAccount.Name)" }

## Lab User Entra ID Security Group
$Params = @{
  DisplayName = "NVE Lab Users"
  MailNickname = "nve-lab-users"
  Description = "<Description for the Lab User Group>"
}
$SecurityGroup = New-AzADGroup @Params
if($SecurityGroup) { Write-Output "successfully created security group: $($SecurityGroup.DisplayName)" }

## Virtual Network Resource Group
$Params = @{
  Name = "rg-nve-labs-net-ae-001"
  Location = $ResourceGroup.Location
}
$NetworkResourceGroup = New-AzResourceGroup @Params
if($NetworkResourceGroup) { Write-Output "successfully created resource group: $($NetworkResourceGroup.ResourceGroupName)" }

## Subnet Config
$Params = @{
  Name = "snet-nve-labs-001"
  AddressPrefix = "10.0.0.0/24"
}
$SubnetConfig = New-AzVirtualNetworkSubnetConfig @Params

$Params = @{ 
  Name = "vnet-nve-labs-001"
  ResourceGroupName = $NetworkResourceGroup.ResourceGroupName
  Location = $NetworkResourceGroup.Location
  AddressPrefix = "10.0.0.0/16"
  Subnet = $SubnetConfig
}
$VirtualNetwork = New-AzVirtualNetwork @Params
if($VirtualNetwork) { Write-Output "successfully created virtual network: $($VirtualNetwork.Name)" }

## NIC Network Security Group
$Params = @{
  Name = "nsg-nve-labs-001"
  ResourceGroupName = $NetworkResourceGroup.ResourceGroupName
  Location = $NetworkResourceGroup.Location
}
$NetworkSecurityGroup = New-AzNetworkSecurityGroup @Params
if($NetworkSecurityGroup) { Write-Output "successfully created network security group: $($NetworkSecurityGroup.Name)" }

## Azure Compute Gallery
$Params = @{
  Name = "Dev_NVE_Labs_Gallery"
  ResourceGroupName = $ResourceGroup.ResourceGroupName
  Location = $ResourceGroup.Location
  Description = "<Description for the Gallery>"
}
$Gallery = New-AzGallery @Params
if($Gallery) { Write-Output "successfully created gallery: $($Gallery.Name)" }

## Lab Users Reader Role Assignment
$Params = @{
  ResourceGroupName = $ResourceGroup.ResourceGroupName
  ObjectId = $SecurityGroup.Id
  RoleDefinitionName = "Reader"
}
$LabUsersReader = New-AzRoleAssignment @Params
if($LabUsersReader) { Write-Output "successfully assigned role: $($LabUsersReader.RoleDefinitionName) to group: $($SecurityGroup.DisplayName)" }

## Lab Users Automation Job Operator Role Assignment
$Params = @{
  Scope = "/subscriptions/$($Context.Subscription.SubscriptionId)/resourcegroups/$($ResourceGroup.ResourceGroupName)/Providers/Microsoft.Automation/automationAccounts/$($AutomationAccount.AutomationAccountName)"
  ObjectId = $SecurityGroup.Id
  RoleDefinitionName = "Automation Job Operator"
}
$LabUsersJobOperator = New-AzRoleAssignment @Params
if($LabUsersJobOperator) { Write-Output "successfully assigned role: $($LabUsersJobOperator.RoleDefinitionName) to group: $($SecurityGroup.DisplayName)" }

## Automation Account Managed Id Subscription Contributor Role Assignment 
$Params = @{
  ObjectId = $UserAssignedIdentity.PrincipalId
  RoleDefinitionName = "Contributor"
}
$ManagedIdSubContributor = New-AzRoleAssignment @Params
if($ManagedIdSubContributor) { Write-Output "successfully assigned role: $($ManagedIdSubContributor.RoleDefinitionName) to managed identity: $($UserAssignedIdentity.Name)" }