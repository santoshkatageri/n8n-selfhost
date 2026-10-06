# GitHub source and OCI plan triggers

Repository: `https://github.com/santoshkatageri/n8n-selfhost` (public, chosen by the owner).

The repository contains source only. Actual compartment/tenancy/stack identifiers, the admin IP, public connection details, private keys, state and plans stay in private local settings or OCI. The platform image OCID is public vendor metadata and is deliberately pinned.

## Preserve existing stacks and state

Connect both existing Resource Manager stacks to the same repository on `main`:

| Stack | Working directory | Required private variables |
| --- | --- | --- |
| automations-compartment | terraform/compartment | tenancy_ocid, existing_compartment_ocid, region |
| automations-controller | terraform/controller | compartment_ocid, availability_domain, admin_ipv4_cidr, ssh_public_key, image_ocid |

Do not create replacement stacks or reimport their state. The public source replaces account-specific literals with inputs. Retain exactly the deployed values when switching source, including the tenant-prefixed AD-2 name. The first Git-sourced plan must show no infrastructure changes. Stop and investigate any addition, replacement or deletion.

Create a Resource Manager GitHub configuration source provider using a fine-grained, read-only GitHub PAT limited to this one public repository. Enter the token directly in OCI; do not paste it into chat or code. Validate the connection, edit each existing stack's source, select the provider/repository/branch/directory, and fill the private variables. Git sourcing fetches source when a job runs; it does not itself trigger an apply.

## Repository workflows

`validate.yml` runs on pull requests and pushes to main. It validates both Terraform directories and Ansible syntax without cloud credentials.

`oci-plan.yml` triggers on changes to Terraform on main or manual dispatch. It is inactive until the repository variable `OCI_PLAN_ENABLED=true` is set. It uses environment `oci-plan` and protected environment secrets:

- OCI_USER_OCID
- OCI_TENANCY_OCID
- OCI_FINGERPRINT
- OCI_PRIVATE_KEY (dedicated OCI API signing key, not the SSH key)
- OCI_COMPARTMENT_STACK_OCID
- OCI_CONTROLLER_STACK_OCID

Use a dedicated OCI identity with scoped Resource Manager job and resource-read permissions reviewed for these two stacks. Do not upload the tenancy administrator's signing key. The owner must create/approve the credential and its access, then enter it directly as a GitHub environment secret. Restrict that environment to main. For this public repository, maintain branch rules and required code review before credentialed workflow changes can run. Avoid exposing secrets to fork pull requests; this workflow does not run cloud plans on PR events.

The script checks each stack is sourced from this repository, main and its expected directory, creates only PLAN jobs, waits for success, and compares each job's downloaded Terraform source with the workflow checkout. This catches a branch advancing while jobs are queued. It never applies, prints a complete plan, or uploads a plan artifact to public Actions logs. Review the private plan in Resource Manager and apply its exact saved job manually after approval.

## Activation checklist

- [ ] GitHub read-only source provider created and validated by the owner.
- [ ] Both existing stacks switched to Git without replacing state.
- [ ] Private variables preserved; first Git plans have zero infrastructure changes.
- [ ] Dedicated CI identity/access and environment secrets configured by the owner.
- [ ] Main-branch and environment restrictions configured.
- [ ] Set OCI_PLAN_ENABLED=true and verify a successful manual dispatch before relying on push triggers.

The workflow files being present does not mean OCI sourcing or automatic cloud plans are active.

Sources: [OCI Git configuration provider](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-csp-github.htm), [stack Git source](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-stack-git.htm), [updating sources](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/update-stack-csp.htm), [plan jobs](https://docs.oracle.com/en-us/iaas/Content/ResourceManager/Tasks/create-job-plan.htm).
