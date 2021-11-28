# Purpose

This is IAC for Cloud Administration - Organizations, Accounts, Service Controls, etc. 

For now, this is AWS-only. Expanding into a multi-cloud architecture is high on my priority list. 

- Root Account
- Organization
- Service Control Policies
- Billing
    - Cost & Usage Report
- Sub Accounts (per Environment)
    - Dev
    - Prod
    - Stage
    
This repo provides overall infrastructure for the org: accounts and policies which host
various application environments. 

Any given project repository should include IAC which generates/manages the project's
dependencies (VPCs, databases, domains, queues, etc).

# Deployment Pipeline

Terraform Cloud monitors the **main** branch of this repository. Changes will be automatically deployed to AWS. 
