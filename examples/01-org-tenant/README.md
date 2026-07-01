# Example 01 — dedicated WEKA Organization (recommended)

Multi-tenant isolation via a dedicated WEKA **Organization** + an
**OrganizationAdmin** user scoped to it. Directory-backed (`dir/v1`) volumes, to
match Coupang's usage. See
[../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-a--dedicated-weka-organization-strong-isolation-recommended).

Files:
- `provider-setup.md` — what the operator runs (`weka org create`, pre-create FS, scoped user)
- `csi-secret.example.yaml` — org-scoped credentials template (copy → `csi-secret.yaml`)
- `storageclass.yaml` — `dir/v1`, pinned to the tenant's filesystem
- `pvc-and-pod.yaml` — smoke test (pod writes to `/data`)

Apply order (after the CSI plugin is installed — see
[../../scripts/tenant/install-csi.sh](../../scripts/tenant/install-csi.sh)):
```bash
cp csi-secret.example.yaml csi-secret.yaml   # edit real values
kubectl apply -f csi-secret.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc-and-pod.yaml
kubectl exec csi-app-on-dir-tenant-a -- cat /data/temp.txt   # verify writes
```

> Not yet run end-to-end on the lab cluster — capture output into `verify.md`.
