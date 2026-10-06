# Automations compartment

This configuration imports the existing `automations` compartment created by the user on 6 October 2026. It must not create a second compartment. The only managed resource is `oci_identity_compartment.automations`, under the verified personal tenancy. It creates no compute, volumes, network, DNS routes or Access policies.

Canonical code: `/Users/spk/workspace/prepare/n8n-selfhost/terraform/compartment`.
Execution and state: OCI Resource Manager, using the signed-in console identity. Record actual stack and job IDs in the project evidence. Do not run a competing local apply.

Provider: OCI 9.8.0, pinned in the provider lock file. Resource Manager: Terraform 1.5.x. Upload source and lock file only, without credentials or state. The future n8n infrastructure stack must take this compartment OCID as input and must not manage this compartment again.

Expected plan: **1 to import, 0 to add, 0 to change, 0 to destroy**. Review the exact OCID before applying the saved plan. The existing description is preserved, tag changes are ignored, `prevent_destroy` is enabled, and `enable_delete` is false.

Known parent tenancy: `<private-tenancy-ocid>`.
Known compartment: `<private-compartment-ocid>`.

For Git sourcing, set `existing_compartment_ocid` privately to the already imported compartment. Preserve this stack and its state.
