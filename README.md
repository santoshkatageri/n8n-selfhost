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

## Mac-based Ansible management

Run Ansible from the owner's Mac. The dedicated free AMD controller approach was dropped on 6 October 2026 after repeated package-maintenance memory exhaustion. Mac ansible-core 2.21.4 with Python 3.14.7 passed a localhost ping. The n8n service host is still to be provisioned and configured.

The AMD VM and its 50 GB boot disk were deleted successfully. Their shared network and OCI Terraform state are retained. `terraform/controller` now describes the retained network; `ansible/controller.yml` is historical bootstrap code and must not be rerun as the active setup path. See `docs/deployment-journal.md` for the decision and evidence.

The GitHub source provider validates, but OCI cannot convert existing ZIP stacks to Git. See `docs/github-source.md` for source options and trigger prerequisites. Automatic cloud plans remain disabled.

## n8n host implementation

`terraform/n8n` is prepared and validated for A1 2 OCPUs / 6 GB RAM, Ubuntu 24.04 ARM64, 50 GB boot and 50 GB data storage. Provisioning is blocked by OUT_OF_HOST_CAPACITY in all three Ashburn ADs despite sufficient A1 quota. No n8n resources have been created. Recheck physical capacity and actual storage usage before applying.
