# Example 01 — dedicated WEKA Organization (recommended)

Multi-tenant isolation via a dedicated WEKA **Organization** + an
**OrganizationAdmin** user scoped to it. Directory-backed (`dir/v1`) volumes, to
the common folder-based pattern. See
[../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-a--dedicated-weka-organization-strong-isolation-recommended).

Files (these are the exact manifests validated in the lab — see `verify.md`):
- `provider-setup.md` — what the operator runs (`weka org add`, pre-create FS, `csi`-role user)
- `csi-secret.example.yaml` — org-scoped credentials (copy → `csi-secret.yaml`, add password)
- `storageclass.yaml` — `dir/v1`, pinned to `tenant-a-fs`
- `pvc-and-pod.yaml` — smoke test (pod writes to `/data`)

Apply order (after the CSI plugin is installed — see
[../../scripts/tenant/install-csi.sh](../../scripts/tenant/install-csi.sh)):
```bash
cp csi-secret.example.yaml csi-secret.yaml   # add the real password
kubectl apply -f csi-secret.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc-and-pod.yaml
kubectl exec app-tenant-a -- cat /data/temp.txt   # verify writes
```

> ✅ Validated end-to-end on 2026-07-01 — PVC Bound, pod Running, read/write
> confirmed. Captured output in [verify.md](verify.md); full transcript in
> [../../docs/lab-evidence.md](../../docs/lab-evidence.md).
