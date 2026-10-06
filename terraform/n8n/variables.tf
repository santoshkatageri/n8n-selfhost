variable "compartment_ocid" { type = string }
variable "availability_domain" { type = string }
variable "subnet_ocid" { type = string }
variable "vcn_ocid" { type = string }
variable "image_ocid" {
  default     = "ocid1.image.oc1.iad.aaaaaaaa6o52ajhkewa2syfadrxel5b7tfwi5qdm45gl4ykwbqut25tvdxrq"
  type        = string
  description = "Pinned Canonical-Ubuntu-24.04-aarch64-2026.09.18-0 platform image, verified compatible with A1 in Ashburn."
}
variable "ssh_public_key" {
  type = string
  validation {
    condition     = startswith(trimspace(var.ssh_public_key), "ssh-ed25519 ")
    error_message = "Provide the dedicated public SSH key only."
  }
}
variable "admin_ipv4_cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.admin_ipv4_cidr, 0)) && can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/32$", var.admin_ipv4_cidr))
    error_message = "Restrict SSH to the owner's verified single IPv4 /32."
  }
}
