# n8n self hosting

Working directory: `/Users/spk/workspace/prepare/n8n-selfhost`.
Project record: `/Users/spk/workspace/life-os/wiki/projects/n8n-oci-cloudflare/`.
Hostname: `n8nautomation.learnwithsk.dev`.

Infrastructure work is authorized. The user created the `automations` compartment first; its import configuration is in `terraform/compartment`. OCI Resource Manager runs Terraform and stores state. No n8n VM, service or DNS route has been deployed. Actual task states and operating evidence remain in Obsidian.

Terraform will own OCI infrastructure and declared Cloudflare resources. Ansible will own the host, persistent mounts, secrets delivery and Compose services. Implementation follows verified tenancy capacity and a reviewed plan. The proposed starting allocation is 2 OCPUs / 6 GB RAM, 50 GB boot storage and 50 GB data storage, subject to existing usage.

## Project files

- `docs/deployment-journal.md`: ongoing blog source with actual implementation steps and results.
- `docs/prerequisites.md`: account checks and decisions required before a Terraform plan.
- `config/prerequisites.example.json`: non-secret capture template; null means unknown.
- `docs/release-verification.md`: exact-release and ARM64 checks required before service configuration.
- `scripts/read_only_preflight.py`: local tool discovery and optional public DNS checks; never creates cloud resources or starts containers.

Run `python3 scripts/read_only_preflight.py` for tool discovery. Add `--dns` for public DNS checks. It writes JSON to standard output; save a redacted result in Obsidian when recording actual evidence. Public DNS does not prove the account's configured records.

The compartment state backend is OCI Resource Manager stack `automations-compartment` in Ashburn. The public code remote is https://github.com/santoshkatageri/n8n-selfhost. Choose the secret store, encrypted off-host backup destination and editor email during task 01. Container release pins are still pending. See `terraform/compartment/README.md` for the import-only expected plan.

Learn With SK owns content and publishing decisions. The later Obsidian-to-n8n-to-Buffer pilot creates one reviewed draft; hosting preparation authorizes no publishing.

## Separate controller and Git source

The separate free AMD controller source is `terraform/controller`, with its Oracle Linux CLI bootstrap in `ansible/controller.yml`. Cloud state stays in Resource Manager. See `docs/github-source.md` for preserving both existing stacks when connecting Git source and activating the plan-only trigger. GitHub source/trigger activation is pending credentials; workflow presence is not proof of a live cloud connection.
