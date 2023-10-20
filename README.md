# azure-nested-labs
Azure hosted, self-administered Hyper-V nested virtualisation labs managed by Automation Account runbooks.

## Setup
1. Import the Nve module into an Automation Account (PowerShell v7)
2. Copy the Runbooks to the Automation Account
3. Setup the #EnvironmenVariables in each runbook to suit your configuration
4. Make sure the Automation Account has the privileges it needs to build VMs in the network
5. Make sure you setup a unique gallery name and change the #EnvironmenVariables to match
6. Provide users of the labs Reader on the Resource Group that the Automation Account belongs to
7. Provide users Automation Job Operator to run the runbooks
8. Copy the templates to the storage accout outlined in the NewLab runbook:. Changind the StorageAccountName and TemplateContainer folder
9. Make sure the Automation Account has Storage Blob Contributor on the templates container