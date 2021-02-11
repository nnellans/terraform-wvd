# terraform-wvd
This repo contains example code to help you deploy Windows Virtual Desktop (WVD) in Azure using Terraform.

Included are examples for the following resources:
- Host Pools (both types: Pooled & Personal)
- Application Groups (both types: Desktop & RemoteApp)
- Workspaces
- Session Hosts / Virtual Machines
- Virtual Machine Extension to join the Session Host VM to a Active Directory Domain
- Virtual Machine Extension for PowerShell DSC to automatically install the WVD Agents and register the Session Host VM to a Host Pool
