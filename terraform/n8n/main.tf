locals {
  tags = { project = "n8n-selfhost", managed_by = "terraform", purpose = "n8n-service" }
}
resource "oci_core_network_security_group" "n8n" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_ocid
  display_name   = "n8n-admin"
  freeform_tags  = local.tags
}
resource "oci_core_network_security_group_security_rule" "ssh" {
  network_security_group_id = oci_core_network_security_group.n8n.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = var.admin_ipv4_cidr
  stateless                 = false
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
resource "oci_core_instance" "n8n" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "n8n-service-arm"
  shape               = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 2
    memory_in_gbs = 6
  }
  preserve_boot_volume = true
  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 10
  }
  create_vnic_details {
    subnet_id        = var.subnet_ocid
    assign_public_ip = true
    hostname_label   = "n8n-service"
    nsg_ids          = [oci_core_network_security_group.n8n.id]
  }
  metadata = { ssh_authorized_keys = trimspace(var.ssh_public_key) }
  instance_options { are_legacy_imds_endpoints_disabled = true }
  freeform_tags = local.tags
  lifecycle { prevent_destroy = true }
  timeouts { create = "15m" }
}
resource "oci_core_volume" "data" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "n8n-data"
  size_in_gbs         = 50
  vpus_per_gb         = 10
  freeform_tags       = local.tags
  lifecycle { prevent_destroy = true }
}
resource "oci_core_volume_attachment" "data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.n8n.id
  volume_id       = oci_core_volume.data.id
  is_read_only    = false
  is_shareable    = false
}
