# Example 02 — root org, dedicated filesystem (simpler, weaker isolation)

A dedicated **`csi`-role** (non-admin) user in the root org, fenced to a pre-created
filesystem via the StorageClass + a capacity quota. Directory-backed (`dir/v1`). See
[../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-b--root-org-dedicated-filesystem-simpler-weaker).

> **Isolation caveat:** a regular root-org user can view all filesystems
> cluster-wide. Only the StorageClass `filesystemName` pin + quota fence the tenant.
> Prefer [Model A](../01-org-tenant/) for real multi-tenancy.

Files (these are the exact manifests validated in the lab — see `verify.md`):
- `provider-setup.md` — operator steps (`weka fs add`, `csi`-role user)
- `csi-secret.example.yaml` — root-org credentials (copy → `csi-secret.yaml`, add password)
- `storageclass.yaml` — `dir/v1`, pinned to `tenant-b-fs`
- `pvc-and-pod.yaml` — smoke test

Apply order (after CSI install — see
[../../scripts/tenant/install-csi.sh](../../scripts/tenant/install-csi.sh)):
```bash
cp csi-secret.example.yaml csi-secret.yaml   # add the real password
kubectl apply -f csi-secret.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc-and-pod.yaml
kubectl exec app-tenant-b -- cat /data/temp.txt   # verify writes
```

> ✅ Validated end-to-end on 2026-07-01 — PVC Bound, pod Running, read/write
> confirmed. Captured output in [verify.md](verify.md); full transcript in
> [../../docs/lab-evidence.md](../../docs/lab-evidence.md).
