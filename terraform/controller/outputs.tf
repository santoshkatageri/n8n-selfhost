output "controller_ocid" { value = oci_core_instance.controller.id }
output "controller_public_ip" { value = oci_core_instance.controller.public_ip }
output "controller_private_ip" { value = oci_core_instance.controller.private_ip }
output "boot_volume_ocid" { value = oci_core_instance.controller.boot_volume_id }
output "vcn_ocid" { value = oci_core_vcn.automations.id }
output "management_subnet_ocid" { value = oci_core_subnet.management.id }
output "admin_nsg_ocid" { value = oci_core_network_security_group.admin.id }
output "egress_route_table_ocid" { value = oci_core_route_table.egress.id }
output "outbound_security_list_ocid" { value = oci_core_security_list.outbound_only.id }
output "controller_allocation" {
  value = {
    role       = "Ansible CLI controller; no AWX or OLAM"
    shape      = "VM.Standard.E2.1.Micro"
    memory_gb  = 1
    boot_gb    = 50
    region     = "us-ashburn-1"
    ad         = var.availability_domain
    image_ocid = var.image_ocid
    ssh_user   = "opc"
  }
}
