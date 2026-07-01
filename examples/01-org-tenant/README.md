# Example 01 — dedicated WEKA Organization

Multi-tenant isolation using a dedicated WEKA **Organization** + an OrgAdmin user
scoped to it. See [../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-a--dedicated-weka-organization-strong-isolation).

**Manifests pending** the provisioning-mode decision in
[../../docs/OPEN-QUESTIONS.md](../../docs/OPEN-QUESTIONS.md). Planned files:

- `provider-setup.md` — `weka org create` + scoped OrgAdmin user
- `csi-secret.example.yaml` — org-scoped credentials (placeholders)
- `storageclass.yaml` — provisioning mode TBD (`dir/v1` recommended)
- `csi-values.yaml` — Helm values (stateless client)
- `pvc-and-pod.yaml` — sample workload proving read/write
- `verify.md` — captured end-to-end output
