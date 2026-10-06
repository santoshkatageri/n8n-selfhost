output "instance_ocid" { value = oci_core_instance.n8n.id }
output "public_ip" { value = oci_core_instance.n8n.public_ip }
output "private_ip" { value = oci_core_instance.n8n.private_ip }
output "boot_volume_ocid" { value = oci_core_instance.n8n.boot_volume_id }
output "data_volume_ocid" { value = oci_core_volume.data.id }
output "ssh_user" { value = "ubuntu" }
