# azure-nested-labs
An Azure Automation Account Runbook system to manage a Nested Virtualisation Environment (NVE) labs.

## Intro
Before diving into it, let me explain what this is. 

I've built an Azure Automation Account Runbook system that allows users to provision, modify, recapture and share their own labs. Below are some of the key features of this system:
1. Self-service lab provisioning
2. Self-service lab modification
3. Self-service lab image capture
4. Self-service password resets
5. Self-service lab start/shutdown
6. Time-based auto shutdown of VMs
7. Self-service lab time extensions
8. Budget driven auto shutdown of VMs
9. Budget driven lab disablement

## Architecture
The system is built around a single Azure Automation Account. The Automation Account has a number of Runbooks that are used to manage the labs. The Runbooks include:

- a--NewLab
- b--Start_Lab
- c--Extend_Lab_Time
- d--Stop_Lab
- e--Add_Lab_DataDisks
- f--Remove_Lab_DataDisks
- g--Set_Lab_VmSize
- h--Remove_Lab
- i--Capture_New_Image
- j--Update_Source_Image
- k--Remove_Image
- l--Reset_Lab_Password
- m--List_Available_resources

The required supporting infrastructure includes:
- Azure Automation Account
- Azure Blob Storage Account
- Azure Compute Gallery
- Azure Virtual Network


## Quickstart


## Setup
1. Import the Nve module into an Automation Account (PowerShell v7)
2. Copy the Runbooks to the Automation Account
3. Setup the #EnvironmenVariables in each runbook to suit your configuration
4. Make sure the Automation Account has the privileges it needs to build VMs in the network
5. Make sure you setup a unique gallery name and change the #EnvironmenVariables to match
6. Provide users of the labs Reader on the Resource Group that the Automation Account belongs to
7. Provide users Automation Job Operator to run the runbooks
8. Copy the templates to the storage account outlined in the NewLab runbook:. Changing the StorageAccountName and TemplateContainer folder
9. Make sure the Automation Account has Storage Blob Contributor on the templates container