# Task 01 — Confirm accounts and quotas

Record actual outcomes in the vault's `Operating Evidence.md` and update task `01 Confirm accounts and quotas.md`. This checklist is preparation, not a second task tracker. Verified public reference date: 6 October 2026.

## OCI account inspection

1. Confirm the signed-in tenancy is the intended personal account. Record account type (Always Free-only, trial or paid), home region and intended compartment. Keep API keys and private keys in the selected secret store.
2. In **Limits, Quotas and Usage**, select the home region and relevant availability domains. Record `standard-a1-core-count` and `standard-a1-memory-count` limits, current usage and available amount, together with compartment quota restrictions and the inspection time. Generic paid/trial limits are not the free entitlement.
3. Inventory all existing A1 instances and their allocation across compartments; include stopped instances when reconciling allocated quota and confirm actual metered usage separately. Do not treat one empty compartment as an empty tenancy.
4. Inventory boot and block volumes, including unattached volumes, across the home region and all compartments. Record combined GB and volume-backup count. Inspect existing VCN usage before assuming a new VCN fits.
5. Reconcile service availability with the free billing allowance. Oracle currently documents 1,500 A1 OCPU-hours and 9,000 GB-hours/month (2 OCPUs / 12 GB for Always Free tenancies), plus 200 GB combined boot/block storage and five volume backups. Check existing month-to-date usage and estimated remaining usage. Proposed incremental allocation: 2 OCPUs / 6 GB and 100 GB storage. At 744 hours this adds 1,488 OCPU-hours and 4,464 GB-hours, before any other usage.
6. Confirm an eligible Ubuntu ARM64 image and availability domain. Inspect capacity evidence if accessible without allocating/reserving a resource. Record the result and time, or leave it unverified until an authorized implementation attempt. Quota headroom does not guarantee host capacity.
7. Record an explicit eligibility/cost decision. Keep the estimate conditional if evidence is missing. Do not delete other resources, resize them, upgrade the tenancy or allocate a VM to resolve this check.

Sources: [Always Free resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm), [service limits](https://docs.oracle.com/en-us/iaas/Content/General/service-limits/default.htm).

## Cloudflare account inspection

1. Confirm access to the account containing `learnwithsk.dev`, its zone status and nameserver delegation.
2. Inspect exact-name A, AAAA and CNAME records for `n8nautomation.learnwithsk.dev`. Record existence, type, target, proxy mode and whether routing is owned by an existing service. Do not replace an existing record or route.
3. Inspect existing named tunnels, published hostnames and Access applications/policies for this host. Record whether an existing setup needs import/reuse; do not create a second tunnel during inspection.
4. Confirm the chosen editor identity/login method, Zero Trust organization and permissions needed for the later Terraform-managed configuration. No tokens need to be created during prerequisite inspection.
5. Design the host-wide editor protection and the narrow machine route. A more specific Access application can override a broader path rule; keep only the selected production webhook path separately authenticated. A service-auth policy and service token can support machine calls where applicable, together with workflow authentication. Keep `/webhook-test`, editor, REST/API, credentials and other admin routes protected. Verify OAuth callbacks individually during deployment.

Public DNS results are time-bound evidence and cannot prove provider-side record absence, account ownership, tunnel health or HTTPS.

Sources: [Access application paths](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/app-paths/), [service tokens](https://developers.cloudflare.com/cloudflare-one/access-controls/service-credentials/service-tokens/).

## Decisions to record

| Decision | Current information | Evidence needed |
| --- | --- | --- |
| Local code directory | `/Users/spk/workspace/prepare/n8n-selfhost`, supplied by user | Code remote/access and revision when selected |
| OCI home region/account type | Ashburn, Free Tier / Always Free observed | Dated console evidence in Operating Evidence |
| Remaining A1 and storage allowance | Per-AD A1 2 cores / 12 GB available; regional eligible storage 200 GB available | Do not add AD quotas; month-to-date billing and host capacity still unverified |
| Ubuntu image / availability domain | Unknown | Compatibility, eligibility and capacity evidence |
| Cloudflare zone and hostname record | learnwithsk.dev inspected; n8nautomation record absent | Dated provider inventory in Operating Evidence |
| Editor identity and webhook auth | Unchosen | Owner selection and scoped access design |
| Terraform state backend | OCI Resource Manager, compartment stack in tenancy root / Ashburn | Actual stack and job identifiers in Operating Evidence |
| Secret store | Unchosen | Retrieval method for Ansible and key recovery |
| Off-host encrypted backups | Unchosen | Destination, existing quota, retention and recovery access |

The local directory is confirmed; it does not select a remote repository or state backend. Keep credentials, saved plans and state outside the vault. Before marking task 01 Done, link actual quota/account proof, provider-side DNS evidence, chosen editor identity, repository/state locations and secret-store decision. Backup design must be resolved before deployment recovery checks.
