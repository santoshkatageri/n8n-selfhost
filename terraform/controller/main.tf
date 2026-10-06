locals {
  tags = {
    project    = "n8n-selfhost"
    managed_by = "terraform"
    purpose    = "ansible-controller"
  }
}
resource "oci_core_vcn" "automations" {
  compartment_id = var.compartment_ocid
  display_name   = "automations-vcn"
  cidr_blocks    = ["10.70.0.0/16"]
  dns_label      = "automations"
  freeform_tags  = local.tags
}
resource "oci_core_internet_gateway" "egress" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.automations.id
  display_name   = "automations-internet"
  enabled        = true
  freeform_tags  = local.tags
}
resource "oci_core_route_table" "egress" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.automations.id
  display_name   = "automations-egress"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.egress.id
  }
  freeform_tags = local.tags
}
resource "oci_core_security_list" "outbound_only" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.automations.id
  display_name   = "automations-outbound-only"
  # No ingress blocks: administrative SSH is restricted by the attached NSG.
  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = false
    description      = "OS updates and outbound automation traffic."
  }
  freeform_tags = local.tags
}
resource "oci_core_subnet" "management" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.automations.id
  display_name               = "automations-management-subnet"
  cidr_block                 = "10.70.10.0/24"
  dns_label                  = "management"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.egress.id
  # Attach only the custom list. The VCN's default public SSH rule is unused.
  security_list_ids = [oci_core_security_list.outbound_only.id]
  freeform_tags     = local.tags
}
resource "oci_core_network_security_group" "admin" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.automations.id
  display_name   = "ansible-controller-admin"
  freeform_tags  = local.tags
}
resource "oci_core_network_security_group_security_rule" "admin_ssh" {
  network_security_group_id = oci_core_network_security_group.admin.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = var.admin_ipv4_cidr
  stateless                 = false
  description               = "Owner-approved SSH from one current Mac public IPv4 address."
  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
resource "oci_core_instance" "controller" {
  compartment_id       = var.compartment_ocid
  availability_domain  = var.availability_domain
  display_name         = "ansible-controller-amd"
  shape                = "VM.Standard.E2.1.Micro"
  preserve_boot_volume = true
  source_details {
    source_type             = "image"
    source_id               = var.image_ocid
    boot_volume_size_in_gbs = 50
    boot_volume_vpus_per_gb = 10
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.management.id
    assign_public_ip = true
    private_ip       = "10.70.10.10"
    hostname_label   = "ansible-controller"
    nsg_ids          = [oci_core_network_security_group.admin.id]
  }
  metadata = {
    ssh_authorized_keys = trimspace(var.ssh_public_key)
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  freeform_tags = local.tags
  lifecycle {
    prevent_destroy = true
  }
  timeouts {
    create = "10m"
  }
}
