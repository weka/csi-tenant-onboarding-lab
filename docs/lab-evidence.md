# Lab evidence — command transcript

Real command output from the live lab (2026-07-01): a tenant's single-node
Kubernetes cluster consuming a traditional WEKA cluster over CSI with scoped
`csi`-role credentials. Passwords redacted; internal lab IPs shown as-is.

Topology: WEKA cluster `csi-tenant` (4.4.10.171, 6 backends, UDP) + one tenant VM
(`csi-tenant-tenant`, Ubuntu 22.04) running single-node k3s + WEKA CSI v2.8.8.

---

## 1. Provider side — the WEKA cluster

Cluster healthy:
```console
$ weka status
WekaIO v4.4.10.171 (CLI build 4.4.10.171)
       cluster: csi-tenant (ddce8d81-1039-4392-bcbb-b31af646c25a)
        status: OK (12 backend containers UP, 12 drives UP)
    protection: 3+2 (Fully protected)
 drive storage: 1.97 TiB total, 1.68 TiB unprovisioned
     io status: STARTED 1 hour ago (36 io-nodes UP, 90 Buckets UP)
```

Two organizations — Root and the tenant's dedicated org (with a capacity quota):
```console
$ weka org
ID  NAME              ALLOCATED SSD  SSD QUOTA  ALLOCATED TOTAL  TOTAL QUOTA
 0  Root                  222.00 GB        0 B        222.00 GB          0 B
 1  coupang-tenant-a      100.00 GB  300.00 GB        100.00 GB    300.00 GB
```

Scoped users — the tenant CSI users hold the dedicated **`CSI`** role, never admin:
```console
$ weka user                          # Root org
USERNAME         SOURCE    ROLE
weka-deployment  Internal  ClusterAdmin
admin            Internal  ClusterAdmin
tenant-b-csi     Internal  CSI        ← Model B credential

$ weka user                          # inside org coupang-tenant-a
USERNAME        SOURCE    ROLE
tenant-a-admin  Internal  OrgAdmin
tenant-a-csi    Internal  CSI         ← Model A credential
```

**Organization isolation, proven.** As a cluster admin in Root you see the Model B
filesystem but *not* the org-A filesystem — it only appears inside the org:
```console
$ weka fs                            # as admin / Root org
FILESYSTEM ID  FILESYSTEM NAME   USED SSD   AVAILABLE SSD
0              .config_fs          4.09 KB       22.00 GB
1              default             4.09 KB      100.00 GB
2              tenant-b-fs       409.59 KB      100.00 GB    ← Model B (root org)
                                                             ← tenant-a-fs NOT visible here

$ weka fs                            # inside org coupang-tenant-a
FILESYSTEM ID  FILESYSTEM NAME   USED SSD   AVAILABLE SSD
3              tenant-a-fs       409.59 KB      100.00 GB    ← Model A, only visible in-org
```

---

## 2. Tenant node — WEKA client + Kubernetes

WEKA client container joined to the cluster (stateless, UDP, 1 core):
```console
$ weka local ps
CONTAINER  STATE    DISABLED  UPTIME    MONITORING  PERSISTENT  PORT   PID    STATUS  VERSION
client     Running  False     0:27:41h  True        True        14000  18945  Ready   4.4.10.171
```

Single-node k3s, Ubuntu 22.04 (kernel < 6.17 so the wekafs driver builds):
```console
$ kubectl get nodes -o wide
NAME                STATUS   ROLES           VERSION        INTERNAL-IP   OS-IMAGE             KERNEL-VERSION
csi-tenant-tenant   Ready    control-plane   v1.36.2+k3s1   10.0.0.10     Ubuntu 22.04.5 LTS   6.8.0-1060-gcp
```

WEKA CSI plugin running:
```console
$ kubectl -n csi-wekafs get pods
NAME                                     READY   STATUS    RESTARTS   AGE
csi-wekafs-controller-6db98d48c5-6stwc   5/5     Running   0          43m
csi-wekafs-controller-6db98d48c5-z46s7   5/5     Running   0          43m
csi-wekafs-node-kj84k                    3/3     Running   0          25m
```

---

## 3. Tenant consuming WEKA storage over CSI

Two StorageClasses (one per model), both `dir/v1` on `csi.weka.io`:
```console
$ kubectl get storageclass
NAME                   PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      AGE
local-path (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   61m
sc-tenant-a-dir        csi.weka.io             Delete          Immediate              46m
sc-tenant-b-dir        csi.weka.io             Delete          Immediate              23m
```

Tenant-scoped Secrets (values redacted — decoded username/org shown for proof):
```console
$ kubectl -n csi-wekafs get secret csi-wekafs-api-secret-a csi-wekafs-api-secret-b
NAME                      TYPE     DATA   AGE
csi-wekafs-api-secret-a   Opaque   9      46m
csi-wekafs-api-secret-b   Opaque   9      23m

# secret A decodes to the scoped user + tenant org (NOT admin / NOT Root):
username     = tenant-a-csi
organization = coupang-tenant-a
```

PVCs **Bound**, PVs carrying `dir/v1` volume handles inside each tenant filesystem:
```console
$ kubectl get pvc
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
pvc-tenant-a   Bound    pvc-9cf3dd3a-8264-4e28-b566-b0fbde394c00   1Gi        RWX            sc-tenant-a-dir
pvc-tenant-b   Bound    pvc-538f5e7e-6acd-45a2-b666-87d9b1b735e6   1Gi        RWX            sc-tenant-b-dir

$ kubectl get pv -o custom-columns=SC:.spec.storageClassName,HANDLE:.spec.csi.volumeHandle
SC                HANDLE
sc-tenant-a-dir   dir/v1/tenant-a-fs/csi-volumes/pvc-9cf3dd3a-...
sc-tenant-b-dir   dir/v1/tenant-b-fs/csi-volumes/pvc-538f5e7e-...
```

Application pods **Running** and mounting WEKA:
```console
$ kubectl get pods -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP           NODE
app-tenant-a   1/1     Running   0          46m   10.42.0.16   csi-tenant-tenant
app-tenant-b   1/1     Running   0          23m   10.42.0.18   csi-tenant-tenant
```

Read/write proof — the volume is a real wekafs mount (note `type wekafs …
container_name=client`) and the app is appending to it:
```console
$ kubectl exec app-tenant-a -- sh -c 'mount | grep /data; tail -3 /data/temp.txt; wc -l < /data/temp.txt'
tenant-a-fs on /data type wekafs (rw,relatime,writecache,acl,sync_on_close,...,container_name=client)
Wed Jul  1 16:46:17 UTC 2026
Wed Jul  1 16:46:22 UTC 2026
Wed Jul  1 16:46:27 UTC 2026
325

$ kubectl exec app-tenant-b -- sh -c 'wc -l < /data/temp.txt'
287
```

---

## What this proves

- A tenant's own Kubernetes cluster provisioned and mounted WEKA storage using only
  a **`csi`-role user** — no admin/ClusterAdmin credentials anywhere in the tenant's config.
- **Model A** confines that user to its own WEKA Organization (`tenant-a-fs` is
  invisible outside the org).
- **Model B** uses a root-org `csi` user fenced to a dedicated filesystem.
- Both delivered working ReadWriteMany volumes that pods read and write live.
