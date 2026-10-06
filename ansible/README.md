# Separate AMD controller bootstrap

> Status — retired approach, 6 October 2026: use Ansible on the Mac. Existing cloud resources have not yet been deleted; retain shared networking and state during any approved cleanup. The instructions below describe the historical controller setup.

This playbook installs Ansible CLI, not AWX/OLAM. It targets only Oracle Linux 9 on x86_64, installs the vendor-supported Python 3.12 packages, and creates an opc-owned virtual environment with ansible-core 2.21.4 and fully pinned, hashed Python dependencies. No inbound service is installed. The owner's automation directory uses two parallel forks and host-key checking.

First create and verify the approved VM. Record its Resource Manager output under `private/`, and generate `private/controller-inventory.yml` with the public IP, user opc, the dedicated private-key path, `/usr/bin/python3` as the initial managed-host interpreter and SSH options `IdentitiesOnly=yes StrictHostKeyChecking=yes UserKnownHostsFile=<project>/private/ssh/known_hosts`. Make the first SSH connection with `StrictHostKeyChecking=accept-new` to record the new host key, then retain checking. A changed host key requires investigation.

From the project root, run:

```sh
ANSIBLE_LOCAL_TEMP="$PWD/private/ansible-tmp" ansible-playbook -i private/controller-inventory.yml ansible/controller.yml
```

Repeat the same playbook and expect zero changes after a completed first run. Verify CLI version and localhost pong from the controller. This does not prove management of the future n8n VM: target credentials, private-network SSH rules and service playbooks still need their own implementation.

Ansible support matrix: https://docs.ansible.com/projects/ansible-core/devel/reference_appendices/release_and_maintenance.html
Oracle Python packages: https://docs.oracle.com/en-us/iaas/oracle-linux/python/python-installing-third-party-packages.htm
