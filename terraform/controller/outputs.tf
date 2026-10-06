output "vcn_ocid" { value = oci_core_vcn.automations.id }
output "management_subnet_ocid" { value = oci_core_subnet.management.id }
output "admin_nsg_ocid" { value = oci_core_network_security_group.admin.id }
output "egress_route_table_ocid" { value = oci_core_route_table.egress.id }
output "outbound_security_list_ocid" { value = oci_core_security_list.outbound_only.id }
