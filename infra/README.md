# Test virtual machine (vmtest, dev)

## Purpose and scope

One small Linux virtual machine in Azure, used to test an infrastructure workflow end to
end. It is not meant to run a workload. Everything lives in one resource group so that
deleting the group removes the whole test.

## Architecture and dependencies

| Resource | Name | Notes |
| --- | --- | --- |
| Resource group | `rg-vmtest-dev-frc` | Created by this deployment |
| Network security group | `nsg-vmtest-dev-frc` | Azure default rules only: nothing inbound from the internet |
| Virtual network | `vnet-vmtest-dev-frc` | `10.50.0.0/24`, subnet `snet-vm` `10.50.0.0/27`, private subnet |
| Network interface | `nic-vmtest-dev-frc` | Private IP only |
| Virtual machine | `vm-vmtest-dev-frc` | Ubuntu Server 24.04 LTS, `Standard_F1als_v7`, 30 GiB Standard SSD |

Order: resource group, network security group, virtual network, network interface,
virtual machine. Bicep works the order out from the references.

- `main.bicep` (subscription scope) creates the resource group and calls the modules.
- `modules/network.bicep` holds the network security group and the virtual network.
- `modules/vm.bicep` holds the network interface and the virtual machine.

## Parameters

Values are in `parameters/dev.bicepparam`.

| Parameter | Value | Source |
| --- | --- | --- |
| `location` | `francecentral` | Chosen for this test |
| `environment`, `workload`, `regionCode` | `dev`, `vmtest`, `frc` | Naming convention `<type>-<workload>-<environment>-<region>` |
| `tags` | environment, workload, owner | Tagging convention |
| `vnetAddressPrefix`, `subnetAddressPrefix` | `10.50.0.0/24`, `10.50.0.0/27` | Chosen so they do not overlap the other networks in the subscription |
| `vmSize` | `Standard_F1als_v7` | Smallest size available to the subscription in this region |
| `adminUsername` | `azureuser` | Default |
| `adminSshPublicKey` | not stored | Read from the environment variable `IAC_VM_SSH_PUBLIC_KEY` at deployment time |

## Prerequisites and permissions

- Azure CLI and Bicep CLI.
- Permission to create resource groups and resources in the subscription (for example
  Contributor at subscription scope).
- An SSH public key in `IAC_VM_SSH_PUBLIC_KEY`.
- The VM size must support generation 2 images and the NVMe disk controller.

## Validation and deployment

```text
bicep build infra/main.bicep
bicep build-params infra/parameters/dev.bicepparam
bicep lint infra/main.bicep
az deployment sub what-if --location francecentral --template-file infra/main.bicep --parameters infra/parameters/dev.bicepparam
```

Deploy only after reviewing the what-if output. This is a subscription-scope deployment.

## Outputs

- `resourceGroupName`: the resource group.
- `vmId`: resource ID of the virtual machine.
- `vmPrivateIp`: its private IP address.

No output contains a secret.

## Cost and security

- Cost: about 0.06 EUR per hour for compute while the VM runs, plus about 2.3 EUR per
  month for the disk while it exists (public list prices, October 2026). Deallocating
  the VM stops the compute charge, not the disk charge.
- No public IP address and no inbound access from the internet.
- The subnet is private and there is no NAT gateway, so the VM has no outbound internet
  access: no package updates, and extensions that download from the internet will fail.
- SSH key sign-in only; password sign-in is disabled. No secrets are stored anywhere.
- Trusted Launch (secure boot and vTPM) is on. Encryption at host is not enabled.
- The VM has a system-assigned managed identity with no role assignments.
- Boot diagnostics use Azure-managed storage. There is no Log Analytics workspace.
- No backups.

## Rollback, recovery and cleanup

- A failed deployment can leave some resources created. Fix the cause and deploy again;
  the deployment is idempotent.
- There is no rollback to a previous state and no data to restore.
- Cleanup: delete the resource group `rg-vmtest-dev-frc`. That removes the VM, its disk,
  the network interface, the virtual network and the network security group, and cannot
  be undone.
