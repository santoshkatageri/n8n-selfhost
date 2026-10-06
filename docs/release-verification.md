# Release verification before service implementation

No container releases are pinned yet. Re-check official release notes and the selected release's source before writing the deployment. Current documentation is guidance; it does not prove an older image supports a setting.

## Release record

For n8n, PostgreSQL and cloudflared, record the exact stable release/tag, immutable image index digest, Linux ARM64 manifest digest, check time and primary source. If an external task runner is needed, verify its documented compatibility with the selected n8n release. Terraform providers, Terraform, Ansible and collections also need reproducible version constraints and a reviewed lock file where supported.

Inspect image manifests without starting services, for example with `docker buildx imagetools inspect IMAGE:EXACT_TAG`, once tags are selected. Avoid floating `latest`, `stable` and major-only tags in deployment configuration. Do not record an image as verified without a manifest result.

## Release-specific configuration checks

- As of the current official reverse-proxy guide, `N8N_WEBHOOK_URL` replaces deprecated `WEBHOOK_URL` from n8n 2.35.0. Verify the selected release's configuration schema, then set the supported variable to `https://n8nautomation.learnwithsk.dev/`.
- Verify `N8N_EDITOR_BASE_URL`, `N8N_HOST`, protocol, secure cookies, scheduling timezone and actual proxy chain. The guide's one-hop example is not proof of the Cloudflare edge/cloudflared hop count; inspect forwarded headers and test generated webhook URLs before accepting it.
- Verify database configuration for PostgreSQL, stable `N8N_ENCRYPTION_KEY` handling, execution pruning, timeouts and initial concurrency. Persist `/home/node/.n8n` as well as database data.
- PostgreSQL 18 changes default data layout. Set an explicit supported `PGDATA` and a matching persistent mount for the chosen major release; verify restart and restore. A major-version image change is not an upgrade procedure.
- Verify cloudflared's pinned authentication mechanism and supported secret-file option, egress needs and origin target. Keep database/n8n ports on the private container network.
- If Code nodes are needed, select an isolated runner using the pinned release's documented method. The Assistant sandbox and local models are outside initial scope.

Record runtime, restart, access and restore outcomes separately in Obsidian. Manifest inspection and documentation review are not healthy-service or recovery evidence.

Primary sources checked on 6 October 2026:

- [n8n Docker Compose installation](https://docs.n8n.io/deploy/host-n8n/install-options/install-using-docker-compose.md)
- [n8n reverse-proxy webhook configuration](https://docs.n8n.io/deploy/host-n8n/configure-n8n/basic-configuration/configuration-examples/configure-webhook-urls-with-reverse-proxy.md)
- [n8n official releases](https://github.com/n8n-io/n8n/releases)
- [Cloudflare tunnel setup](https://developers.cloudflare.com/tunnel/get-started/)
