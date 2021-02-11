# terraform-wvd
This repo contains example code to help you deploy Windows Virtual Desktop (WVD) in Azure using Terraform.

Included are examples for the following:
- Creating Host Pools (both types: Pooled & Personal)
- Creating Application Groups (both types: Desktop & RemoteApp)
- Assigning Users or Groups to Application Groups
- Creating Workspaces
- Registering an Application Group to a Workspace
- Creating Session Hosts / Virtual Machines
- Using a Virtual Machine Extension to join the Session Host VM to a Active Directory Domain
- Using a Virtual Machine Extension for PowerShell DSC to automatically install the WVD Agents and register the Session Host VM to a Host Pool
