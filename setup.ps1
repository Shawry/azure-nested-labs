

## Azure Automation Account
$Params = @{
  Name = "<Enter a name for the Automation Account>"
  Location = "<Azure Region> ie. Australia East"
  ResourceGroupName = "<Resource Group name for the Automation Account>"
}
$Params = @{
  Name = "aa-nve-labs-001"
  Location = "australiaeast"
  ResourceGroupName = "rg-nve-labs-ae-001"
}
New-AzAutomationAccount @Params

## Lab User Entra ID Security Group
$Params = @{
  DisplayName = "<Display Name for the Lab Users Group>"
  GroupType = "Security"
  Description = "<Description for the Lab User Group>"
}
$Params = @{
  DisplayName = "NVE Lab Users"
  GroupType = "Security"
  Description = "<Description for the Lab User Group>"
}
New-AzADGroup @Params