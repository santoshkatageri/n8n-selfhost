# Building our n8n home on OCI and Cloudflare

Status: working implementation journal for a future blog, not a finished tutorial. Updated: 6 October 2026, Asia/Kolkata. Append verified outcomes as the deployment progresses; distinguish planned work from completed work. Never add credentials, private keys, tokens, Terraform state, database contents or webhook payloads.

## What we are building

A small n8n service at `n8nautomation.learnwithsk.dev`, hosted on OCI Always Free infrastructure and reached through Cloudflare Tunnel. PostgreSQL and n8n data will use persistent storage. Terraform will own cloud resources; Ansible will configure the host and services. The later content workflow will receive a selected Obsidian package and create one reviewed Buffer draft. Publishing remains a separate decision.

The proposed starting size is one Ampere A1 VM with 2 OCPUs and 6 GB RAM, a 50 GB boot volume and a separate 50 GB data volume. These resources have **not** been provisioned yet.

## 1. Choose one implementation directory

The user selected `/Users/spk/workspace/prepare/n8n-selfhost` for implementation. Project tasks and operating evidence remain in the separate Obsidian project at `/Users/spk/workspace/life-os/wiki/projects/n8n-oci-cloudflare`.

We added a README, workspace instructions, an ignore file, a prerequisite checklist, a non-secret information template, a release-verification checklist and a read-only preflight script. The ignore file excludes Terraform state, saved plans, environment files, keys and backups. We have not chosen a remote code repository yet.

Local tools found: Terraform, Ansible and Docker. Local OCI CLI and cloudflared were not found, and no default OCI API configuration was found. The local Terraform version used for validation was 1.16.4 on macOS ARM64.

**Why this matters:** deployment code and operational records have distinct homes. Obsidian is useful for decisions and evidence, but is not the place to keep cloud state or secrets.

## 2. Inspect the accounts before creating compute

The user signed in to OCI and Cloudflare in Chrome. We inspected those existing sessions rather than requesting API tokens in chat.

OCI observations on 6 October 2026, approximately 13:12–13:26 IST:

- The intended personal tenancy showed a Free Tier / Always Free account.
- The home region was US East (Ashburn), `us-ashburn-1`.
- Root and the pre-existing `vaultwarden` compartment showed no instances. Their quota-policy lists were empty.
- Each of the three Ashburn availability-domain tables showed A1 core limit 2, usage 0, available 2, and memory limit 12 GB, usage 0, available 12 GB.
- The regional eligible boot/block storage quota showed 200 GB available, with usage 0. The volume-backup counters showed 5 available, usage 0.

**The key distinction:** three availability-domain tables do not mean a 6-OCPU free budget. Oracle's documented monthly allowance is 1,500 A1 OCPU-hours and 9,000 GB-hours, equivalent to 2 OCPUs and 12 GB for an Always Free tenancy. Quota headroom also does not prove physical host capacity. Billing history, current month consumption, VCN usage and host capacity still need checking before compute provisioning.

Cloudflare observations:

- We could access the `learnwithsk.dev` zone, with a Free plan and Full DNS setup.
- The DNS inventory contained three unrelated records: apex, `admin`, and `devpersonify`. There was no exact `n8nautomation` record or wildcard.
- An existing `my-mac` tunnel was Inactive, with zero replicas and no routes.
- Two existing Access applications covered other services; neither covered the proposed n8n hostname.
- The Zero Trust team had an existing one-time PIN integration. The allowed n8n editor email is still unchosen.

At 13:11:47 IST, public A, AAAA and CNAME checks through the system resolver, Cloudflare and Google all returned NXDOMAIN. This is a dated observation. The signed-in DNS inventory supplied the separate provider-side evidence. Existing records, tunnels and Access policies were not changed.

**Blog angle:** first verify both quota and account inventory. Public DNS alone cannot tell us who owns a route or whether an existing provider configuration should be reused.

## 3. Create the `automations` compartment first

The user chose to start with a dedicated `automations` compartment and created it in the OCI console. The detail page showed it as Active under the tenancy root, created at 07:55 UTC / 13:25 IST on 6 October. Its description was `compartment for n8n automations`.

A compartment gives the automation resources an explicit organizational boundary. It is not a VM or a network boundary, and by itself does not deploy n8n.

The important implementation choice was to adopt the existing compartment. Creating another resource with the same intended role would leave the manually created one outside Terraform management.

## 4. Write an import-only Terraform configuration

Source directory: `terraform/compartment`.

We pinned `oracle/oci` to 9.8.0 and included the provider lock file. The provider was obtained from the official Terraform registry and its partner signature was verified during initialization. Resource Manager supplies the authenticated context, so no local OCI API key was added.

The configuration declares exactly one resource:

```hcl
resource "oci_identity_compartment" "automations" {
  compartment_id = var.tenancy_ocid
  name           = "automations"
  description    = "compartment for n8n automations"
  enable_delete  = false

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [defined_tags, freeform_tags]
  }
}

import {
  to = oci_identity_compartment.automations
  id = "<existing-automations-compartment-ocid>"
}
```

The blog example uses a placeholder. The working configuration uses the verified OCID supplied by the user. Matching the description and ignoring existing tag changes keeps adoption from rewriting the console-created details. Destroy protection is an extra guard against ordinary Terraform teardown; it is not a replacement for backups or access controls.

Local preparation and checks:

```sh
terraform init -backend=false -input=false
terraform fmt
terraform validate -json
```

Validation returned `valid: true`, zero errors and zero warnings. One sandboxed validation attempt could not start the provider's local socket; validation outside that sandbox succeeded. This was a local execution restriction, not a cloud deployment result.

We packaged only `main.tf`, `README.md` and `.terraform.lock.hcl` into a ZIP. Provider binaries, keys, state and saved plans were excluded. SHA-256 source hashes are kept in `terraform/compartment/source-manifest.json`.

## 5. Run Terraform through OCI Resource Manager

We selected OCI Resource Manager for the compartment stack so execution and state could stay in OCI under the existing signed-in identity. We did not create local API credentials or keep a competing local state file.

Console steps:

1. Open Resource Manager in Ashburn and choose **Create stack**.
2. Select **My configuration → .zip file** and upload the source-only ZIP.
3. Name the stack `automations-compartment` and store it in the tenancy root.
4. Use the supported Terraform **1.5.x** version.
5. Set `region` to `us-ashburn-1` and `tenancy_ocid` to the verified root tenancy.
6. Leave **Run apply** unchecked so the plan can be reviewed first.
7. Create the stack, then start the plan job `import-automations-plan-20261006`.

The browser extension's direct upload method was unavailable under its existing file permissions. Chrome's native file picker successfully uploaded the ZIP, so no broader extension file access was enabled.

The stack was created at 08:01:07 UTC / 13:31:07 IST. The plan ran from 08:01:28 to 08:01:53 UTC and succeeded. Its actual result was:

```text
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

We checked that it targeted the existing compartment's exact OCID, with the expected parent, name and description.

## 6. Apply the reviewed import plan

From the stack's Apply action, we named the job `import-automations-apply-20261006` and selected the successful plan job as the plan resolution. We did not use automatic approval of a newly generated plan.

The apply job ran from 08:03:44 to 08:04:10 UTC (13:33:44–13:34:10 IST) and showed **Succeeded**. The existing compartment is now adopted into the stack's Terraform state.

The final Terraform log at 08:04:03 UTC confirmed:

```text
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
```

The outputs matched the existing compartment name and supplied OCID.

This step created the Resource Manager management stack and imported the existing compartment. It did not provision a VM, volume, VCN, DNS record, tunnel or running n8n service.

**Blog angle:** infrastructure as code can start by adopting a resource already created in the console. A reviewed import plan makes that handoff explicit and auditable.

## 7. Decide how to manage the VM configuration

After the compartment import, the user asked whether Ansible is needed for VM configuration management. We recommend using it for this deployment. Ansible is optional technically, but it gives this small service a repeatable maintenance and rebuild path.

The ownership split is:

| Tool | Our responsibility for it |
| --- | --- |
| Terraform | Compartment, VCN/subnet, security rules, VM, boot/data volumes and attachments; declared Cloudflare resources |
| Ansible | Ubuntu packages and configuration, Docker/Compose, persistent mounts, service files, protected secret delivery and backup jobs |
| Docker Compose | Run the pinned n8n, PostgreSQL and cloudflared services defined by Ansible |

We will use playbooks for intended host configuration, run them for deployment and later updates, and verify a repeat run for explainable changes. Ansible normally connects over SSH without a resident management agent. We still need to choose a restricted administrative connection path before configuring the VM; the application Tunnel does not by itself provide that management path.

The planned host setup will validate and mount the intended data volume before starting database containers, render pinned service configuration, supply secrets without logging them, and control restarts deliberately. Applying Terraform will not install n8n. This is the configuration-management decision, not proof that playbooks have run: no VM or Ansible role has been deployed yet.

Official references checked on 6 October 2026: [Ansible introduction](https://docs.ansible.com/projects/ansible/latest/getting_started/introduction.html), [Docker Compose v2 module](https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docker_compose_v2_module.html), [persistent mount module](https://docs.ansible.com/projects/ansible/latest/collections/ansible/posix/mount_module.html).

## 8. Choose a separate lightweight Ansible controller — 6 October 2026

The user chose a separate controller and selected a free AMD VM with Ansible CLI. n8n will still use the planned Ampere service VM. AWX requires a Kubernetes deployment; Oracle Linux Automation Manager 2.3 requires at least two CPU cores and 4 GB RAM. These do not fit the 1 GB Always Free micro VM. OLAM packages are available through Oracle's public repositories; supported OLAM is included with Oracle Linux Premier Support. We chose CLI Ansible for the small controller rather than allocating a larger paid instance.

References: [OCI Always Free](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm), [OLAM requirements](https://docs.oracle.com/en/operating-systems/oracle-linux-automation-manager/2/install2.3/awx-OracleLinuxAutomationManagerRequirements.html), [OLAM installation](https://docs.oracle.com/en/learn/olam-install/), [AWX operator](https://github.com/ansible/awx-operator).

## 9. Check controller eligibility and prepare restricted access

Using the signed-in OCI console's Cloud Shell, we checked the tenancy's actual limits and resource availability. The Always Free AMD allowance was two instances in Ashburn AD-2; AD-1 and AD-3 had zero allowance. AD-2 reported two available, zero used. VCN availability was two, zero used; Always Free combined boot/block storage was 200 GB available, zero used. Empty instance and VCN lists were observed in the root, automations and vaultwarden compartments. Quota headroom does not guarantee physical host capacity.

The image query filtered for the AMD micro shape and Oracle Linux 9, returning the compatible platform image `Oracle-Linux-9.8-2026.09.18-0`. We pinned its exact image identifier in Terraform. The controller will have a 50 GB boot disk; combined with the planned 100 GB for n8n, the proposed total is 150 GB.

With explicit user approval, we generated a dedicated Ed25519 key under `private/ssh` and looked up the Mac's current public IPv4 through `api.ipify.org`. The key is local, excluded from version control and protected with file permissions. Only the public key goes to OCI. Local connection settings stay under `private/`; reusable blog examples must omit the actual admin IP and private identifiers.

## 10. Prepare the controller Terraform source and Resource Manager stack

The controller source lives in `terraform/controller`. It takes the existing automations compartment as input and declares eight resources: one shared VCN, internet gateway, outbound route table, outbound-only security list, management subnet, SSH network security group, one TCP 22 rule from the owner's single IPv4 /32, and one `VM.Standard.E2.1.Micro` instance. The subnet uses only the custom security list. The controller's boot volume is preserved and Terraform prevents instance destruction.

The first local validation rejected assigning `ingress_security_rules = []` because the provider expects nested rule blocks. Omitting ingress blocks expresses the intended empty ingress list; validation then passed with zero errors and warnings. We pinned OCI provider 9.8.0 and packaged only source and its dependency lock file.

Created Resource Manager stack `automations-controller` inside automations at 08:27:32 UTC / 13:57:32 IST, leaving Run apply unchecked. Resource Manager adds region and tenancy variables automatically; we verified the downloaded source archive matches every local Terraform file byte-for-byte and explicitly reviewed the compartment/image defaults and public SSH inputs. The plan job `ansible-controller-plan-20261006` ran 08:30:32–08:31:02 UTC (14:00:32–14:01:02 IST) and succeeded: **8 to add, 0 to change, 0 to destroy**. We reviewed all eight resource declarations, exact compartment/image, 50 GB boot volume, shape, AD-2, and the single-address TCP 22 rule. The user approved applying this restricted saved plan. At that checkpoint no controller VM or network had been provisioned. The Ansible CLI bootstrap playbook and nine pinned, hashed Python packages are prepared; its syntax check passed. Actual installation and repeat-run verification await the VM.

## Current checkpoint

- Completed: compartment import; separate Ansible CLI controller decision; AMD, VCN and storage preflight; dedicated SSH key; validated controller Terraform source and management stack.
- Controller created: reviewed and approved plan applied successfully; SSH and boot verified. Ansible bootstrap and memory tuning verification are underway. For the future n8n VM: month-to-date metered A1 usage, eligible Ubuntu ARM64 image and physical host capacity remain to check.
- Owner choices pending: code remote, secret store, encrypted off-host backup destination and allowed editor email.
- Not yet implemented: n8n compute/network/storage, Ansible configuration, pinned containers, Cloudflare route and Access policies, persistence/restart checks, backup restore and Buffer draft pilot.

The separate AMD controller and shared network are now created. Finish controller verification and GitHub source activation; then prepare the separate n8n compute/storage plan using the existing compartment and shared network.

## How to keep this journal useful

Append a dated entry after each meaningful step with what we changed, why we chose it, the exact review or check, observed result and next limitation. Record failed attempts briefly when they explain a useful decision. Do not turn planned checks into claims of successful operation. Keep detailed resource identifiers and private evidence in the project operating record; use placeholders in reusable blog examples.

## Official references checked on 6 October 2026

- [OCI Always Free resources and limits](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [OCI service limits](https://docs.oracle.com/en-us/iaas/Content/General/service-limits/default.htm)
- [OCI Resource Manager: create a stack](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-stack.htm)
- [OCI Resource Manager: apply a configuration](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-job-apply.htm)
- [OCI Terraform provider configuration](https://docs.oracle.com/en-us/iaas/Content/dev/terraform/configuring.htm)
- [Oracle OCI provider registry](https://registry.terraform.io/providers/oracle/oci/latest)
- [n8n Docker Compose hosting](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose.md)
- [n8n proxy and webhook URL configuration](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/configuration-examples/configure-webhook-urls-with-reverse-proxy.md)
- [Cloudflare Access path policies](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/app-paths/)

## 11. GitHub source and triggers requested

The user asked to keep the stacks GitHub sourced and triggered. Resource Manager supports a GitHub configuration source provider, branch and per-stack working directory; a source connection alone is not an automatic apply trigger. Proposed workflow: automatic plans on relevant changes, followed by explicit approval to apply the exact reviewed plan. Repository destination and authentication still need selection. Existing stack identifiers and cloud state must be preserved when their source changes. Keep keys, local connection settings and saved plans excluded. No GitHub repository or workflow has been connected yet. [OCI Git sources](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-stack-git.htm), [source provider](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-csp-github.htm).

## 12. Provision the approved controller and tune its small memory budget

The owner approved the exact restricted plan. The apply log at 08:35:23 UTC / 14:05:23 IST confirmed **8 added, 0 changed, 0 destroyed**, and Resource Manager showed Succeeded. SSH with the dedicated key succeeded; cloud-init completed, the OS reported Oracle Linux 9.8 on x86_64, Python 3.9.25 and a 50 GB boot disk. The new SSH host key was recorded locally and subsequent connections require it to match.

The image's kernel crash-dump reservation consumed 448 MiB (469,762,048 bytes), leaving 498 MiB usable from the free VM's nominal 1 GB. We chose to recover that RAM for the small CLI workload, accepting loss of kernel crash-dump capture. Automatic approval review initially rejected the extra tuning/reboot because the tradeoff needed explicit approval; the action did not run then. The user subsequently approved disabling kdump, setting crashkernel=0 and rebooting once, and requested that the reason be documented. Ansible is now carrying out that approved adjustment and CLI installation. Post-boot recovered memory, CLI checks and repeat-run results remain to verify at this checkpoint.

See [the detailed crash-dump decision and restoration instructions](controller-crash-dumps.md). This applies to this disposable controller, not every managed VM. SELinux, ordinary logs and SSH restrictions are retained.

## 13. Prepare public GitHub source

The user selected repository name n8n-selfhost and then explicitly chose public visibility. Account-specific compartment identifiers and the tenant-prefixed availability domain were moved from literals to private Resource Manager inputs. Deployed source copies are retained under private/ for comparison; both reusable Terraform configurations passed validation with zero errors and warnings.

The repository will contain a source-validation workflow and an opt-in plan-only OCI trigger. The trigger requires a GitHub read-only source connection, dedicated OCI CI credentials and preserved stack variables before activation. Existing cloud state and stack identities must be retained. No private keys, connection inventory, source archives, state or saved plans are published.
