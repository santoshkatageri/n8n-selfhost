# n8n service host

Prepared, not deployed. Terraform owns one Ubuntu ARM64 A1 VM (2 OCPUs / 6 GB), a 50 GB boot disk, a protected 50 GB data disk and its paravirtualized attachment, and an NSG allowing SSH only from the verified Mac IPv4 /32. The existing subnet supplies outbound access. No application ports are exposed. Ansible from the Mac will configure the host later.

Before apply: verify actual tenancy-wide usage, A1 quota and host capacity, Ubuntu image compatibility/eligibility and exact image OCID, existing network outputs and current Mac IP. No paid shape fallback. Review the expected five additions and no replacements/deletions. State belongs in OCI Resource Manager. Keep input values, plans and state private. Do not format a disk until its identity and blank state are verified.

Capacity check on 6 October 2026: regional quota has 2 OCPUs and 12 GB free, but every Ashburn AD reports OUT_OF_HOST_CAPACITY for the requested 2 OCPUs / 6 GB. No apply attempted. Exact Ubuntu 24.04 ARM64 image is pinned in variables.tf.
