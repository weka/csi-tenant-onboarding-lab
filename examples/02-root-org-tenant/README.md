# Example 02 — root org, dedicated filesystem

Simpler, weaker isolation: a **non-admin** user in the root org, fenced to a
pre-created filesystem via the StorageClass and a capacity quota. See
[../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-b--root-org-dedicated-filesystem-simpler-weaker).

**Manifests pending** the provisioning-mode decision in
[../../docs/OPEN-QUESTIONS.md](../../docs/OPEN-QUESTIONS.md). Planned files:

- `provider-setup.md` — `weka fs create` + non-admin user
- `csi-secret.example.yaml` — root-org credentials (placeholders)
- `storageclass.yaml` — provisioning mode TBD (`dir/v1` recommended)
- `csi-values.yaml` — Helm values (stateless client)
- `pvc-and-pod.yaml` — sample workload proving read/write
- `verify.md` — captured end-to-end output
