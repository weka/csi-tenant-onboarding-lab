# Example 02 — root org, dedicated filesystem (simpler, weaker isolation)

A **regular** (non-admin) user in the root org, fenced to a pre-created filesystem
via the StorageClass + a capacity quota. Directory-backed (`dir/v1`). See
[../../docs/secrets-and-access.md](../../docs/secrets-and-access.md#model-b--root-org-dedicated-filesystem-simpler-weaker).

> **Isolation caveat:** a regular root-org user can view all filesystems
> cluster-wide. Only the StorageClass `filesystemName` pin + quota fence the tenant.
> Prefer [Model A](../01-org-tenant/) for real multi-tenancy.

Files:
- `provider-setup.md` — operator steps (`weka fs create`, non-admin user)
- `csi-secret.example.yaml` — root-org credentials template (copy → `csi-secret.yaml`)
- `storageclass.yaml` — `dir/v1`, pinned to the dedicated FS
- `pvc-and-pod.yaml` — smoke test

Apply order (after CSI install — see
[../../scripts/tenant/install-csi.sh](../../scripts/tenant/install-csi.sh)):
```bash
cp csi-secret.example.yaml csi-secret.yaml   # edit real values
kubectl apply -f csi-secret.yaml
kubectl apply -f storageclass.yaml
kubectl apply -f pvc-and-pod.yaml
kubectl exec csi-app-on-dir-tenant-a -- cat /data/temp.txt   # verify writes
```

> Not yet run end-to-end on the lab cluster — capture output into `verify.md`.
