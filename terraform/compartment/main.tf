terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "= 9.8.0"
    }
  }
}

# OCI Resource Manager supplies the authenticated context and stores state.
provider "oci" {
  region = var.region
}

variable "tenancy_ocid" {
  description = "The verified parent OCI tenancy OCID, supplied by Resource Manager."
  type        = string
  validation {
    condition     = startswith(var.tenancy_ocid, "ocid1.tenancy.")
    error_message = "Supply the verified OCI tenancy OCID."
  }
}

variable "region" {
  description = "Verified tenancy home region."
  type        = string
  default     = "us-ashburn-1"
  validation {
    condition     = var.region == "us-ashburn-1"
    error_message = "Use the verified Ashburn home region."
  }
}

resource "oci_identity_compartment" "automations" {
  compartment_id = var.tenancy_ocid
  name           = "automations"
  description    = "compartment for n8n automations"
  enable_delete  = false
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [defined_tags, freeform_tags]
  }
}

output "automations_compartment_ocid" {
  description = "Parent compartment for the later n8n Terraform infrastructure stack."
  value       = oci_identity_compartment.automations.id
}

output "automations_compartment_name" {
  value = oci_identity_compartment.automations.name
}

# The compartment is already imported in the existing Resource Manager state.
# Keep the same stack/state when changing to Git source.
