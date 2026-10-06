variable "compartment_ocid" {
  type        = string
  description = "Existing automations compartment. Managed by the separate compartment stack."
  validation {
    condition     = startswith(var.compartment_ocid, "ocid1.compartment.")
    error_message = "Use the verified automations compartment."
  }
}
variable "image_ocid" {
  type        = string
  description = "Pinned Oracle-Linux-9.8-2026.09.18-0 platform image compatible with E2.1.Micro."
  default     = "ocid1.image.oc1.iad.aaaaaaaag3xchijubmnnvvd2mwlsaftbwtlbpcge5mpilv4xcujc37iis6xq"
  validation {
    condition     = startswith(var.image_ocid, "ocid1.image.oc1.iad.")
    error_message = "Supply the verified Ashburn platform image OCID."
  }
}
variable "ssh_public_key" {
  type        = string
  description = "Dedicated admin SSH public key only; private key stays local."
  validation {
    condition     = startswith(trimspace(var.ssh_public_key), "ssh-ed25519 ")
    error_message = "Supply the dedicated Ed25519 public key, never a private key."
  }
}
variable "admin_ipv4_cidr" {
  type        = string
  description = "Owner-approved current Mac public IPv4 address with /32; no broad SSH ingress."
  validation {
    condition     = can(cidrhost(var.admin_ipv4_cidr, 0)) && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/32$", var.admin_ipv4_cidr))
    error_message = "Use one approved IPv4 /32 address."
  }
}

variable "availability_domain" {
  type        = string
  description = "Tenant-prefixed Ashburn AD-2 name verified for the free AMD micro allowance."
  validation {
    condition     = endswith(var.availability_domain, ":US-ASHBURN-AD-2")
    error_message = "Use the verified tenant-prefixed Ashburn AD-2 name."
  }
}
