# Verify — Model A (dedicated WEKA Organization)

Captured from a live lab run on 2026-07-01. Traditional WEKA cluster
`csi-tenant` (4.4.10.171, 6 backends, UDP) on GCP `your-gcp-project`; tenant = single-node
k3s on Ubuntu 22.04. See [../../lab/LAB.md](../../lab/LAB.md).

## WEKA-side (provider)

```
# org + org-admin created in one command
$ weka org add tenant-a tenant-a-admin '***' --ssd-quota 300GB --total-quota 300GB
Organization with ID 1 created successfully.

# filesystem created INSIDE the org (as the org admin)
$ weka fs add tenant-a-fs default 100GB

# the scoped CSI user — dedicated 'CSI' role, NOT admin
$ weka user add tenant-a-csi csi '***'

$ weka user            # (in org tenant-a context)
USERNAME        SOURCE    ROLE
tenant-a-admin  Internal  OrgAdmin
tenant-a-csi    Internal  CSI
```

**Isolation proof** — as ClusterAdmin in Root, `tenant-a-fs` is *not visible*
(it lives in the org); Root only sees its own filesystems:
```
$ weka fs            # as admin/Root
0  .config_fs
1  default
2  tenant-b-fs        # Model B's fs (Root)   ← tenant-a-fs absent
```

## Tenant k8s side

```
$ kubectl get pvc pvc-tenant-a
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
pvc-tenant-a   Bound    pvc-9cf3dd3a-8264-4e28-b566-b0fbde394c00   1Gi        RWX            sc-tenant-a-dir

$ kubectl get pod app-tenant-a
NAME           READY   STATUS    RESTARTS   AGE
app-tenant-a   1/1     Running   0          21m

# directory-backed volume provisioned inside the tenant's org filesystem:
volumeHandle = dir/v1/tenant-a-fs/csi-volumes/pvc-9cf3dd3a-...

# read/write proof (pod appends a timestamp every 5s)
$ kubectl exec app-tenant-a -- sh -c 'tail -2 /data/temp.txt; wc -l < /data/temp.txt'
Wed Jul  1 16:21:49 UTC 2026
Wed Jul  1 16:21:54 UTC 2026
30
```

✅ The tenant provisioned + mounted WEKA storage using a **scoped `CSI`-role user
confined to its own Organization** — never admin credentials.
