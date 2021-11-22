# Purpose

This is IAC for the AWS Organization and any sub-accounts that may be needed, including
SCP definition and attachment. 

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

TODO - Evaluate networking patterns and consider centralizing access. Example:
```
- Create a VPC in the root account and attach a nat gateway.
- Create a VPC in each sub-account and set up VPC peering/transit.
- Configure all VPCs to use the root account's nat gateway for outbound traffic. 
- This prevents the need for a separate nat gateway ($$/month) for each subnet, and would allow for better filtering/inspection.
```