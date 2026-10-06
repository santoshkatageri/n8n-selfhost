# Existing shared automation network

The owner authorized deletion of the AMD controller and its boot disk on 6 October 2026. This directory now declares only the seven existing network resources. Cleanup is complete: the saved-plan apply succeeded, and both instance and boot volume report TERMINATED.

Retirement procedure completed using the existing Resource Manager stack and state. First apply the prepared transition configuration setting the old instance's `preserve_boot_volume` and `prevent_destroy` to false. Review that transition as an in-place update only. Then apply this network-only configuration, reviewing exactly one instance deletion and no network changes. Verify the boot disk is deleted; if it survives, remove only the verified controller disk explicitly. Never destroy the whole stack. Private transition archives preserve the deployed input defaults, avoiding unrelated variable changes.

Keep the VCN, subnet, internet gateway, route table, outbound-only security list, admin NSG and existing SSH rule. The new n8n stack consumes network outputs and owns its own restricted NSG. State remains in Resource Manager.
