# Why we disabled kernel crash dumps on the AMD controller

Date: 6 October 2026. Scope: the separate, disposable Ansible CLI controller; this is not a blanket recommendation for every server.

The OCI free AMD shape has 1 GB RAM. The pinned Oracle Linux 9.8 image booted with:

```text
crashkernel=1G-64G:448M,64G-:512M
```

The live reservation was 469,762,048 bytes (448 MiB), and `free -m` reported only 498 MiB usable RAM. Reserving nearly half the machine for crash capture leaves little memory for Python, Ansible and package installation, can increase swap pressure and offers limited practical benefit on a small controller that can be rebuilt from code.

The owner explicitly approved this tradeoff. Ansible stops and disables `kdump`, replaces the crash-kernel boot argument with `crashkernel=0` for configured kernels, and reboots once. It then verifies more than 850 MiB usable memory and that SELinux remains enabled and enforcing. A repeat run must not reboot again when the reservation is already zero.

What we give up: this controller will not capture a kernel memory dump after a kernel panic. This makes deep kernel-crash diagnosis harder. Ordinary system logs, authentication, host-key checking, SELinux and the restricted cloud SSH rule are retained. This adjustment creates no additional cloud storage and does not change the free shape.

To restore crash capture later, first allocate enough RAM for both the workload and the vendor-recommended crash-kernel reservation. Remove or revise the disabling tasks in the controller playbook so a later run does not undo restoration. Set the appropriate `crashkernel` argument using `grubby`, enable `kdump` and reboot; verify `kdumpctl status`, the reserved memory and a protected dump destination. Do not restore the original 448 MiB reservation on this 1 GB VM without considering the loss of usable memory.

Post-reboot checks confirmed the result:

| Measurement | Before | After |
| --- | --- | --- |
| Usable RAM (`free -m`) | 498 MiB | 945 MiB |
| Kernel crash reservation | 448 MiB | 0 |

The usable-memory increase was 447 MiB; rounding and kernel accounting explain the difference from the 448 MiB reservation. Ansible's memory and SELinux-enforcing checks passed. This is verified recovery after reboot, not just an edited boot argument. Ansible CLI package installation remains a separate check. SSH later stalled; a normal restart briefly restored access and reconfirmed 945 MiB, zero reservation, disabled kdump and SELinux enforcing. The retry then stalled during package installation. Installation and repeat-run verification remain incomplete; the cause of the stall is not confirmed.

**Blog takeaway:** on our rebuildable 1 GB Ansible controller, reserving almost half the RAM for kernel-crash diagnosis cost more than it helped. We explicitly accepted losing kernel memory dumps to give the actual workload enough memory. Reassess this choice for larger or critical hosts.

Oracle references: [OCI crash dumps and reservation](https://docs.oracle.com/en-us/iaas/oracle-linux/oci/diagnostics-kdump.htm), [Oracle Linux kernel reservation and grubby](https://docs.oracle.com/en/operating-systems/oracle-linux/9/relnotes9.0/ol9-KnownIssues.html), [Kdump configuration](https://docs.oracle.com/en/operating-systems/oracle-linux/9/boot/monitoring-ConfiguringKdump.html).
