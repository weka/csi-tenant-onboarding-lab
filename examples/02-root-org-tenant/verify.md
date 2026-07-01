# Verify — Model B (root org, dedicated filesystem)

Captured from the same live lab run on 2026-07-01 (see
[../../lab/LAB.md](../../lab/LAB.md)).

## WEKA-side (provider)

```
# dedicated filesystem in the root org
$ weka fs add tenant-b-fs default 100GB

# scoped CSI user in Root — dedicated 'CSI' role, NOT ClusterAdmin
$ weka user add tenant-b-csi csi '***'

$ weka user            # Root
USERNAME         SOURCE    ROLE
weka-deployment  Internal  ClusterAdmin
admin            Internal  ClusterAdmin
tenant-b-csi     Internal  CSI
```

> Isolation caveat (as documented): a Root-org user has no org boundary. The
> `CSI` role limits *what* it can do, and the StorageClass pins it to
> `tenant-b-fs`, but it is not confined to an org the way Model A is.

## Tenant k8s side

```
$ kubectl get pvc pvc-tenant-b
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
pvc-tenant-b   Bound    pvc-538f5e7e-6acd-45a2-b666-87d9b1b735e6   1Gi        RWX            sc-tenant-b-dir

$ kubectl get pod app-tenant-b
NAME           READY   STATUS    RESTARTS   AGE
app-tenant-b   1/1     Running   0          36s

volumeHandle = dir/v1/tenant-b-fs/csi-volumes/pvc-538f5e7e-...

$ kubectl exec app-tenant-b -- sh -c 'wc -l < /data/temp.txt'
7
```

✅ Provisioned + mounted with a **scoped `CSI`-role user** in the root org, fenced
to `tenant-b-fs` by the StorageClass — never admin credentials.
