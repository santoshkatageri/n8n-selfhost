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

variable "existing_compartment_ocid" {
  description = "Existing automations compartment to adopt; set privately in Resource Manager."
  type        = string
  validation {
    condition     = startswith(var.existing_compartment_ocid, "ocid1.compartment.")
    error_message = "Supply the verified existing compartment OCID."
  }
}

# Adopt the existing compartment without publishing the account-specific OCID.
import {
  to = oci_identity_compartment.automations
  id = var.existing_compartment_ocid
}
