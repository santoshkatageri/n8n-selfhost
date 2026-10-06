# Separate AMD Ansible controller

User chose a free AMD VM with Ansible CLI on 6 October 2026. This stack declares exactly one fixed `VM.Standard.E2.1.Micro` controller, its 50 GB boot volume (part of the instance) and an automation VCN with restricted management access. The existing `automations` compartment is an input and remains owned by its own stack.

The free AMD micro shape has 1 GB RAM and a 1/8-OCPU baseline. It is for a small CLI controller. AWX/OLAM are not installed; OLAM's documented minimum is 4 GB RAM and two CPU cores. The planned Ampere n8n service remains separate.

Execute only through OCI Resource Manager in Ashburn, Terraform 1.5.x and pinned OCI provider 9.8.0. No API credentials or private SSH key belong in source, uploads or state. Supply only the public key and owner-approved `/32` SSH source. Expected first plan: **8 to add, 0 to change, 0 to destroy**. Review and approve the specific single-address SSH rule before applying the saved plan.

Resources: VCN, internet gateway, egress route table, outbound-only custom security list, management subnet, admin NSG, its one TCP/22 rule, and controller. No paid NAT/LB, data volume, backups, DNS, tunnel, IAM policy or n8n service. The subnet uses only the custom list, so the VCN default security list is not applied.

Ansible must perform host/software configuration after SSH access is verified. The boot disk is preserved on instance removal, and the VM has `prevent_destroy`. Keep the state and plan in Resource Manager. Do not launch another resource or use a paid fallback after a capacity failure. Later n8n infrastructure must consume these shared network outputs rather than creating a third VCN.
